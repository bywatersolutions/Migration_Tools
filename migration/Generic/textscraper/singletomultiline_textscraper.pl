#!/usr/bin/perl
#---------------------------------
# 2015 Joy Nelson
#
#---------------------------------
#
# -Joy Nelson
#  read one line of data and output value in column 0
#   on a separate line with all the (variable number) of items in columns 1 through ?
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Encode;
use Getopt::Long;
use Text::CSV;
use Text::CSV::Simple;
$|=1;
my $debug=0;

my $infile_name = "";
my $outfile_name = "";
my $csv=Text::CSV->new( { binary=>1} );

GetOptions(
    'in=s'          => \$infile_name,
    'out=s'         => \$outfile_name,
    'debug'         => \$debug,
);

if (($infile_name eq '') || ($outfile_name eq '')){
  print "Something's missing.\n";
  exit;
}
my $i=0;
my $written=0;

my %thisrow;
my @charge_fields= qw{ course_number courseitem };

open my $infl,"<",$infile_name;
open my $outfl,">",$outfile_name || die ('problem opening $outfile_name');
for my $j (0..scalar(@charge_fields)-1){
   print $outfl $charge_fields[$j].',';
}
print $outfl "\n";

my $NULL_STRING = '';
my $course;
my $item;

LINE:
while (my $line=$csv->getline($infl)){
   last LINE if ($debug && $i >5000);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my @data = @$line;
   my $course = $data[0];

   for my $j (2..scalar(@data)-1){
      print $outfl "$course,$data[$j]\n";
   }
  
}
print "\n\n";
close $infl;
close $outfl;

exit;

