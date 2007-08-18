#!perl
package Class::Method::Modifiers;
use strict;
use warnings;
use parent 'Exporter';
use Carp;
use Scalar::Util 'blessed';
use MRO::Compat;

our $VERSION = '0.05';

our @EXPORT = qw(before around after);

# this is a dynamically scoped variable that has, during an around, the arounds
# that must be called "inside" that around. this includes the original method.
# implemented so multiple arounds by the same class does the right thing
our @AROUNDS_LEFT;

# keeps track of what modifiers we've defined
my %method_cache;

my %type_expand = (A => "after", B => "before", C => "around");

# this is the method that gets injected into each class
sub _resolve
{
    my $methodname = shift;
    my $package    = shift;
    my $qualified  = $package . '::' . $methodname;
    my $dispatch   = $method_cache{"X$qualified"};

    if (!$dispatch)
    {
        # see where we'd dispatch to next. mro's next::method doesn't let us do
        # next-method resolution as a third party :(
        SEARCH:
        {
            no strict 'refs';

            my @mro = @{ mro::get_linear_isa($package) };
            shift @mro; # get_linear_isa annoyingly returns self as well
            for (@mro)
            {
                next unless $dispatch = *{$_.'::'.$methodname}{CODE};
                last SEARCH;
            }

            Carp::croak "Modifier of '$methodname' failed: $methodname doesn't exist in " . blessed($_[0]) . "'s inheritance hierarchy";
        }

        $method_cache{"X$qualified"} = $dispatch;
    }

    my $before = $method_cache{"B$qualified"} || [];
    my $after  = $method_cache{"A$qualified"} || [];
    my $around = $method_cache{"C$qualified"} || [];

    for (@$before)
    {
        $_->(@_);
    }

    my @ret;

    {
        local @AROUNDS_LEFT = (@$around, $dispatch);
        if (wantarray)
        {
            @ret = _orig(@_);
        }
        else
        {
            $ret[0] = _orig(@_);
        }
    }

    for (@$after)
    {
        $_->(@_);
    }

    return wantarray ? @ret : $ret[0];
}

# this handles the injection and error checking
sub _install
{
    my $mod_type   = shift;
    my $methodname = shift;
    my $modifier   = shift;
    my $package    = @_ ? shift : caller(1);
    my $qualified  = $package . '::' . $methodname;
    my $already_installed = 0;

    no strict 'refs';
    if (*{$qualified}{CODE})
    {
        $already_installed = 1;

        # if we have an existing method, and we don't know about it, that is
        # a "sub foo" that we probably don't want
        if (!exists($method_cache{"A$qualified"})
         && !exists($method_cache{"B$qualified"})
         && !exists($method_cache{"C$qualified"}))
        {
            # it's not ok to say 'sub foo' 'around foo =>'
            Carp::croak "You seem to have both 'sub $methodname' and \"$type_expand{$mod_type} '$methodname'\" in $package";
        }
    }

    if ($mod_type eq 'A')
    {
        # after methods work in the order they were defined
        push @{$method_cache{"A$qualified"}}, $modifier;
    }
    else
    {
        # before and around are the opposite
        unshift @{$method_cache{"$mod_type$qualified"}}, $modifier;
    }

    *{$qualified} = sub
    {
        unshift @_, $methodname, $package;
        goto &_resolve;
    } unless $already_installed;
}

# this implements the magic needed for multiple "around"s in one class
# this is the function that is actually called when you invoke $orig, it
# figures out what to dispatch to next. it does so using the dynamically scoped
# @AROUNDS_LEFT, which is set for us by _resolve
sub _orig
{
    my $next = shift @AROUNDS_LEFT
        or die "It looks like you're calling \$orig more than once in around. Don't!!";

    # need to set up the next $orig
    unshift @_, \&_orig if @AROUNDS_LEFT;

    goto &$next;
}

sub before
{
    my $modifier = pop;
    for (@_)
    {
        _install('B', $_, $modifier);
    }
}

sub after
{
    my $modifier = pop;
    for (@_)
    {
        _install('A', $_, $modifier);
    }
}

sub around
{
    my $modifier = pop;
    for (@_)
    {
        _install('C', $_, $modifier);
    }
}

=head1 NAME

Class::Method::Modifiers - provides Moose-like method modifiers

=head1 VERSION

Version 0.05 released 17 Aug 07

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
thrashing your namespace. I may steal more features from L<Moose>, namely
C<super>, C<override>, C<inner>, C<augment>, and whatever the L<Moose> folks
come up with next.

Note that the syntax and semantics for these modifiers is directly borrowed
from L<Moose> (the implementations, however, are not).

Parent classes need not know about C<Class::Method::Modifiers>. This means you
should be able to modify methods in I<any> subclass.

=head2 before method(s) => sub { ... }

C<before> is called before the method it is modifying. Its return value is
totally ignored. It receives the same C<@_> as the the method it is modifying
would have received. You can modify the C<@_> the original method will receive
by changing C<$_[0]> and friends (or by changing anything inside a reference).
This is a feature!

=head2 after method(s) => sub { ... }

C<after> is called after the method it is modifying. Its return value is
totally ignored. It receives the same C<@_> as the the method it is modifying
received, mostly. The original method can modify C<@_> (such as by changing
C<$_[0]> or references) and C<after> will see the modified version. If you
don't like this behavior, specify both a C<before> and C<after>, and copy the
C<@_> during C<before> for C<after> to use.

=head2 around method(s) => sub { ... }

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

It doesn't yet play well with C<caller>. There are some todo tests for this.

=head1 SEE ALSO

L<Moose>, L<Class::MOP::Method::Wrapped>, L<MRO::Compat>, CLOS

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

=head1 BUGS

Calling C<$orig> twice in an C<around> modifier is prone to breakage. Moose
supports this, I currently don't.

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

Thanks to Stevan Little for L<Moose>, I would never have known about
method modifiers otherwise.

Thanks to Matt Trout and Stevan Little for their advice.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

