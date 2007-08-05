#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

my $child = Child->new();
eval { $child->DNE };
is($@, "around 'DNE' failed: DNE doesn't exist in Child's inheritance tree at t/50-error.t line ".(__LINE__-1)."\n", "correct error for a does-not-exist method being modified");

BEGIN
{
    package Parent;
    sub new { bless {}, shift }
    sub orig { }
}

BEGIN
{
    package Child;
    use base 'Parent';
    use Class::Method::Modifiers;

    around 'DNE' => sub
    {
        my $orig = shift;
        my $self = shift;

        return $orig->($self);
    };
}

