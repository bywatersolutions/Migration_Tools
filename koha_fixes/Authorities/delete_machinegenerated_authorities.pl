#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
# Comments:
#  This script deletes authority records that are machine generated.
#  It looks for machine generated authority records
#    in the authority records that correspond to the tag entered
#  perl delete_authority.pl --tag=100 --update
#  this example will delete 100 (personal name) authority records that are machine generated.
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use C4::Context;
use C4::AuthoritiesMarc;
use MARC::Record;
use MARC::Field;

$|=1;
my $debug=0;
my $doo_eet=0;
my $i=0;

my $tagfield="1..";
my $normalize="case";
my $best="longest";

GetOptions(
    'tag=s'         => \$tagfield,
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);

my $field_not_present=0;
my $inserted=0;

my $dbh=C4::Context->dbh();

my $sth=$dbh->prepare("SELECT authid FROM auth_header");
my $marc_sth=$dbh->prepare("SELECT marc FROM auth_header WHERE authid=?");
$sth->execute();

RECORD:
while (my $row=$sth->fetchrow_hashref()){
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   $marc_sth->execute($row->{authid});
   my $rec = $marc_sth->fetchrow_hashref();
   my $marc = MARC::Record->new_from_usmarc($rec->{marc});
   my $field;
   my $field_whole = $marc->field($tagfield);

   if (!$field_whole) {
      $field_not_present++;
      next RECORD;
   }

   $field=$field_whole->as_string();
print "$row->{authid} and $field\n";

   if ($field ne "Machine generated authority record."){
      $field_not_present++;
print "skipping\n";
      next RECORD;
   }
   
   
   if (($field eq "Machine generated authority record.") && $doo_eet){
print "deleting\n";
         DelAuthority($row->{authid});
   }
}

