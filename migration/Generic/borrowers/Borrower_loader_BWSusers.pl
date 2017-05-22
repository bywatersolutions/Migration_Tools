#!/usr/bin/perl
#---------------------------------
# Copyright 2015 ByWater Solutions
#
#---------------------------------
#
#  Joy Nelson
#
#---------------------------------
#use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use C4::Context;
use C4::Members;
use Digest::MD5 qw(md5_base64);
$|=1;
my $debug=0;
my $doo_eet=0;

my $training_pwd = '';
my $category = '';
my $branch = '';

GetOptions(
    'trainingpassword=s'     => \$training_pwd,
    'categorycode=s'         => \$category,
    'branchcode=s'           => \$branch,
    'debug'                  => \$debug,
    'update'                 => \$doo_eet
);

#if (($training_pwd eq '')){
# print "You're missing something.\n";
# exit;
#}

my $dbh=C4::Context->dbh();

my $branch_sth = $dbh->prepare("insert into branches (branchcode,branchname) values (?,?)");
my $upd_sth = $dbh->prepare("insert into borrowers (surname,categorycode,branchcode,cardnumber,userid,password,flags) values (?,?,?,?,?,?,?)");
my $anon_sth = $dbh->prepare("insert into borrowers (surname,categorycode,branchcode,cardnumber,userid,flags) values (?,?,?,?,?,?)");
my $sys_sth = $dbh->prepare("update systempreferences set value=? where variable='AnonymousPatron'");

   my $trainuserid = 'training';
   my $password = md5_base64($training_pwd);

   my $bwsuserid = 'bwssupport';
   my $bwspass = "wetC\@T\=n0tHapp4";
   my $bwspassword = md5_base64($bwspass);

   my $webuserid = 'bwsweb';
   my $webpassword = md5_base64("TPPhCDKy4yJ");

   my $anonuser = 'anonymous';

   $doo_eet and $branch_sth->execute($branch,$branch);
   $doo_eet and $upd_sth->execute($trainuserid,$category,$branch,$trainuserid,$trainuserid,$password,"1");
   $doo_eet and $upd_sth->execute($bwsuserid,$category,$branch,$bwsuserid,$bwsuserid,$bwspassword,"1");
   $doo_eet and $upd_sth->execute($webuserid,$category,$branch,$webuserid,$webuserid,$webpassword,"1");
   $doo_eet and $anon_sth->execute($anonuser,$category,$branch,$anonuser,$anonuser,"4");

my $anon = GetMember(cardnumber=>$anonuser);
my $anonpatron=$anon->{'borrowernumber'};
#print "$anonpatron";

   $doo_eet and $sys_sth->execute($anonpatron);


print "\nuser records created.\nAnonymous Patron and system preference set\nTRAINING=> training/$training_pwd\nOPAC=> bwsweb/TPPhCDKy4yJ\nSUPPORT=> bwssupport/wetC\@T\=n0tHapp4\n";
