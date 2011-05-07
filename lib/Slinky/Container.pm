package Slinky::Container;
use strict;
use Slinky::Item::Ref;
use Slinky::Item::Literal;
use Moose;
use Data::Dumper;
use Carp ();

has 'config'    => ( is => 'rw', isa => 'HashRef', trigger => \&_init_objects );
has 'typeof'    => ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub { { } } );
has 'objects'   => ( is => 'rw', isa => 'HashRef[Slinky::Item]', lazy => 1, default => sub { { } } );

sub _init_objects {
    my ($self, $conf) = @_;
    (exists $conf->{'components'})
        or Carp::croak("Expected 'components' key");
    my $components = delete $conf->{'components'};
    foreach my $k (keys %$components) {
        my $v = delete $components->{$k};
        $self->_wire_object($v, $k);
    }
}

sub _wire_object {
    my ($self, $v, $k) = @_;
    my $oinst;
    if (ref($v)) {
        if (ref($v) eq 'HASH') {
            if (exists $v->{'ref'}) {
                # reference to existing types
                $oinst = tie $_[1], 'Slinky::Item::Ref', $self, $v->{'ref'};
            }
            else {
                # plain hashref ... traverse first
                my $href = { };
                foreach my $hk (keys %$v) {
                    $href->{$hk} = $v->{$hk};
                    $self->_wire_object($v->{$hk});
                }
                $oinst = tie $v, 'Slinky::Item::Literal', $href;
            }
        }
        elsif (ref($v) eq 'ARRAY') {
            # arrayref are to be traversed for refs
            my $count = scalar(@$v)-1;
            for(0..$count) {
                $self->_wire_object($v->[$_]);
            }
            $oinst = tie $v, 'Slinky::Item::Literal', $v;
        }
        else {
            # other ref types
            $oinst = tie $v, 'Slinky::Item::Literal', $v;
        }
    }
    else {
        # literal
        $oinst = tie $v, 'Slinky::Item::Literal', $v;
    }

    if (defined $k) {
        $self->typeof->{$k} = $oinst;
        $self->objects->{$k} = $_[1];
    }
    return $v;
}



sub lookup {
    my ($self, $key) = @_;
    return if (not defined $key);
    return if (not exists $self->typeof->{$key});
    return $self->typeof->{$key}->FETCH;
}


__PACKAGE__->meta->make_immutable;

1;

__END__
