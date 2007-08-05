#!perl -T
use strict;
use warnings;
use Test::More tests => 12;

my ($orig_called, $around_saw_orig_set, $around_saw_orig_unset) = (0, 0, 0);
my $parent = Parent->new();
ok(!$orig_called,           "orig not called at Parent->new time..");
ok(!$around_saw_orig_set,   "around not called at Parent->new time..");
ok(!$around_saw_orig_unset, "around not called at Parent->new time..");

($orig_called, $around_saw_orig_set) = (0, 0, 0);
$parent->orig();
ok( $orig_called,           "orig called by Parent->orig");
ok(!$around_saw_orig_set,   "around not called by Parent->orig");
ok(!$around_saw_orig_unset, "around not called by Parent->orig");

($orig_called, $around_saw_orig_set) = (0, 0, 0);
my $child = Child->new();
ok(!$orig_called,           "orig not called at Child->new time..");
ok(!$around_saw_orig_set,   "around not called at Child->new time..");
ok(!$around_saw_orig_unset, "around not called at Child->new time..");

($orig_called, $around_saw_orig_set) = (0, 0, 0);
$child->orig();
ok( $orig_called,           "original method called by Child->orig");
ok( $around_saw_orig_set,   "around modifier called around original method in Child->orig");
ok( $around_saw_orig_unset, "around modifier called around original method in Child->orig");

BEGIN
{
    package Parent;
    sub new { bless {}, shift }
    sub orig
    {
        my $self = shift;

        $orig_called = 1;
    }
}

BEGIN
{
    package Child;
    use base 'Parent';
    use Class::Method::Modifiers;

    around 'orig' => sub
    {
        my $orig = shift;
        my $self = shift;

        $around_saw_orig_unset = 1
            if !$orig_called;

        $orig->($self);

        $around_saw_orig_set = 1
            if $orig_called;

    };
}
