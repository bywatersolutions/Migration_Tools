#!/usr/bin/perl
#---------------------------------
# Copyright 2010 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#  --edited to append notes to existing notes
#  --changed the borrowernotes_updater to this version which updates itemnotes
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
my $barlength = 0;
my $barprefix = '';
my $infile_name = "";

GetOptions(
    'in=s'            => \$infile_name,
    'barprefix=s'  => \$barprefix,
    'barlength=i'  => \$barlength,
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
my $sth = $dbh->prepare("UPDATE items SET itemnotes=? WHERE itemnumber=?");
my $borr_sth = $dbh->prepare("SELECT itemnumber,itemnotes FROM items WHERE barcode=?");

my $thisborrowerbar;
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
   $debug and print Dumper(@data);
   next RECORD if $data[0] eq '';

   if ($barprefix ne '' || $barlength > 0) {
            my $curbar = $data[0];
            my $prefixlen = length($barprefix);
            if (($barlength > 0) && (length($curbar) <= ($barlength-$prefixlen))) {
               my $fixlen = $barlength - $prefixlen;
               while (length ($curbar) < $fixlen) {
                  $curbar = '0'.$curbar;
               }
               $curbar = $barprefix . $curbar;
            }
            $data[0] = $curbar;
   }


   $data[0] =~ s/\"//g;
   $borr_sth->execute($data[0]);
   my $rec=$borr_sth->fetchrow_hashref();
   my $borrnumber = $rec->{'itemnumber'};
   my $currnotes = $rec->{'itemnotes'} || ' ';


   if (!$borrnumber) {
     print "no item found for $data[0]\n";
     next RECORD;
   }

   $finalnote = $currnotes."  --  ".$data[1];

   $debug and print "barcode:$data[0] ( $borrnumber ) \nNOTE:$finalnote\n";

   if ($borrnumber && $doo_eet){
      $sth->execute($finalnote,$borrnumber);
   }
   $j++;
}

close $in;

print "\n\n$i lines read.\n$j notes loaded.\n";
exit;
