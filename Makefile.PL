use inc::Module::Install;
name 'Plack-Middleware-Debug';
all_from 'lib/Plack/Middleware/Debug.pm';
readme_from 'lib/Plack/Middleware/Debug.pm';
auto_set_repository;
requires 'parent';
requires 'Plack';
requires 'Text::MicroTemplate', 0.15;
requires 'Data::Dump';
requires 'File::ShareDir', '1.00';
requires 'Class::Method::Modifiers', '1.05';
requires 'Encode', 2.23;
feature 'Module versions panel', - default => 0,
    'Module::Versions' => '0.01';
test_requires 'Test::More' => '0.70';
test_requires 'Test::Requires';
install_share 'share';
auto_install;

Makefile->postamble(<<EOMAKE);
YUICOMPRESS = ~/bin/yuicompressor.jar
MEDIADIR = share/debug_toolbar

yuicompressor:
\tjava -jar \$(YUICOMPRESS) \$(MEDIADIR)/toolbar.js > \$(MEDIADIR)/toolbar.min.js
\tjava -jar \$(YUICOMPRESS) \$(MEDIADIR)/jquery.cookie.js >> \$(MEDIADIR)/toolbar.min.js
\tjava -jar \$(YUICOMPRESS) --type css \$(MEDIADIR)/toolbar.css > \$(MEDIADIR)/toolbar.min.css
EOMAKE

WriteAll;
