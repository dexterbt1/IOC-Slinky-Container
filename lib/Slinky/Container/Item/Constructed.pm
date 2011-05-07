package Slinky::Container::Item::Constructed;
use strict;
use Scalar::Util qw/weaken refaddr/;

sub new {
    my ($class, $ns, $new, $args, $singleton) = @_;
    my $self = [ { }, $ns, $new, $args, $singleton ];
    bless($self, $class);
    return $self;
}

sub FETCH {
    my ($self) = @_;
    my ($tmp, $ns, $new, $args, $singleton) = @$self;
    if ($singleton) {
        if (exists $tmp->{last_inst}) {
            return $tmp->{last_inst};
        }
    }
    $tmp->{last_inst} = $ns->$new(@$args);
    return $tmp->{last_inst};
}

1;

__END__
