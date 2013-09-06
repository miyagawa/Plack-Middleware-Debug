requires 'Class::Method::Modifiers', '1.05';
requires 'Data::Dump';
requires 'Encode', '2.23';
requires 'File::ShareDir', '1.00';
requires 'Plack';
requires 'Text::MicroTemplate', '0.15';
requires 'parent';
requires 'perl', '5.008001';

on test => sub {
    requires 'Test::More', '0.70';
};
