#!/usr/bin/perl

use autodie;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Modern::Perl;
use Readonly;
use Text::CSV_XS;
use C4::Context;
use C4::Overdues;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};
my $start_time             =  time();

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $written = 0;
my $problem = 0;

GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT * FROM accountlines WHERE accounttype='FU'");
my $update_sth = $dbh->prepare("UPDATE accountlines set accounttype='F' where borrowernumber=? and accountno=? and date=?");
$sth->execute();

LINE:
while (my $line=$sth->fetchrow_hashref()) {
   last LINE if ($debug and $written);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);

   my $fix_this = 0;
   $debug and print Dumper($line);

   if (!defined $line->{itemnumber}) {
      $fix_this = 1;
   }
   else {
      my $this_issue = GetIssuesIteminfo($line->{itemnumber});
      $debug and print Dumper($this_issue);
      if (!defined $this_issue || $this_issue->{borrowernumber} != $line->{borrowernumber}) {
         $fix_this = 1;
      }
   }

   if ($fix_this){
      if ($doo_eet) {
         $update_sth->execute($line->{borrowernumber},$line->{accountno},$line->{date});
      }
      $written++;
   }
}

print << "END_REPORT";

$i records read.
$written records written.
$problem records not loaded due to problems.
END_REPORT

my $end_time = time();
my $time     = $end_time - $start_time;
my $minutes  = int($time / 60);
my $seconds  = $time - ($minutes * 60);
my $hours    = int($minutes / 60);
$minutes    -= ($hours * 60);

printf "Finished in %dh:%dm:%ds.\n",$hours,$minutes,$seconds;

exit;
