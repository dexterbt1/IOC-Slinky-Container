package Slinky::Item;
use strict;
use Moose::Role;

has 'parent_container' => ( is => 'rw', isa => 'Slinky::Container', weak_ref => 1, required => 1 );

requires 'get';

1;

__END__
