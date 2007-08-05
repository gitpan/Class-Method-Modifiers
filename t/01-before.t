#!perl -T
use strict;
use warnings;
use Test::More tests => 12;

my ($orig_called, $before_called, $orig_saw_before_set) = (0, 0, 0);
my $parent = Parent->new();
ok(!$before_called,       "before not called at Parent->new time..");
ok(!$orig_called,         "orig not called at Parent->new time..");
ok(!$orig_saw_before_set, "before not called at Parent->new time..");

($orig_called, $before_called, $orig_saw_before_set) = (0, 0, 0);
$parent->orig();
ok(!$before_called,       "before not called by Parent->orig");
ok( $orig_called,         "orig called by Parent->orig");
ok(!$orig_saw_before_set, "before not called by Parent->orig");

($orig_called, $before_called, $orig_saw_before_set) = (0, 0, 0);
my $child = Child->new();
ok(!$before_called,       "before not called at Child->new time..");
ok(!$orig_called,         "orig not called at Child->new time..");
ok(!$orig_saw_before_set, "before not called at Child->new time..");

($orig_called, $before_called, $orig_saw_before_set) = (0, 0, 0);
$child->orig();
ok( $before_called,       "before modifier called by Child->orig");
ok( $orig_called,         "original method called by Child->orig");
ok( $orig_saw_before_set, "before modifier called before original method in Child->orig");

BEGIN
{
    package Parent;
    sub new { bless {}, shift }
    sub orig
    {
        my $self = shift;

        $orig_saw_before_set = 1
            if $before_called;
        $orig_called = 1;
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

        $before_called = 1;
    };
}
