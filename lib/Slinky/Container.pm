package Slinky::Container;
use strict;
use Slinky::Item::Ref;
use Slinky::Item::Literal;
use Moose;
use Data::Dumper;
use Carp ();

has 'config'    => ( is => 'rw', isa => 'HashRef', trigger => \&_init_objects );
has 'all_keys'  => ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub { { } } );
has 'objects'   => ( is => 'rw', isa => 'HashRef[Slinky::Item]', lazy => 1, default => sub { { } } );

sub _init_objects {
    my ($self, $conf) = @_;
    (exists $conf->{'components'})
        or Carp::croak("Expected 'components' key");
    foreach my $k (keys %{$conf->{'components'}}) {
        my $v = $conf->{'components'}->{$k};
        $self->_cache_object( $k, $v );
    }
}

sub _cache_object {
    my ($self, $k, $v) = @_;
    $self->all_keys->{$k} = 1;
    if (ref($v)) {
        if (ref($v) eq 'HASH') {
            if (exists $v->{'ref'}) {
                # reference to existing types
                $self->objects->{$k} = Slinky::Item::Ref->new( ref_key => $v->{'ref'}, parent_container => $self );
            }
            else {
                # plain hashref
                $self->objects->{$k} = Slinky::Item::Literal->new( value => $v, parent_container => $self );
            }
        }
        else {
            # other ref types
            $self->objects->{$k} = Slinky::Item::Literal->new( value => $v, parent_container => $self );
        }
    }
    else {
        $self->objects->{$k} = Slinky::Item::Literal->new( value => $v, parent_container => $self );
    }
}

sub lookup {
    my ($self, $key) = @_;
    (defined $key)
        or Carp::croak("Undefined lookup key");
    (exists $self->all_keys->{$key})
        or Carp::croak("Non-existent lookup key");
    # ---
    return $self->objects->{$key}->get;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
