use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.006006
use Test::Spelling 0.12;
use Pod::Wordlist;


add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib  ) );
__DATA__
Shawn
Moore
sartak
Aaron
Crane
arc
David
Steinbrunner
dsteinbrunner
Graham
Knop
haarg
Justin
Hunter
justin
Karen
Etheridge
ether
Peter
Rabbitson
ribasushi
code
gfx
gfuji
lib
Class
Method
Modifiers
