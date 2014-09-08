use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::Plugin::APIKey;
use File::Temp 'tempdir';

subtest basic1 => sub {
    my $tempdir = tempdir CLEANUP => 1;
    my $temp = "$tempdir/hoge.db";
    my $api_key = Amon2::Plugin::APIKey::Impl->new(dbname => $temp);
    my $key = $api_key->create(user => "hoge", name => "foo");
    my @s = $api_key->search;
    diag "$_ -> " . ($s[0]->get($_) || "") for qw(id user name value created_at expire_at);
    ok $key;
    diag $key;
    ok $api_key->is_valid($key);
    ok $api_key->expire(value => $key);
};
subtest basic2 => sub {
    my $tempdir = tempdir CLEANUP => 1;
    my $temp = "$tempdir/hoge.db";
    my $api_key = Amon2::Plugin::APIKey::Impl->new(dbname => $temp);
    my $now = time;
    my $key = $api_key->create(user => "hoge", name => "foo", expire_at => $now - 10);
    ok $key;
    diag $key;
    ok !$api_key->is_valid($key);
    ok $api_key->purge;
    my @key = $api_key->search;
    is scalar(@key), 0;
};

subtest basic3 => sub {
    my $tempdir = tempdir CLEANUP => 1;
    my $temp = "$tempdir/hoge.db";
    my $api_key = Amon2::Plugin::APIKey::Impl->new(dbname => $temp);
    my $now = time;
    for (1..10) {
        $api_key->create(user => "hoge", name => "foo", expire_at => $now + 100);
        $api_key->create(user => "hoge", name => "foo", expire_at => $now - 100);
        $api_key->create(user => "hoge", name => "foo", expire_at => $now - 200);
    }
    my @s = $api_key->search;
    is scalar(@s), 30;
    ok $api_key->purge;
    @s = $api_key->search;
    is scalar(@s), 10;
};

done_testing;





