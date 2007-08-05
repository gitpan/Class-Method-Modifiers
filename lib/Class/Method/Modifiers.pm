#!perl
package Class::Method::Modifiers;
use strict;
use warnings;
use parent 'Exporter';
use Carp;
use Scalar::Util 'blessed';

our $VERSION = '0.02';

our @EXPORT = qw(before around after);

my %method_cache;
my %type_expand = (A => "after", B => "before", C => "around");

# <magic author="cozens">
# this will find where a method would have dispatched to if class->method
# didn't already exist. modified a little, but the idea is all his
my $find_super = sub
{
    my ($class, $method, $force_pkg) = @_;

       if ($force_pkg)     { $class = $force_pkg }
    elsif (blessed $class) { $class = blessed $class }

    my $coderef;

    no strict 'refs';
    for (@{$class."::ISA"})
    {
        return $coderef if $coderef = $_->can($method);
    }

    return;
};
# </magic>

# this is the method that gets injected into each class
sub _resolve
{
    my $methodname = shift;
    my $package    = shift;
    my $dispatch = $_[0]->$find_super($methodname, $package);

    if (!$dispatch)
    {
        Carp::croak "Modifier of '$methodname' failed: $methodname doesn't exist in " . blessed($_[0]) . "'s inheritance hierarchy";
    }

    my $qualified = $package . '::' . $methodname;

    my $before = $method_cache{"B$qualified"};
    my $after  = $method_cache{"A$qualified"};
    my $around = $method_cache{"C$qualified"};

    $before->(@_) if $before;

    my @ret;
    if (wantarray)
    {
        @ret = $around ? $around->($dispatch, @_)
                       : $dispatch->(@_);
    }
    else
    {
        $ret[0] = $around ? $around->($dispatch, @_)
                          : $dispatch->(@_);
    }

    $after->(@_) if $after;

    return wantarray ? @ret : $ret[0];
}

# this handles the injection and error checking
sub _install
{
    my $mod_type   = shift;
    my $methodname = shift;
    my $modifier   = shift;
    my $package    = caller;
    my $qualified  = $package . '::' . $methodname;

    # saying 'around', 'around' on the same method is probably a mistake
    if (exists $method_cache{"$mod_type$qualified"})
    {
        Carp::croak "Redefinition of '$type_expand{$mod_type} $methodname' in $package"
    }

    $method_cache{"$mod_type$qualified"} = $modifier;

    no strict 'refs';

    if (exists *{$package.'::'}->{$methodname})
    {
        my @othertypes;
        @othertypes = qw/B C/ if $mod_type eq 'A';
        @othertypes = qw/A C/ if $mod_type eq 'B';
        @othertypes = qw/A B/ if $mod_type eq 'C';

        # it's OK to have multiple different kinds of modifiers
        return if exists $method_cache{"$othertypes[0]$qualified"}
               || exists $method_cache{"$othertypes[1]$qualified"};

        # it's not ok to say 'sub foo' 'around foo =>'
        Carp::croak "You have seem to have both 'sub $methodname' and \"$mod_type '$methodname'\" in $package";
    }

    *{$qualified} = sub
    {
        unshift @_, $methodname, $package;
        goto &_resolve;
    }
}

sub before($&)
{
    unshift @_, "B";
    goto \&_install;
}

sub after($&)
{
    unshift @_, "A";
    goto \&_install;
}

sub around($&)
{
    unshift @_, "C";
    goto \&_install;
}

=head1 NAME

Class::Method::Modifiers - provides Moose-like method modifiers

=head1 VERSION

Version 0.02 released 05 Aug 07

=head1 SYNOPSIS

    package Child::Class;
    use parent 'Parent::Class';
    use Class::Method::Modifiers;

    sub new_method { }

    before 'old_method' => sub
    {
        carp "old_method is deprecated, use new_method";
    };

    around 'other_method' => sub
    {
        my $orig = shift;
        my ($self, @args) = @_;

        my $ret = $orig->($self, @args);
        return $ret =~ /\d/ ? $ret : lc $ret;
    };

=head1 MODIFIERS

All three modifiers; C<before>, C<after>, and C<around>; are exported into your
namespace by default. You may C<use Class::Method::Modifiers ()> to avoid
thrashing your namespace. I may steal more features from Moose, namely
C<super>, C<override>, C<inner>, C<augment>, and whatever the L<Moose> folks
come up with next.

Note that the syntax and semantics for these modifiers is directly borrowed
from L<Moose> (the implementations, however, are not).

Parent classes need not know about C<Class::Method::Modifiers>. This means you
should be able to modify methods in I<any> subclass.

=head2 before

C<before> is called before the method it is modifying. Its return value is
totally ignored. It receives the same C<@_> as the the method it is modifying
would have received. You can modify the C<@_> the original method will receive
by changing C<$_[0]> and friends (or by changing anything inside a reference).
This is a feature!

=head2 after

C<after> is called after the method it is modifying. Its return value is
totally ignored. It receives the same C<@_> as the the method it is modifying
received, mostly. The original method can modify C<@_> (such as by changing
C<$_[0]> or references) and C<after> will see the modified version. If you
don't like this behavior, specify both a C<before> and C<after>, and copy the
C<@_> during C<before> for C<after> to use.

=head2 around

C<around> is called instead of the method it is modifying. The method you're
overriding is passed in as the first argument (called C<$orig> by convention).
Watch out for contextual return values of C<$orig>.

You can use C<around> to:

=over 4

=item Pass C<$orig> a different C<@_>

    around 'method' => sub
    {
        my $orig = shift; my $self = shift;
        $orig->($self, reverse @_);
    };

=item Munge the return value of C<$orig>

    around 'method' => sub
    {
        my $orig = shift;
        ucfirst $orig->(@_);
    };

=item Avoid calling C<$orig> -- conditionally

    around 'method' => sub
    {
        my $orig = shift;
        return $orig->(@_) if time() % 2;
        return "no dice, captain";
    };

=back

=head1 CAVEATS

It is erroneous to modify a method that doesn't exist in your class's
inheritance hierarchy. If this occurs, an exception will be thrown when
the method is invoked.

It uses a small amount of Cozens magic to figure out how to call the method in
your inheritance hierarchy. I'm not sure how well this will play with Brandon
Black's C3 MRO.

It doesn't yet play well with C<caller>. There are some todo tests for this.

=head1 SEE ALSO

C<Moose>, C<Class::MOP::Method::Wrapped>, C<rubyism>, CLOS

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

=head1 BUGS

Please report any bugs through RT: email
C<bug-class-method-modifiers at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Method-Modifiers>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Class::Method::Modifiers

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Method-Modifiers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Method-Modifiers>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Method-Modifiers>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Method-Modifiers>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Stevan Little for Moose, I would never have even known about method
modifiers otherwise.

Thanks to Matt Trout and Stevan Little for their advice.

Thanks to Simon Cozens for writing L<rubyisms>, from which this module borrowed
some magic.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

