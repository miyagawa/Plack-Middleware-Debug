#!perl -w
use strict;
use warnings;
use Test::More;
eval 'use Test::Pod::Coverage; 1'
  or plan skip_all => 'Test::Pod::Coverage required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING'
  if $ENV{AUTOMATED_TESTING};
plan skip_all => "pod coverage tests turned off in environment"
  if $ENV{PERL_SKIP_POD_COVERAGE_TESTS};

# Pod::Find doesn't use require() but traverses @INC manually. *sigh*
BEGIN { unshift @INC, @Devel::SearchINC::inc if @Devel::SearchINC::inc }
all_pod_coverage_ok();
