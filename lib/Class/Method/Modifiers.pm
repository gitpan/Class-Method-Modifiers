#!perl
package Class::Method::Modifiers;
use strict;
use warnings;
use parent 'Exporter';
use Carp;
use Scalar::Util 'blessed';

our @EXPORT = qw(before around after);

=head1 NAME

Class::Method::Modifiers - provides Moose-like method modifiers

=head1 VERSION

Version 0.01 released 05 Aug 07

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    package Child::Class;
    use parent 'Parent::Class';
    use Class::Method::Modifiers;

    sub new_method {}

    before 'old_method' => sub
    {
        warn "old_method is deprecated, use new_method";
    };

    around 'other_method' => sub
    {
        my $orig = shift;
        my ($self, @args) = @_;

        my $ret = $orig->($self, @args);
        return lc $ret;
    };

=head1 MODIFIERS

All three modifiers; C<before>, C<after>, and C<around>; are exported into your
namespace by default. You may C<use Class::Method::Modifiers ()> to avoid
thrashing your namespace. I may steal more features from Moose, namely
C<super>, C<override>, C<inner>, C<augment>, and whatever the L<Moose> folks
come up with next.

Note that the syntax and semantics for these modifiers is directly borrowed
from L<Moose> (the implementations, however, are not).

=head2 before

C<before> is called before the method it is modifying. Its return value is
totally ignored. We try to avoid letting it affect the original method's C<@_>,
but not very hard. We just make a shallow copy.

=cut

sub before($&)
{
    my $method = shift;
    my $modifier = shift;
    my $install_into = caller(0);

    no strict 'refs';
    *{$install_into."::".$method} = sub
    {
        my $self = shift;
        my $dispatch = $self->UNIVERSAL::super($method, $install_into);
        Carp::croak "before '$method' failed: $method doesn't exist in "
                  . blessed($self) . "'s inheritance tree"
                      if !$dispatch;

        my @copy = @_;
        $modifier->($self, @copy);

        return $dispatch->($self, @_);
    };
}

=head2 after
 
C<after> is called after the method it is modifying. Its return value is
totally ignored. We try to avoid letting the original method affect C<after>'s
C<@_>, but not very hard. We just make a shallow copy.

=cut

sub after($&)
{
    my $method = shift;
    my $modifier = shift;
    my $install_into = caller(0);

    no strict 'refs';
    *{$install_into."::".$method} = sub
    {
        my $self = shift;
        my $dispatch = $self->UNIVERSAL::super($method, $install_into);
        Carp::croak "after '$method' failed: $method doesn't exist in "
                  . blessed($self) . "'s inheritance tree"
                      if !$dispatch;

        my @copy = @_;

        my @ret;
        if (wantarray)
        {
            @ret = $dispatch->($self, @_);
        }
        else
        {
            $ret[0] = $dispatch->($self, @_);
        }

        $modifier->($self, @copy);

        return wantarray ? @ret : $ret[0];
    };
}

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

=cut

sub around($&)
{
    my $method = shift;
    my $modifier = shift;
    my $install_into = caller(0);

    no strict 'refs';
    *{$install_into."::".$method} = sub
    {
        my $self = shift;
        my $dispatch = $self->UNIVERSAL::super($method, $install_into);
        Carp::croak "around '$method' failed: $method doesn't exist in "
                  . blessed($self) . "'s inheritance tree"
                      if !$dispatch;

        return $modifier->($dispatch, $self, @_);
    };
}

=head1 CAVEATS

It is erroneous to modify a method that doesn't exist in your class's
inheritance hierarchy. If this occurs, an exception will be thrown.

The behavior of using multiple modifiers on a single method in a single class
is undefined. This includes defining an overriding method in the usual way,
i.e. with C<sub methodname { ... }>. You may of course subclass a class that
uses C<Class::Method::Modifiers> and wrap its already-wrapped methods.

It uses a small amount of Cozens magic to figure out how to call the method in
your inheritance hierarchy. I'm not sure how well this will play with Brandon
Black's C3 MRO.

The last thing I did before cutting this first release was fixing a hefty bug.
I'm certain there are more of them lurking around.

=cut

# <magic author="cozens">
package UNIVERSAL;

sub super
{
    my ($class, $method, $force_pkg) = @_;

    if (ref $class)
    {
        $class = ref $class
    }
    $class = $force_pkg if $force_pkg;

    my $coderef;

    no strict 'refs';
    for (@{$class."::ISA"}, "UNIVERSAL")
    {
        return $coderef if $coderef = $_->can($method);
    }

    return;
}
# </magic>

=head1 SEE ALSO

C<Moose>, C<rubyism>, CLOS

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

=head1 BUGS

No known bugs.

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

Thanks to Simon Cozens for writing L<rubyisms>, from which this module borrowed
some magic.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

