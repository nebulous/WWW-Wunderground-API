use inc::Module::Install;

name     'WWW-Wunderground-API';
all_from 'lib/WWW/Wunderground/API.pm';
author   q{John Lifsey <nebulous@crashed.net>};
license  'perl';

build_requires 'Test::More';

requires 'Moo';
requires 'LWP::Simple';
requires 'XML::Simple';
requires 'JSON::Any';
requires 'Hash::AsObject';
recommends 'Cache::FileCache'=> 0;

auto_install;

WriteAll;

