package IOC::Slinky::Container;
use strict;
use IOC::Slinky::Container::Item::Ref;
use IOC::Slinky::Container::Item::Literal;
use IOC::Slinky::Container::Item::Constructed;
use Carp ();

sub new {
    my ($class, %args) = @_;
    my $self = bless { }, $class;
    $self->{typeof} = { };
    if (exists $args{config}) {
        $self->configure( delete $args{config} );
    }
    $self;
}

sub typeof { 
    $_[0]->{typeof};
}

sub configure {
    my ($self, $conf) = @_;
    (ref($conf) eq 'HASH')
        or Carp::croak("Expected 'container' key as hash reference");
    (exists $conf->{'container'})
        or Carp::croak("Expected 'container' key");
    my $container = delete $conf->{'container'};
    foreach my $k (keys %$container) {
        my $v = delete $container->{$k};
        $self->wire($v, $k);
    }
}

sub wire {
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
                $oinst = tie $_[1], 'IOC::Slinky::Container::Item::Ref', $self, $v->{'_ref'};
            }
            elsif (exists $v->{'_class'}) {
                # object!
                my $ns = delete $v->{'_class'};
                my $new = delete $v->{'_constructor'} || 'new';
                my $ctor = delete $v->{'_constructor_args'} || [ ];

                my $singleton = 1;
                if (exists $v->{'_singleton'}) {
                    $singleton = delete $v->{'_singleton'};
                }
                $self->wire($ctor);

                my $alias = delete $v->{'_lookup_id'};
                if (defined $alias) {
                    push @k_aliases, $alias;
                }
                $oinst = tie $_[1], 'IOC::Slinky::Container::Item::Constructed', $self, $ns, $new, $ctor, $v, $singleton;
            }
            else {
                # plain hashref ... traverse first
                foreach my $hk (keys %$v) {
                    if ($hk eq '_lookup_id') {
                        push @k_aliases, delete($v->{$hk});
                        next;
                    }
                    $self->wire($v->{$hk});
                }
                $oinst = tie $v, 'IOC::Slinky::Container::Item::Literal', $v;
            }
        }
        elsif (ref($v) eq 'ARRAY') {
            # arrayref are to be traversed for refs
            my $count = scalar(@$v)-1;
            for(0..$count) {
                $self->wire($v->[$_]);
            }
            $oinst = tie $v, 'IOC::Slinky::Container::Item::Literal', $v;
        }
        else {
            # other ref types
            $oinst = tie $v, 'IOC::Slinky::Container::Item::Literal', $v;
        }
    }
    else {
        # literal
        $oinst = tie $v, 'IOC::Slinky::Container::Item::Literal', $v;
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


1;

__END__

=head1 NAME

IOC::Slinky::Container - a minimalist dependency-injection container

=head1 SYNOPSIS

    # in myapp.yml
    ---
    container:
        db_dsn: "DBI:mysql:database=myapp"
        db_user: "myapp"
        db_pass: "myapp"
        logger:
            _class: FileLogger
            _constructor_args:
                filename: "/var/log/myapp/debug.log"
        myapp:
            _class: "MyApp"
            _constructor_args:
                dbh:
                    _class: "DBI"
                    _constructor: "connect"
                    _constructor_args:
                        - { _ref => "db_dsn" }
                        - { _ref => "db_user" }
                        - { _ref => "db_pass" }
                        - { RaiseError => 1 }
                logger:
                    _ref: logger

    # in myapp.pl
    # ...
    use IOC::Slinky::Container;
    use YAML qw/LoadFile/;

    my $c = IOC::Slinky::Container->new( config => LoadFile('myapp.yml') );
    my $app = $c->lookup('myapp');
    $app->run;


=head1 DESCRIPTION

This module aims to be a transparent and simple dependency-injection (DI) 
container; usually preconfigured from a configuration file.

A DI-container is a special object used to load and configure other 
components/objects. Each object can then be globally resolved
using a unique lookup id. 

For more information about the benefits of the technique, see 
L<Dependency Injection|http://en.wikipedia.org/wiki/Dependency_Injection>.

=head1 METHODS

=over

=item CLASS->new( config => $conf )

Returns an container instance based on the configuration specified
by the hashref C<$conf>. See L</CONFIGURATION> for details.

=item $container->lookup($key)

Returns the C<$obj> if C<$key> lookup id is found in the container,
otherwise it returns undef.

=back

=head1 CONFIGURATION

=head3 Rules

=over

The configuration should be a plain hash reference.

A single top-level key C<container> should be a hash reference;
where its keys will act as global namespace for all objects to be resolved.

    # an empty container
    $c = IOC::Slinky::Container->new( 
        config => {
            container => {
            }
        }
    );

A container value can be one of the following:

=item Constructed Object

=item Reference

=item Literal

    # literals
    $c = IOC::Slinky::Container->new( 
        config => {
            container => {
                null        => undef,
                greeting    => "Hello World",
                pi          => 3.1416,
                plain_href  => { a => 1 },
                plain_aref  => [ 1, 2, 3 ],
            }
        }
    );

=back

=head3 Recommended Practices

=over

L<IOC::Slinky::Container>'s configuration is simply a hash-reference 
with a specific structure. It can come from virtually anywhere.
Our recommended usage however is to externalize the configuration 
(e.g. in a file), and to use L<YAML> (for conciseness and ease-of-editing).

    use IOC::Slinky::Container;
    use YAML qw/LoadFile/;
    my $c = IOC::Slinky::Container->new( config => LoadFile("/etc/myapp.yml") );
    # ...

=back

=head1 SEE ALSO

L<Bread::Broad> - a Moose-based DI framework

L<IOC> - the ancestor of L<Bread::Board>

L<http://en.wikipedia.org/wiki/Dependency_Injection>

L<YAML>

=head1 AUTHOR

Dexter Tad-y, <dtady@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Dexter Tad-y

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


