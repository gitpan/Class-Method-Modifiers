#!perl -T
use strict;
use warnings;
use Test::More tests => 4;

eval
{
    package Parent;
    sub new { bless {}, shift }
    sub orig
    {
        my $self = shift;
        return;
    }
};

ok(!$@, "no error defining parent");

eval
{
    package ChildBefore;
    use base 'Parent';
    use Class::Method::Modifiers;

    before 'orig' => sub
    {
    };

    before 'orig' => sub
    {
    };
};

like($@, qr{\ARedefinition of 'before orig' in ChildBefore at }, "before before gives error");

eval
{
    package ChildAround;
    use base 'Parent';
    use Class::Method::Modifiers;

    around 'orig' => sub
    {
    };

    around 'orig' => sub
    {
    };
};

like($@, qr{\ARedefinition of 'around orig' in ChildAround at }, "around around gives error");

eval
{
    package ChildAfter;
    use base 'Parent';
    use Class::Method::Modifiers;

    after 'orig' => sub
    {
    };

    after 'orig' => sub
    {
    };
};

like($@, qr{\ARedefinition of 'after orig' in ChildAfter at }, "after after gives error");

