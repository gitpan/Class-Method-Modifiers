#!perl -T
use strict;
use warnings;
use Test::More tests => 12;

my ($orig_called, $after_called, $after_saw_orig_set) = (0, 0, 0);
my $parent = Parent->new();
ok(!$after_called,       "after not called at Parent->new time..");
ok(!$orig_called,        "orig not called at Parent->new time..");
ok(!$after_saw_orig_set, "after not called at Parent->new time..");

($orig_called, $after_called, $after_saw_orig_set) = (0, 0, 0);
$parent->orig();
ok(!$after_called,       "after not called by Parent->orig");
ok( $orig_called,        "orig called by Parent->orig");
ok(!$after_saw_orig_set, "after not called by Parent->orig");

($orig_called, $after_called, $after_saw_orig_set) = (0, 0, 0);
my $child = Child->new();
ok(!$after_called,       "after not called at Child->new time..");
ok(!$orig_called,        "orig not called at Child->new time..");
ok(!$after_saw_orig_set, "after not called at Child->new time..");

($orig_called, $after_called, $after_saw_orig_set) = (0, 0, 0);
$child->orig();
ok( $after_called,       "after modifier called by Child->orig");
ok( $orig_called,        "original method called by Child->orig");
ok( $after_saw_orig_set, "after modifier called after original method in Child->orig");

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
    use Class::Method::Modifiers;

    after 'orig' => sub
    {
        my $self = shift;

        $after_saw_orig_set = 1
            if $orig_called;
        $after_called = 1;
    };
}

