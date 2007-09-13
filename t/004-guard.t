#!perl -T
use strict;
use warnings;
use Test::More tests => 15;

my ($orig_called, $guard_saw_orig_set, $guard_saw_orig_unset) = (0, 0, 0);
my $parent = Parent->new();
ok(!$orig_called,           "orig not called at Parent->new time..");
ok(!$guard_saw_orig_set,    "guard not called at Parent->new time..");
ok(!$guard_saw_orig_unset,  "guard not called at Parent->new time..");

($orig_called, $guard_saw_orig_set) = (0, 0, 0);
$parent->orig();
ok( $orig_called,           "orig called by Parent->orig");
ok(!$guard_saw_orig_set,    "guard not called by Parent->orig");
ok(!$guard_saw_orig_unset,  "guard not called by Parent->orig");

($orig_called, $guard_saw_orig_set) = (0, 0, 0);
my $child = Child->new();
ok(!$orig_called,           "orig not called at Child->new time..");
ok(!$guard_saw_orig_set,    "guard not called at Child->new time..");
ok(!$guard_saw_orig_unset,  "guard not called at Child->new time..");

($orig_called, $guard_saw_orig_set) = (0, 0, 0);
$child->orig();
ok( $orig_called,           "original method called by Child->orig");
ok(!$guard_saw_orig_set,    "guard modifier not called after original method in Child->orig");
ok( $guard_saw_orig_unset,  "guard modifier called before original method in Child->orig");

($orig_called, $guard_saw_orig_set) = (0, 0, 0);
$child->orig("halt!");
ok(!$orig_called,           "original method NOT called by Child->orig");
ok(!$guard_saw_orig_set,    "guard modifier not called after original method in Child->orig");
ok( $guard_saw_orig_unset,  "guard modifier called before original method in Child->orig");

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
    our @ISA = 'Parent';
    use Class::Method::Modifiers 'guard';

    guard 'orig' => sub
    {
        my $self = shift;
        my $arg = shift;
        return if $arg;

        $guard_saw_orig_unset = 1
            if !$orig_called;

        $guard_saw_orig_set = 1
            if $orig_called;

        1
    };
}

