#!perl -T
use strict;
use warnings;
use Test::More tests => 3;

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
    package Child;
    use base 'Parent';
    use Class::Method::Modifiers;

    after 'orig' => sub
    {
    };

    sub orig
    {
    }
};

like($@, qr{\AYou have seem to have both 'sub orig' and "A 'orig'" in Child at \S+ line \d+\n\z}, "after then sub");

eval
{
    package Child2;
    use base 'Parent';
    use Class::Method::Modifiers;

    sub orig
    {
    }

    after 'orig' => sub
    {
    };

};

like($@, qr{\AYou have seem to have both 'sub orig' and "A 'orig'" in Child2 at \S+ line \d+\n\z}, "after then sub");

