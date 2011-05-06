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
    digits: 1234567890
    href1:
        somekey1: somevalue1
    aref1:
        - 1
        - "abc"
    ptr1: { ref: "greeting" }
YML

dies_ok { $c = Slinky::Container->new( config => { } ); } 'no components';

$c = Slinky::Container->new( config => Load($conf) );

dies_ok { $c->lookup(); } 'non-existent lookup';
dies_ok { $c->lookup(''); } 'non-existent lookup';

is $c->lookup('somenull'), undef, 'somenull';
is $c->lookup('greeting'), "Hello World", 'greeting';
is $c->lookup('digits'), 1234567890, 'digits';

is_deeply $c->lookup('href1'), { 'somekey1' => 'somevalue1' }, 'href1';
is_deeply $c->lookup('aref1'), [ 1, "abc" ], 'aref1';

is $c->lookup('ptr1'), $c->lookup('greeting'), 'ptr1=greeting';
is refaddr($c->lookup('ptr1')), refaddr($c->lookup('greeting')), 'same-addr-oREF-greeting';


ok 1;

__END__

