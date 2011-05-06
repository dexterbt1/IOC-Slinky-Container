package Slinky::Item::Ref;
use strict;
use Moose;
use Slinky::Item;

with 'Slinky::Item';

has 'ref_key' => ( is => 'rw', isa => 'Str', required => 1 );

sub get {
    my ($self) = @_;
    return $self->parent_container->lookup($self->ref_key);
}

1;

__END__
