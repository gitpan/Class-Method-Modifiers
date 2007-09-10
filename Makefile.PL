# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Class-Method-Modifiers';
all_from       'lib/Class/Method/Modifiers.pm';

requires       'parent';
requires       'Scalar::Util';
requires       'Carp';
requires       'Exporter';
requires       'MRO::Compat';

build_requires 'Test::More';

auto_install;
WriteAll;


