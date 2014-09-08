use strict;
use warnings;
use utf8;
use Test::More;
use Amon2::Plugin::APIKey;
use File::Temp 'tempfile';

subtest basic1 => sub {
    my (undef, $temp) = tempfile UNLINK => 0;
    unlink $temp;
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
    my (undef, $temp) = tempfile UNLINK => 0;
    unlink $temp;
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

done_testing;





