{
    package Item;
    use Moose;
    no Moose;
}
{
    package Car;
    use Moose;
    has 'brand'     => ( is => 'rw', isa => 'Str', required => 1 );
    has 'type'      => ( is => 'rw', isa => 'Str' );
    has 'model'     => ( is => 'rw', isa => 'Str' );
    has 'year'      => ( is => 'rw', isa => 'Int' );
    has 'test_item' => ( is => 'rw', isa => 'Item' );
    no Moose;
}

1;
