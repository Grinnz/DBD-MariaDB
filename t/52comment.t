use strict;
use warnings;

use DBI;
use DBI::Const::GetInfoType;
use Test::More;
use lib 't', '.';
require 'lib.pl';

use vars qw($test_dsn $test_user $test_password);

my $dbh = DbiTestConnect($test_dsn, $test_user, $test_password,
                      { RaiseError => 1,
                        PrintError => 1, 
                        AutoCommit => 0, }
                        );
plan tests => 30; 

ok $dbh->do("DROP TABLE IF EXISTS dbd_mysql_t52comment"), "drop table if exists dbd_mysql_t52comment";

my $create= <<"EOTABLE";
create table dbd_mysql_t52comment (
    id bigint unsigned not null default 0
    )
EOTABLE


ok $dbh->do($create), "creating table";

my $statement= "insert into dbd_mysql_t52comment (id) values (?)";

my $sth;
ok $sth= $dbh->prepare($statement);

my $rows;
ok $rows= $sth->execute('1');
cmp_ok $rows, '==',  1;
$sth->finish();

$statement= <<EOSTMT;
SELECT id 
FROM dbd_mysql_t52comment
-- it's a bug?
WHERE id = ?
EOSTMT

my $retrow= $dbh->selectrow_arrayref($statement, {}, 1);
cmp_ok $retrow->[0], '==', 1;

$statement= "SELECT id FROM dbd_mysql_t52comment /* it's a bug? */ WHERE id = ?";

$retrow= $dbh->selectrow_arrayref($statement, {}, 1);
cmp_ok $retrow->[0], '==', 1;

$statement= "SELECT id FROM dbd_mysql_t52comment WHERE id = ? /* it's a bug? */";

$retrow= $dbh->selectrow_arrayref($statement, {}, 1);
cmp_ok $retrow->[0], '==', 1;

$statement= "SELECT id FROM dbd_mysql_t52comment WHERE id = ? ";
my $comment = "/* it's/a_directory/does\ this\ work/bug? */";

for (0 .. 9) {
    $retrow= $dbh->selectrow_arrayref($statement . $comment, {}, 1);
    cmp_ok $retrow->[0], '==', 1;
}

$comment = "/* $0 */";

for (0 .. 9) {
    $retrow= $dbh->selectrow_arrayref($statement . $comment, {}, 1);
    cmp_ok $retrow->[0], '==', 1;
}

ok $dbh->do("DROP TABLE IF EXISTS dbd_mysql_t52comment"), "drop table if exists dbd_mysql_t52comment";

ok $dbh->disconnect;
