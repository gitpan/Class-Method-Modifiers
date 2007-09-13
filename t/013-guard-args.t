#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

my $storage = "Foo";

my $child = Child->new();
is($child->orig($storage), "guard foo", "guard affected orig's args a little");

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
    our @ISA = 'Parent';
    use Class::Method::Modifiers 'guard';

    guard 'orig' => sub
    {
        my $self = shift;
        $_[0] = 'Guard ' . $_[0];

        my $discard = shift;
        $discard = "will never be seen";
        return ["lc on an arrayref? ha ha ha"];
    };
}

