#!/usr/bin/perl
#---------------------------------
# Copyright 2013 ByWater Solutions
#
#---------------------------------
#
# Joy Nelson
#
#---------------------------------
#
# EXPECTS:
#   -input CSV in this form: 
#    <tagfield>,<liblibrarian>,<repeatable>,<mandatory>
#
# DOES:
#   -updates the value described, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of records read

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Items;
$|=1;
my $debug = 0;
my $doo_eet = 0;
my $i=0;

my $infile_name = q{};
my $csv_delim            = 'comma';

GetOptions(
   'in:s'     => \$infile_name,
'delimiter=s'  => \$csv_delim,
   'debug'    => \$debug,
   'update'   => \$doo_eet,
);

if (($infile_name eq q{}) ){
   print "Something's missing.\n";
   exit;
}

my %delimiter = ( 'comma' => ',',
                  'tab'   => "\t",
                  'pipe'  => '|',
                );
my $written=0;
my $item_not_found=0;
my $csv=Text::CSV_XS->new({ binary => 1, sep_char => $delimiter{$csv_delim} });
my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("INSERT INTO auth_tag_structure (authtypecode, tagfield, liblibrarian, libopac,repeatable, mandatory) 
                        VALUES (?,?,?,?,?,?)");
open my $infl,"<",$infile_name;

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>1000);
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line; 

   if ($doo_eet){
   $sth->execute('',$data[0],$data[1],$data[1],$data[2],$data[3]);
   $written++;
   $sth->execute('CORPO_NAME',$data[0],$data[1],$data[1],$data[2],$data[3]);
   $written++;
   $sth->execute('GEOGR_NAME',$data[0],$data[1],$data[1],$data[2],$data[3]);
   $written++;
   $sth->execute('MEETI_NAME',$data[0],$data[1],$data[1],$data[2],$data[3]);
   $written++;
   $sth->execute('PERSO_NAME',$data[0],$data[1],$data[1],$data[2],$data[3]);
   $written++;
   }
}
close $infl;
print "\n\n$i records read.\n$written items updated.\n";

exit;

