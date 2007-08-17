#!perl -T
use strict;
use warnings;
use Test::More tests => 1;
my @seen;

TODO:
{
    local $TODO = "calling orig twice screws up the dynamically scoped method list";

    eval { ChildCMM->new->orig() };
    is_deeply(\@seen, ["orig", "orig"], "CMM: calling orig twice in one around works");
}

BEGIN
{
    package Parent;
    sub new { bless {}, shift }
    sub orig { push @seen, "orig" }

    package ChildCMM;
    use base 'Parent';
    use Class::Method::Modifiers;
    around 'orig' => sub { my $orig = shift; $orig->(); $orig->(); };
}

