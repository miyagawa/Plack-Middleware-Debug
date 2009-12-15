use inc::Module::Install;
include 'Module::AutoInstall';
name 'Plack-Middleware-Debug';
all_from 'lib/Plack/Middleware/Debug.pm';
readme_from_pod;
readme_markdown_from_pod;
auto_set_homepage;
auto_set_bugtracker;
auto_set_repository;
requires 'parent';
requires 'Plack';
requires 'Text::MicroTemplate';
requires 'Data::Dump';
requires 'File::ShareDir', '1.00';
requires 'Class::Method::Modifiers', '1.05';
feature 'Module versions panel', - default => 1,
    'Module::Versions' => '0.01';
test_requires 'Test::More' => '0.70';
extra_tests;
author_requires 'ShipIt';
author_requires 'ShipIt::Step::DistClean';
author_requires 'ShipIt::Step::DistTestExtra';
author_requires 'ShipIt::Step::Manifest';
author_requires 'ShipIt::Step::Twitter';
author_requires 'Test::Compile';
author_requires 'Test::Perl::Critic';
author_requires 'Test::Pod';
author_requires 'Test::Spelling';
author_requires 'Pod::Wordlist::hanekomu';
author_requires 'Test::Pod::Coverage';

# author_requires 'Test::Kwalitee';
author_requires 'Test::YAML::Meta';
author_requires 'Test::Portability::Files';
author_requires 'Test::Synopsis';
author_requires 'Test::MinimumVersion';
author_requires 'Test::HasVersion';
author_requires 'Test::CheckChanges';
author_requires 'Test::DistManifest';
install_share 'share';
auto_install;
auto_include;

Makefile->postamble(<<EOMAKE);
YUICOMPRESS = ~/bin/yuicompressor.jar
MEDIADIR = share/debug_toolbar

yuicompressor:
\tjava -jar \$(YUICOMPRESS) \$(MEDIADIR)/toolbar.js > \$(MEDIADIR)/toolbar.min.js
\tjava -jar \$(YUICOMPRESS) \$(MEDIADIR)/jquery.cookie.js >> \$(MEDIADIR)/toolbar.min.js
\tjava -jar \$(YUICOMPRESS) --type css \$(MEDIADIR)/toolbar.css > \$(MEDIADIR)/toolbar.min.css
EOMAKE

WriteAll;
