requires 'perl', '5.008001';
requires 'Amon2';
requires 'DBD::SQLite';
requires 'DBI';
requires 'Digest::SHA';
requires 'Teng';
requires 'parent';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

