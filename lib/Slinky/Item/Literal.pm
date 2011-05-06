package Slinky::Item::Literal;
use strict;
use Moose;
use Slinky::Item;

with 'Slinky::Item';

has 'value' => ( is => 'rw', isa => 'Any', required => 1 );

sub get {
    my ($self) = @_;
    return $self->value;
}

1;

__END__

