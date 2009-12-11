#!perl -w
use strict;
use warnings;
use Test::More;
eval 'use Pod::Wordlist::hanekomu; 1'
  or plan skip_all => 'Pod::Wordlist::hanekomu required';
eval 'use Test::Spelling; 1'
  or plan skip_all => 'Test::Spelling required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING'
  if $ENV{AUTOMATED_TESTING};
all_pod_files_spelling_ok('lib');
