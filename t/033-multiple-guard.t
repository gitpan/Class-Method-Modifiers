#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

my @seen;
my @expected = ("guard 2", "guard 1", "orig");

my $child = Child->new; $child->orig;

is_deeply(\@seen, \@expected, "multiple guards called in the right order");

BEGIN {
    package Parent;
    sub new { bless {}, shift }
    sub orig
    {
        push @seen, "orig";
    }
}

BEGIN {
    package Child;
    our @ISA = 'Parent';
    use Class::Method::Modifiers 'guard';

    guard orig => sub
    {
        push @seen, "guard 1";
    };

    guard orig => sub
    {
        push @seen, "guard 2";
    };
}

