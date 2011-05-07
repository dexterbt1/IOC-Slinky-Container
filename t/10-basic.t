use strict;
use Test::More qw/no_plan/;
use Test::Exception;
use Scalar::Util qw/refaddr/;

BEGIN {
    use_ok 'Slinky::Container';
    use_ok 'YAML';
}

my $conf;
my $c;
my $o;

$conf = <<YML;
---
components:
    somenull: ~ 
    greeting: "Hello World"
    greeting2: "Aloha"
    digits: 1234567890

    href1:
        somekey1: somevalue1
    aref1:
        - 1
        - "abc"
    ptr1: { ref: "greeting" }

    href2:
        this2:
            is2:
                nested2: { ref: "digits" }

    aref2:
        - 1
        - { ref: "greeting2" }
    ptr2: { ref: "ptr1" }
YML

dies_ok { $c = Slinky::Container->new( config => { } ); } 'no components';

$c = Slinky::Container->new( config => Load($conf) );

ok not(defined $c->lookup()), 'non-existent lookup';
ok not(defined $c->lookup('')), 'non-existent lookup';

is $c->lookup('somenull'), undef, 'somenull';
is $c->lookup('greeting'), "Hello World", 'greeting';
is $c->lookup('digits'), 1234567890, 'digits';

is_deeply $c->lookup('href1'), { 'somekey1' => 'somevalue1' }, 'href1';
is_deeply $c->lookup('aref1'), [ 1, "abc" ], 'aref1';

is $c->lookup('ptr1'), $c->lookup('greeting'), 'ptr1=greeting';

is_deeply $c->lookup('href2'), { this2 => { is2 => { nested2 => 1234567890 } } }, 'deep-href2';

is_deeply $c->lookup('aref2'), [ 1, 'Aloha' ], 'deep-aref2';

is $c->lookup('ptr2'), $c->lookup('ptr1'), 'ptr2-to-ptr1';
is $c->lookup('ptr2'), $c->lookup('greeting'), 'ptr2-to-greeting';


pass "last";

__END__

