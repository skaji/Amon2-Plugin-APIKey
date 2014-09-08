package Amon2::Plugin::APIKey;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Amon2::Util ();

sub init {
    my ($class, $c, $config) = @_;

    Amon2::Util::add_method($c, 'api_key' => sub {
        my ($c, %option) = @_;
        $c->{_api_key} ||= do {
            my $mode = $c->mode_name || "development";
            my $dbname = delete $option{dbname}
                || File::Spec->catfile($c->base_dir, "db", "api_key.$mode.db");
            Amon2::Plugin::APIKey::Impl->new(dbname => $dbname, %option);
        };
    });

}

package Amon2::Plugin::APIKey::Impl;
use Teng;
use File::Spec;
use File::Path 'mkpath';
use File::Basename 'dirname';
use Digest::SHA ();
use Time::HiRes ();
use Amon2::Util qw(random_string);
use constant EXPIRE_AT => 9999999999;

sub new {
    my ($class, %opt) = @_;
    my $secret = $opt{secret} || "secret";
    my $dbname = $opt{dbname} or die;
    if (!-d dirname($dbname)) {
        mkpath dirname($dbname);
    }
    my $sql = Amon2::Plugin::APIKey::DB::Schema::schema_sql();
    my $schema = Amon2::Plugin::APIKey::DB::Schema->instance;
    my $db = Amon2::Plugin::APIKey::DB->new(
        connect_info => ["dbi:SQLite:dbname=$dbname", "", "", ],
        on_connect_do => [$sql],
        schema => $schema,
    );
    bless { db => $db, secret => $secret }, $class;
}

sub create {
    my $self = shift;
    my %option = ref $_[0] ? %{$_[0]} : @_;
    my $db = $self->{db};
    for (1..10) {
        my $random = random_string(32);
        my $value  = $self->sha1($random);
        my $txn = $db->txn_scope;
        my $id = eval {
            $db->fast_insert('api_key' => {
                expire_at => EXPIRE_AT,
                created_at => time,
                %option,
                value => $value
            });
        };
        if (defined $id) {
            $txn->commit;
            return $random;
        } else {
            $txn->rollback;
        }
    }
    return undef;
}
sub purge {
    my $self = shift;
    $self->{db}->delete('api_key', {expire_at => { "<" => time }});
}

sub sha1 {
    my $self = shift;
    my $value = shift;
    Digest::SHA::sha1_hex( $value . $self->{secret} );
}

sub is_valid {
    my $self = shift;
    my $value = shift or die;
    my $row = $self->single(value => $self->sha1($value));
    $row && time < $row->get('expire_at') ? 1 : 0;
}
sub expire {
    my $self = shift;
    my %option = ref $_[0] ? %{$_[0]} : @_;
    my %other = $option{value} ? (value => $self->sha1(delete $option{value})) : ();
    $self->{db}->delete('api_key', {%option, %other});
}
sub search {
    my $self = shift;
    my %option = ref $_[0] ? %{$_[0]} : @_;
    $self->{db}->search('api_key', \%option);
}
sub single {
    my $self = shift;
    my %option = ref $_[0] ? %{$_[0]} : @_;
    $self->{db}->single('api_key', \%option);
}

package Amon2::Plugin::APIKey::DB;
use parent 'Teng';

package Amon2::Plugin::APIKey::DB::Schema;
use Teng::Schema::Declare;
sub schema_sql {
    return q{
        CREATE TABLE IF NOT EXISTS api_key (
            id INTEGER PRIMARY KEY AUTOINCREMENT
            , user TEXT
            , name TEXT
            , value TEXT NOT NULL
            , created_at INTEGER NOT NULL
            , expire_at INTEGER NOT NULL
            , UNIQUE(value)
        )
    };
}

table {
    name 'api_key';
    pk 'id';
    columns qw(id user name value created_at expire_at);
};

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::APIKey - It's new $module

=head1 SYNOPSIS

    use Amon2::Plugin::APIKey;

=head1 DESCRIPTION

Amon2::Plugin::APIKey is ...

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

