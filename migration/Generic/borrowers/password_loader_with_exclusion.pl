#!/usr/bin/perl
#---------------------------------
# Copyright 2010 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# -Joy Nelson --added exclusion clause 3/21/2012
#---------------------------------
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use C4::Context;
use Digest::MD5 qw(md5_base64);
$|=1;
my $debug=0;
my $doo_eet=0;
my $infile_name = "";

GetOptions(
    'in=s'      => \$infile_name,
    'debug'     => \$debug,
    'update'    => \$doo_eet,
);

if (($infile_name eq '')){
 print "You're missing something.\n";
 exit;
}

my $csv=Text::CSV->new();
my $dbh=C4::Context->dbh();
my $i=0;
my $written=0;

my $upd_sth = $dbh->prepare("update borrowers set password=? where cardnumber=? and password is NULL");
my $haspwd_sth = $dbh->prepare("SELECT password from borrowers where cardnumber=?");

open my $io,"<$infile_name";
RECORD:
while (my $row=$csv->getline($io)){
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my @data = @$row;
   next if $data[2];
   next if $data[1] eq '';
   my $password = md5_base64($data[1]);
   $haspwd_sth->execute($data[0]);
   my $pass=$haspwd_sth->fetchrow_hashref();
   my $pass2=$pass->{'password'};
   if ($pass2) {
    print "has password, skipping $data[0]\n";
    next RECORD;
   }

   $debug and print "setting $data[0]...$password\n";
   if ($doo_eet) {
    $upd_sth->execute($password,$data[0]);
    print "updating $data[0] with $data[1] hashed to $password\n";
    $written++;
   }
}

close $io;

print "\n$i records read.\n$written records updated.\n";
