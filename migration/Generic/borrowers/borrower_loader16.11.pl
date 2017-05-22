#!/usr/bin/perl
#---------------------------------
# Copyright 2010 ByWater Solutions
#
#---------------------------------
#
# Draws heavily on Koha's tools/import_borrower.pl
#
# -D Ruth Bavousett
#
#---------------------------------

use strict;
use warnings;
use autodie;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use Koha::Libraries;
use Koha::Patron::Categories;
use Koha::Patrons;
use C4::Members;
use C4::Members::Attributes;
use C4::Members::Attributes qw /extended_attributes_code_value_arrayref/;
use C4::Members::AttributeTypes;
use Koha::DateUtils;
use Koha::Database;

my $debug=0;
my $doo_eet=0;
$|=1;

my $input_file="";
my $err_file="";

GetOptions(
    'in=s'          => \$input_file,
    'err=s'         => \$err_file,
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);

if (($input_file eq '') || ($err_file eq '')){
   print "Something's missing.\n";
   exit;
}

my $i=0;
my $attempted_write=0;
my $written=0;
my $other_problem=0;
my $broken_records=0;
my $duplicate_borrowers=0;
my $dbh=C4::Context->dbh();
my $csv=Text::CSV_XS->new({binary => 1});
my $today_iso = output_pref({ dt => dt_from_string(), dateformat => 'iso', dateonly => 1 });
my $extended = C4::Context->preference('ExtendedPatronAttributes');
my $set_messaging_prefs = C4::Context->preference('EnhancedMessagingPreferences');

my $schema = Koha::Database->new()->schema;
my @columnkeys = $schema->source('Borrower')->columns;
@columnkeys = grep { $_ ne 'borrowernumber' } @columnkeys;
@columnkeys = grep { $_ ne 'patron_attributes' } @columnkeys;

open my $in,"<$input_file";
open my $err,">$err_file";

my $headerline = $csv->getline($in);
my @csvcolumns = @$headerline;
my %csvkeycol;
my $col=0;
foreach my $keycol (@csvcolumns){
   $keycol =~ s/ +//g;
   $csvkeycol{$keycol} = $col++;
}
if ($extended) {
    push @columnkeys, 'patron_attributes';
}

RECORD:
while (my $line=$csv->getline($in)){
   $debug and last if ($i > 10);
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my %borrower;
   my $patron_attributes;
   my $bad_record = 0;
   my $message = '';
   my @columns = @$line; 
   foreach my $key (@columnkeys){
      $debug and print "KEY $key\n";
      if (defined($csvkeycol{$key}) and $columns[$csvkeycol{$key}] =~ /\S/){
         $borrower{$key} = $columns[$csvkeycol{$key}];
      }
      else {
         $borrower{$key} = '';
      }
   }

   if ($borrower{categorycode}){
      if (!Koha::Patron::Categories->find($borrower{categorycode})){
         $bad_record = 1;
         $message .= "/Borrower category unknown";
      }
   }
   else {
      $bad_record = 1;
      $message .= "/Borrower category missing";
   }
   if ($borrower{branchcode}){
       if (!Koha::Libraries->find($borrower{branchcode})) {
         $bad_record = 1;
         $message .= "/Borrower branch unknown";
      }
   }
   else {
      $bad_record = 1;
      $message .= "/Borrower branch missing";
   }
   if (!$borrower{surname}){
      $bad_record = 1;
      $message .= "/Surname undefined";
   }
   if ($bad_record){
      print $err "PROBLEM RECORD #".$i.":\n".$message."\n";
      print $err Dumper(%borrower);
      $broken_records++;
      next RECORD;
   }
   if ($extended) {
      my $attr_str = $borrower{patron_attributes};
      delete $borrower{patron_attributes}; 
      $patron_attributes = extended_attributes_code_value_arrayref($attr_str);
   }
   $borrower{dateenrolled} = $today_iso unless $borrower{dateenrolled};
   $borrower{dateexpiry} ||= Koha::Patron::Categories->find( $borrower{categorycode} )->get_expiry_date( $borrower{dateenrolled} );

   my $borrowernumber;

   $debug and print "WRITTEN: $borrower{cardnumber}\n";
   $attempted_write++;

#   my $member = GetMember( 'cardnumber' => $borrower{'cardnumber'});
#   my $member = Koha::Patrons->search( { cardumber => $borrower{cardnumber} } ) ;


#   if ($member ){
    if ( C4::Members::checkcardnumber( $borrower{cardnumber} ) ) {
      print $err "DUPLICATE CARDNUMBER--RECORD #".$i.":\n";
      print $err Dumper(\%borrower);
      $duplicate_borrowers++;
      next RECORD;
   }
   
   if ($doo_eet){
      eval { $borrowernumber = AddMember(%borrower); };
      if ( $borrowernumber ) {
         if ($extended) {
            C4::Members::Attributes::SetBorrowerAttributes($borrowernumber, $patron_attributes);
         }
         if ($set_messaging_prefs) {
            C4::Members::Messaging::SetMessagingPreferencesFromDefaults({ borrowernumber => $borrowernumber,
                                                                          categorycode => $borrower{categorycode} });
         }
         $written++;
      } else {
         print $err "ERROR WITH ADDMEMBER--RECORD #".$i.":\n";
         print $err Dumper(%borrower);
         $other_problem++;
      }
   }
}
close $in;
close $err;
print "\n\n$i borrowers found.\n";
print "$attempted_write borrowers potentially written.\n$written new borrowers written.\n";
print "$duplicate_borrowers borrowers not written due to duplicate cardnumber.\n";
print "$broken_records invalid records found.\n";
print "$other_problem records could not be added by AddMember.\n";
