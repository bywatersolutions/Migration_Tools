#!/usr/bin/perl
#---------------------------------
# Copyright 2010 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
# barprefix is for borrowers barcode
# alternate runtime option allows for use of alternate borrowernumber.  (i.e. for historical circ loading)
#
#---------------------------------

use autodie;
use Data::Dumper;
use Getopt::Long;
use Modern::Perl;
use Text::CSV;
use C4::Context;
$|=1;

my $infile_name = "";
my $table_name = "";
my $borrowercol = "XXX";
my $itemcol = "YYY";
my $alternate = undef;
my $csv_delim = 'comma';
my $debug=0;
my $doo_eet=0;
my @datamap_filenames;
my %datamap;
my $counter=0;

GetOptions(
    'in=s'     => \$infile_name,
    'table=s'  => \$table_name,
    'borr=s'   => \$borrowercol,
    'alt=s'    => \$alternate,
    'item=s'   => \$itemcol,
    'map=s'        => \@datamap_filenames,
    'delimiter=s'  => \$csv_delim,
    'counter=s'=> \$counter,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my %DELIMITER = ( 'comma' => q{,},
                  'tab'   => "\t",
                  'pipe'  => q{|},
                );

if (($infile_name eq '') || ($table_name eq '')){
   print "Something's missing.\n";
   exit;
}

foreach my $map (@datamap_filenames) {
   my ($mapsub,$map_filename) = split (/:/,$map);
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$map_filename;
$debug and print "$map_filename\n";
   while (my $row = $csv->getline($mapfile)) {
      my @data = @$row;
      $datamap{$mapsub}{$data[0]} = $data[1];
#$debug and print "$data[0] and $data[1]\n";
  }
   close $mapfile;
}

my $csv=Text::CSV->new({ binary => 1, sep_char => $DELIMITER{$csv_delim} });
my $dbh=C4::Context->dbh();
my $j=$counter;
my $exceptcount=0;
open my $io,"<$infile_name";
my $headerline = $csv->getline($io);
my @fields=@$headerline;
$debug and print Dumper(@fields);
while (my $line=$csv->getline($io)){
   $debug and last if ($j>433323); 
   $j++;
   print ".";
   print "\r$j" unless ($j % 100);
   my @data = @$line;
   $debug and print Dumper(@data);
   my $querystr = "INSERT INTO $table_name (issue_id,";
   my $exception = 0;
   for (my $i=0;$i<scalar(@data);$i++){
      next if ($fields[$i] eq "" || $data[$i] eq "");
      if ($fields[$i] eq "ignore"){
         next;
      }
      if ($fields[$i] eq $borrowercol){
         $querystr .= "borrowernumber,";
         next;
      }
      if ($fields[$i] eq $itemcol){
         $querystr .= "itemnumber,";
         next;
      }
      if (($data[$i] ne "") && ($fields[$i] ne "suppress")){
         $querystr .= $fields[$i].",";
      }
   }
   $querystr =~ s/,$//;
   $querystr .= ") VALUES ($j,";
   for (my $i=0;$i<scalar(@fields);$i++){
      if ($fields[$i] eq "ignore" || $data[$i] eq ""){
         next;
      }
      if ($fields[$i] eq "branchcode") {
         $data[$i] = uc $data[$i];
      }
      my $oldval = $data[$i];
      if ($datamap{$fields[$i]}{$oldval}) {
         $debug and say "MAPPED: $oldval  TO $datamap{$fields[$i]}{$oldval}";
         $data[$i] = $datamap{$fields[$i]}{$oldval};
      }
      if ($fields[$i] eq $borrowercol){
$debug and print "cardnumber is: $data[$i]\n";

         my $convertq = $dbh->prepare("SELECT borrowernumber FROM borrowers WHERE cardnumber = '$data[$i]';");
         $convertq->execute();
         my $rec=$convertq->fetchrow_hashref();
         my $borr=$rec->{'borrowernumber'} || $alternate;
$debug and print "borrowernumber is: $data[$i]\n";
         if ($borr){
            $data[$i]= $borr;
         }
         elsif ($data[$i] ne 'NULL' && $data[$i] ne ''){
$debug and print "$data[$i] is $data[$i]\n";
            $exception = "No Borrower";
         }
      } 

      if ($fields[$i] eq $itemcol){
$debug and print "item barcode is: $data[$i]\n";

         if ($data[$i]){
            my $convertq = $dbh->prepare("SELECT itemnumber FROM items WHERE barcode = '$data[$i]';");
            $convertq->execute();
            my $rec=$convertq->fetchrow_hashref();
            if ($rec->{'itemnumber'}){
               $data[$i] = $rec->{'itemnumber'};
$debug and print "itemnumber is: $data[$i]\n";
            }
            elsif ($data[$i] ne 'NULL' && $data[$i] ne '') {
               $exception = "No Item";
            }
         }
         else{
            $querystr .= "NULL,";
         }
      } 
      if ($fields[$i] =~ /date/){
         if (length($data[$i]) == 8){
           $data[$i] =~ s/(\d{4})(\d{2})(\d{2})/$1-$2-$3/;
         }
      }
      if (($data[$i] ne "") && ($fields[$i] ne "suppress")){
         $data[$i] =~ s/\"/\\"/g;
         $querystr .= '"'.$data[$i].'",';
      }
   }
   $querystr =~ s/,$//;
   $querystr .= ");";
   $debug and print $querystr."\n";
   if (!$exception){
      my $sth = $dbh->prepare($querystr);
      if ($doo_eet){
        $sth->execute();
#print "\n\n$querystr\n\n";
      }
   }
   else {
      $exceptcount++;
      print "\nEXCEPTION:  $exception\n";
      for (my $i=0;$i<scalar(@fields);$i++){
         print $fields[$i].":  ".$data[$i]."\n";
      }
      print "--------------------------------------------\n";
   }
}
print "\n\n$j records processed.  $exceptcount exceptions.\n";
