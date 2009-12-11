#!perl
use strict;
use warnings;
use Test::More;
eval 'use Test::YAML::Meta; 1' or
    plan skip_all => 'Test::YAML::Meta required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING' if
    $ENV{AUTOMATED_TESTING};
meta_yaml_ok();
