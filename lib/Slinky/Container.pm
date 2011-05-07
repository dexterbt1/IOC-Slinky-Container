package Slinky::Container;
use strict;
use Slinky::Container::Item::Ref;
use Slinky::Container::Item::Literal;
use Slinky::Container::Item::Constructed;
use Moose;
use Data::Dumper;
use Carp ();

has 'config'    => ( is => 'rw', isa => 'HashRef', trigger => \&_init_objects );
has 'typeof'    => ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub { { } } );

sub _init_objects {
    my ($self, $conf) = @_;
    (exists $conf->{'container'})
        or Carp::croak("Expected 'container' key");
    my $container = delete $conf->{'container'};
    foreach my $k (keys %$container) {
        my $v = delete $container->{$k};
        $self->_wire_object($v, $k);
    }
}

sub _wire_object {
    my ($self, $v, $k) = @_;
    my $oinst;
    my @k_aliases = ();
    if (defined $k) {
        push @k_aliases, $k
    }
    if (ref($v)) {
        if (ref($v) eq 'HASH') {
            if (exists $v->{'_ref'}) {
                # reference to existing types
                $oinst = tie $_[1], 'Slinky::Container::Item::Ref', $self, $v->{'_ref'};
            }
            elsif (exists $v->{'_constructor'}) {
                # object!
                my $ns = delete $v->{'_constructor'};
                my $new = delete $v->{'_constructor_method'} || 'new';
                my $args = delete $v->{'_constructor_args'} || [ ];
                my $singleton = 1;
                if (exists $v->{'_singleton'}) {
                    $singleton = delete $v->{'_singleton'};
                }
                $self->_wire_object($args);
                $oinst = Slinky::Container::Item::Constructed->new($ns, $new, $args, $singleton);
            }
            else {
                # plain hashref ... traverse first
                my $href = { };
                foreach my $hk (keys %$v) {
                    if ($hk eq '_lookup_id') {
                        push @k_aliases, delete($v->{$hk});
                        next;
                    }
                    $href->{$hk} = $v->{$hk};
                    $self->_wire_object($v->{$hk});
                }
                $oinst = tie $v, 'Slinky::Container::Item::Literal', $href;
            }
        }
        elsif (ref($v) eq 'ARRAY') {
            # arrayref are to be traversed for refs
            my $count = scalar(@$v)-1;
            for(0..$count) {
                $self->_wire_object($v->[$_]);
            }
            $oinst = tie $v, 'Slinky::Container::Item::Literal', $v;
        }
        else {
            # other ref types
            $oinst = tie $v, 'Slinky::Container::Item::Literal', $v;
        }
    }
    else {
        # literal
        $oinst = tie $v, 'Slinky::Container::Item::Literal', $v;
    }

    if (scalar @k_aliases) {
        foreach my $ok (@k_aliases) {
            $self->typeof->{$ok} = $oinst;
        }
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
