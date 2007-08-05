#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

my $child = Child->new();
is($child->orig("Foo"), "foo", "before didn't affect orig's args");

BEGIN
{
    package Parent;
    sub new { bless {}, shift }
    sub orig
    {
        my $self = shift;
        return lc shift;
    }
}

BEGIN
{
    package Child;
    use base 'Parent';
    use Class::Method::Modifiers;

    before 'orig' => sub
    {
        my $self = shift;
        my $discard = shift;
        return ["lc on an arrayref? ha ha ha"];
    };
}
