#!perl -w
use strict;
use warnings;
use FindBin '$Bin';
use File::Spec;
use Test::More;
eval 'use Perl::Critic; 1'
  or plan skip_all => 'Perl::Critic required';
eval 'use Test::Perl::Critic; 1'
  or plan skip_all => 'Test::Perl::Critic required';
plan skip_all => 'skip author tests during AUTOMATED_TESTING'
  if $ENV{AUTOMATED_TESTING};
my %opt;
my $rc_file = File::Spec->catfile($Bin, 'perlcriticrc');
$opt{'-profile'} = $rc_file if -r $rc_file;
Test::Perl::Critic->import(%opt);
all_critic_ok("lib");
