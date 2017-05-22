#!/usr/bin/perl
#---------------------------------
# Copyright 2010 ByWater Solutions
#
#---------------------------------
#
# -drnoe
#  --edited to append notes to existing notes
#  --based on druth's borrowernotes_updater.pl
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use C4::Context;
use C4::Items;
$|=1;
my $debug=0;
my $doo_eet=0;
my $infile_name = "";

GetOptions(
    'in=s'            => \$infile_name,
    'debug'           => \$debug,
    'update'          => \$doo_eet,
);

if (($infile_name eq '')){
  print "Something's missing.\n";
  exit;
}

open my $in,"<$infile_name";
my $i=0;
my $j=0;
my $k=0;
my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("UPDATE aqbooksellers SET notes=? WHERE id=?");
my $vend_sth = $dbh->prepare("SELECT id,notes FROM aqbooksellers WHERE id=?");

my $thisvendor;
RECORD:
while (my $line = readline($in)) {
   last if ($debug and $i>10);
   chomp $line;
   $line =~ s///g;
   $i++;
   print ".";
   print "\r$i" unless $i % 100;
   my $finalnote=q{};
   my @data = split /,/ ,$line, 2;
   #$debug and print Dumper(@data);
   next RECORD if $data[0] eq '';



   $data[1] =~ s/\"//g;
   $vend_sth->execute($data[0]);
   my $rec=$vend_sth->fetchrow_hashref();
   my $id = $rec->{'id'};
   my $currnotes = $rec->{'notes'} || '';



   $finalnote = $currnotes."\n".$data[1];

   $debug and print "ACBOOKSELLER:$data[0] ( $id ) \nNOTE:$finalnote\n";
   if ($id && $doo_eet){
      $sth->execute($finalnote,$id);
   }
   $j++;
}

close $in;

print "\n\n$i lines read.\n$j notes loaded.\n";
exit;
