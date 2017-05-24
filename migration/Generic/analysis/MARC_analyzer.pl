#!/usr/bin/perl
#---------------------------------
# Copyright 2017 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#
#---------------------------------
#
# EXPECTS:
#   -file of MARC records
#
# DOES:
#
# CREATES:
#
# REPORTS:
#   -reports subfields and count of values in subfields for a specified itemtag
#
# Notes:

use autodie;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Readonly;
use Text::CSV_XS;
use Business::ISBN;
use Scalar::Util qw(looks_like_number);
use MARC::File::USMARC;
use MARC::File::XML;
use MARC::Record;
use MARC::Batch;
use MARC::Charset;
use Date::Calc qw(Add_Delta_Days);

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};

my $debug   = 0;
my $i       = 0;
my $problem = 0;

my $input_marc_filename  = $NULL_STRING;
my $charset              = 'marc8';
my $itemtag;
my $tags_found;
my %tagsubcount = ();
my @exclude;

GetOptions(
    'in=s'         => \$input_marc_filename,
    'itemtag=s'    => \$itemtag,
    'exclude=s'    => \@exclude,
    'debug'        => \$debug,
);


for my $var ($input_marc_filename) {
   croak ("You're missing something") if $var eq $NULL_STRING;
}


my %tally = ();

my $input_file = IO::File->new($input_marc_filename);
my $batch      = MARC::Batch->new('USMARC',$input_file);
$batch->warnings_off();
$batch->strict_off();
#my $iggy    = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding($charset);

print "Processing bibliographic records:\n";

RECORD:
while() {
   last RECORD if ($debug && $i>50);
   my $record;
   eval {$record = $batch->next();};
   if ($@) {
      print "$i Bogus record skipped.\n";
      $problem++;
      next RECORD;
   }
   last RECORD unless ($record);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);

#pull tag from marc and spin through 
   foreach my $tag ($record->field($itemtag)) {
      $tags_found++;

#count the number of times a subfield is used.
      foreach my $sub ($tag->subfields()) {
         my ($code,$val) = @$sub;
         $tagsubcount{$code}++;
      }

#tally up the values in this 2-D hash
       foreach my $kee (sort keys %tagsubcount) {
         if ($tag->subfield($kee)) {
            $tally{$kee}{$tag->subfield($kee)}++;
         }
      }
   }
}

close $input_file;


print << "END_REPORT";

$i records read.
$problem records not loaded due to problems.
$tags_found itemtags found.

END_REPORT

print "\nSubfield count:\n\n";
foreach my $kee (sort keys %tagsubcount) {
   print "$kee:  $tagsubcount{$kee}\n";
}

print "\nTally results:\n\n";

REPORT:
foreach my $sub (sort keys %tally) {
   if ( grep { $_ eq $sub } @exclude) {
    next REPORT;
   }
   print "\nSubfield $sub:\n";
   foreach my $kee (sort keys %{ $tally{$sub} }) {
      print $kee.':  '.$tally{$sub}{$kee}."\n";
   }
}

exit;

