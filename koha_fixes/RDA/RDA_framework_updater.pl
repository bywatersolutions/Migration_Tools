#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#
#---------------------------------

use autodie;
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use C4::Context;
$|=1;

my $debug=0;
my $doo_eet=0;
my $framework_in;
my @frameworks;

GetOptions(
    'framework=s' => \$framework_in,
    'debug'       => \$debug,
    'update'      => \$doo_eet,
);

@frameworks = split(/,/, $framework_in);

my $dbh=C4::Context->dbh();
my $j=0;
my $sth1=$dbh->prepare("insert into marc_tag_structure (tagfield, liblibrarian, libopac, repeatable, mandatory, frameworkcode) values 
         (264, 'PRODUCTION, PUBLICATION, DISTRIBUTION, MANUFACTURE STATEMENTS', 'PRODUCTION, PUBLICATION, DISTRIBUTION, MANUFACTURE STATEMENTS', 0,0,?),
         (336, 'CONTENT TYPE', 'CONTENT TYPE', 1,0,?),
         (337, 'MEDIA TYPE', 'MEDIA TYPE', 1,0,?),
         (338, 'CARRIER TYPE', 'CARRIER TYPE', 1,0,?),
         (344,'SOUND CHARACTERISTICS','SOUND CHARACTERISTICS',1,0,?),
         (345,'PROJECTION CHARACTERISTICS OF MOVING IMAGE','Project Characteristics of Moving Image',1,0,?),
         (346,'VIDEO CHARACTERISTICS','VIDEO CHARACTERISTICS',1,0,?),
         (347,'DIGITAL FILE CHARACTERISTICS','DIGITAL FILE CHARACTERISTICS',1,0,?),
         (377,'ASSOCIATED LANGUAGE','ASSOCIATED LANGUAGE',1,0,?),
         (380,'FORM OF WORK','FORM OF WORK',1,0,?),
         (381,'OTHER DISTINGUISHING CHARACTERISTICS OF WORK OR EXPRESSION','OTHER DISTINGUISHING CHARACTERISTICS OF WORK OR EXPRESSION',1,0,?),
         (382,'MEDIUM OF PERFORMANCE','MEDIUM OF PERFORMANCE',1,0,?),
         (383,'NUMERIC DESIGNATION OF MUSICAL WORK','NUMERIC DESIGNATION OF MUSICAL WORK',1,0,?),
         (384,'KEY','KEY',0,0,?)");
my $sth2=$dbh->prepare(" insert into marc_subfield_structure (tagfield, tagsubfield, liblibrarian, libopac, repeatable, mandatory, tab, isurl, hidden, frameworkcode) values 
         (264, 'a','Place of production, publication, distribution, manufacture', 'Place of production, publication, distribution, manufacture', 1,0,2,0,0,?), 
	(264, 'b','Name of producer, publisher, distributor, manufacturer', 'Name of producer, publisher, distributor, manufacturer', 1,0,2,0,0,?), 
	(264, 'c','Date of production, publication, distribution, manufacture', 'Date of production, publication, distribution, manufacture', 1,0,2,0,0,?), 
	(264, '3','Materials Specified', 'Materials Specified', 0,0,2,0,0,?), 
	(264, '6','Linkage', 'Linkage', 0,0,2,0,0,?), 
	(264, '8','Field link and sequence number', 'Field link and sequence number', 1,0,2,0,0,?),
	(336, 'a','Content Type Term', 'Content Type Term', 1,0,3,0,0,?), 
	(336, 'b','Content Type Code', 'Content Type Code', 1,0,3,0,0,?),
	(336, '2','Source', 'Source', 0,0,3,0,0,?), 
	(336, '3','Materials Specified', 'Materials Specified', 1,0,3,0,0,?), 
	(336, '6','Linkage', 'Linkage', 1,0,3,0,0,?), 
	(336, '8','Field link and sequence number', 'Field link and sequence number', 1,0,3,0,0,?), 
	(337, 'a','Media Type Term', 'Media Type Term', 1,0,3,0,0,?), 
	(337, 'b','Media Type Code', 'Media Type Code', 1,0,3,0,0,?), 
	(337, '2','Source', 'Source', 0,0,3,0,0,?), 
	(337, '3','Materials Specified', 'Materials Specified', 1,0,3,0,0,?), 
	(337, '6','Linkage', 'Linkage', 1,0,3,0,0,?), 
	(337, '8','Field link and sequence number', 'Field link and sequence number', 1,0,3,0,0,?), 
	(338, 'a','Carrier Type Term', 'Carrier Type Term', 1,0,3,0,0,?), 
	(338, 'b','Carrier Type Code', 'Carrier Type Code', 1,0,3,0,0,?), 
	(338, '2','Source', 'Source', 0,0,3,0,0,?), 
	(338, '3','Materials Specified', 'Materials Specified', 1,0,3,0,0,?), 
	(338, '6','Linkage', 'Linkage', 1,0,3,0,0,?), 
	(338, '8','Field link and sequence number', 'Field link and sequence number', 1,0,3,0,0,?),
        ('046','o','Single or starting date for aggregated content','Single or starting date for aggregated content',1,0,0,0,0,?),
        ('046','p','Ending date for aggregated content','Ending date for aggregated content',1,0,0,0,0,?),
        (344,'a','Type of recording','Type of recording',1,0,3,0,0,?),
        (344,'b','Recording medium','Recording medium',1,0,3,0,0,?),
        (344,'c','Playing speed','Playing speed',1,0,3,0,0,?),
        (344,'d','Groove characteristic','Groove characteristic',1,0,3,0,0,?),
        (344,'e','Track configuration','Track configuration',1,0,3,0,0,?),
        (344,'f','Tape configuration','Tape configuration',1,0,3,0,0,?),
        (344,'g','Configuration of playback channels','Configuration of playback channels',1,0,3,0,0,?),
        (344,'h','Special playback characteristics','Special playback characteristics',1,0,3,0,0,?),
        (344,'0','Authority record control number or standard number','Authority record control number or standard number',1,0,3,0,0,?),
        (344,'2','Source','Source',0,0,3,0,0,?),
        (344,'3','Material specified','Material specified',0,0,3,0,0,?),
        (345,'a','Presentation format','Presentation format',1,0,3,0,0,?),
        (345,'b','Projection speed','Projection speed',1,0,3,0,0,?),
        (345,'0','Authority record control number or standard number','Authority record control number or standard number',1,0,3,0,0,?),
        (345,'2','Source','Source',0,0,3,0,0,?),
        (345,'3','Material specified','Material specified',0,0,3,0,0,?),
        (346,'a','Video format','Video format',1,0,3,0,0,?),
        (346,'b','Broadcast standard','Broadcast standard',1,0,3,0,0,?),
        (346,'0','Authority record control number or standard number','Authority record control number or standard number',1,0,3,0,0,?),
        (346,'2','Source','Source',0,0,3,0,0,?),
        (346,'3','Material specified','Material specified',0,0,3,0,0,?),
        (347,'a','File type','File type',1,0,3,0,0,?),
        (347,'b','Encoding format','Encoding format',1,0,3,0,0,?),
        (347,'c','File size','File size',1,0,3,0,0,?),
        (347,'d','Resolution','Resolution',1,0,3,0,0,?),
        (347,'e','Regional encoding','Regional encoding',1,0,3,0,0,?),
        (347,'f','Transmission speed','Transmission speed',1,0,3,0,0,?),
        (347,'0','Authority record control number or standard number','Authority record control number or standard number',1,0,3,0,0,?),
        (347,'2','Source','Source',0,0,3,0,0,?),
        (347,'3','Material specified','Material specified',0,0,3,0,0,?),
        (377,'a','Language code','Language code',1,0,3,0,0,?),
        (377,'1','Language term','Language term',1,0,3,0,0,?),
        (377,'2','Source','Source',0,0,3,0,0,?),
        (380,'a','Form of work','Form of work',1,0,3,0,0,?),
        (380,'0','Record control number','Record control number',1,0,3,0,0,?),
        (380,'2','Source of term','Source of term',0,0,3,0,0,?),
        (381,'a','Other distinguishing characteristic','Other distinguishing characteristic',1,0,3,0,0,?),
        (381,'u','Uniform Resource Identifier','Uniform Resource Identifier',1,0,3,0,0,?),
        (381,'v','Source of information','Source of information',1,0,3,0,0,?),
        (381,'0','Record control number','Record control number',1,0,3,0,0,?),
        (381,'2','Source of term','Source of term',0,0,3,0,0,?),
        (382,'a','Medium of performance','Medium of performance',1,0,3,0,0,?),
        (382,'b','Soloist','Soloist',1,0,3,0,0,?),
        (382,'d','Doubling instrument','Doubling instrument',1,0,3,0,0,?),
        (382,'n','Number of performers of the same medium','Number of performers of the same medium',1,0,3,0,0,?),
        (382,'p','Alternative medium of performance','Alternative medium of performance',1,0,3,0,0,?),
        (382,'s','Total number of performers','Total number of performers',1,0,3,0,0,?),
        (382,'v','Note','Note',1,0,3,0,0,?),
        (382,'0','Authority record control number or standard number ','Authority record control number or standard number',1,0,3,0,0,?),
        (382,'2','Source of term','Source of term',0,0,3,0,0,?),
        (383,'a','Serial number','Serial number',1,0,3,0,0,?),
        (383,'b','Opus number','Opus number',1,0,3,0,0,?),
        (383,'c','Thematic index number','Thematic index number',1,0,3,0,0,?),
        (383,'d','Thematic index code','Thematic index code',0,0,3,0,0,?),
        (383,'e','Publisher associated with opus number','Publisher associated with opus number',0,0,3,0,0,?),
        (383,'2','Source','Source',0,0,3,0,0,?),
        (384,'a','Key','Key',1,0,3,0,0,?),
        (700,'i','Relationship Information','Relationship Information',0,0,7,0,0,?)");
foreach my $framework (@frameworks) {
$debug and print "$framework\n";
   $debug and last if ($j>30); 
   $j++;
   print ".";
   print "\r$j" unless ($j % 100);
   if ($doo_eet) {
     $sth1->execute($framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework);
     $sth2->execute($framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework,$framework);
   }
}
print "\n\n$j records processed.  \n";
