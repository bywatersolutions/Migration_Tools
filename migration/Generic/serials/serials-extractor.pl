#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#a variation of MARC_field_extractor.pl(drnoe)
# a generic version of that (jweaver)
#---------------------------------
#
# EXPECTS:
#	-MARC file
#
# DOES:
#	-pulls data specified by runtime options
#
# CREATES:
#	-CSV with ???
#
# REPORTS:
#	-nothing

use autodie; 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use MARC::Field;
use MARC::File::USMARC;
use MARC::Record;
use MARC::Batch;
use MARC::Charset;
use Text::CSV_XS;

local $OUTPUT_AUTOFLUSH = 1;

my $debug	= 0;
my $prepend_captions = 0;
my $recordnum		= 0;

my $branch;
my $biblionumber;
my $input_filename  = "";
my $enum_output_filename = "";
my $hist_output_filename = "";
my $enumtag;
my $enumsubfields;
my $histtag;
my $histsubfields;
my @maps;

GetOptions(
	'in=s'		  => \$input_filename,
	'branch=s'	=> \$branch, 
	'biblionumber=s'	=> \$biblionumber, 
	'enum-out=s'  => \$enum_output_filename,
	'hist-out=s'  => \$hist_output_filename,
	'enum-tag=s' => \$enumtag,
	'enum-subfields=s' => \$enumsubfields,
	'hist-tag=s' => \$histtag,
	'hist-subfields=s' => \$histsubfields,
	'prepend-captions' => \$prepend_captions,
	'debug'		 => \$debug,
);

unless ($branch && $biblionumber && $input_filename && $hist_output_filename) {
  print "Something's missing.\n";
  exit;
}

my $written = 0;

my $in_fh  = IO::File->new($input_filename);
my $batch = MARC::Batch->new('USMARC',$in_fh);
$batch->warnings_off();
$batch->strict_off();
my $iggy	= MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('marc8');
open my $enum_out_fh,">:utf8",$enum_output_filename if ( $enum_output_filename );
open my $hist_out_fh,">:utf8",$hist_output_filename;

my $tagfieldre = qr/^(\d{3})([A-Za-z0-9])$/;

my $branchcode;
my ( $branchtag, $branchsubfield );

if ( $branch =~ /$tagfieldre/ ) {
	( $branchtag, $branchsubfield ) = ( $1, $2 );
} else {
	$branchcode = $branch;
}

die 'Invalid format of biblionumber' unless ( my ( $biblionumbertag, $biblionumbersubfield ) = ( $biblionumber =~ /$tagfieldre/ ) );

my $csv = Text::CSV_XS->new( { binary => 1 } );

my @enumsubfields;
my @enumcolumns;

if ( $enumtag ) {
	die 'Invalid format of enum-tag' unless ( $enumtag =~ /[0-9]{3}/ );

	my @subfield_descriptors = split /,/, $enumsubfields;

	foreach my $desc ( @subfield_descriptors ) {
		die 'Invalid format of enum subfield' unless ( my ( $subfield, $column ) = ( $desc =~ /^([A-Za-z0-9]+):(.*)$/ ) );

		die 'Only numberpattern enum-column can use multiple subfields' if ( $column ne 'numberpattern' && length( $subfield ) > 1 );
		push @enumsubfields, $subfield;
		push @enumcolumns, $column;
	 }

	 $csv->print( $enum_out_fh, [ 'biblionumber', 'branchcode', @enumcolumns ] );
	 print {$enum_out_fh} "\n";
}

die 'Invalid format of hist-tag' unless ( $histtag =~ /[0-9]{3}/ );

my @subfield_descriptors = split /,/, $histsubfields;
my @histsubfields;
my @histcolumns;

foreach my $desc ( @subfield_descriptors ) {
	die 'Invalid format of hist subfield' unless ( my ( $subfield, $column ) = ($desc =~ /^([A-Za-z0-9]+):(.*)$/ ) );

	# recievedlist is the right spelling according to the DB
	die 'Only recievedlist hist-column can use multiple subfields' if ( $column ne 'recievedlist' && length( $subfield ) > 1 );
	push @histsubfields, $subfield;
	push @histcolumns, $column;
}

$csv->print( $hist_out_fh, [ 'biblionumber', 'branchcode', @enumcolumns ] );
print {$hist_out_fh} "\n";

RECORD:
while () {
	last RECORD if ($debug and $recordnum > 99);
	my $this_record;
	eval{ $this_record = $batch->next(); };
	if ($EVAL_ERROR){
	  print "Bogusness skipped\n";
	  next RECORD;
	}
	last RECORD unless ($this_record);
	$recordnum++;
	print '.'	unless $recordnum % 10;;
	print "\r$recordnum" unless $recordnum % 100;

FIELD:
	my $biblionumber;
	my $field = $this_record->field($biblionumbertag);
	if ( !$field || !($biblionumber = $field->subfield($biblionumbersubfield)) ) {
		print "Missing biblionumber, skipped\n";
		next RECORD;
	}
	
	if ( $branchtag ) {
		my $branchfield = $this_record->field($branchtag);
		if ( !$branchfield || !($branchcode = $field->subfield($branchsubfield)) ) {
			print "Missing branch, skipped\n";
			next RECORD;
		}
	}

	my %enumlinks;

	if ( $enumtag ) {
		foreach my $field ($this_record->field($enumtag)) {
			$enumlinks{$field->subfield('8')} = $field if ( $field->subfield('8') );

			my @coldata;
			foreach my $i ( 0..(scalar @enumsubfields - 1) ) {
				if ( $enumcolumns[$i] eq 'numberpattern' ) {
					my @values;
					my @placeholders = 'X'..'Z';
					my @used_subfields = split //, $enumsubfields[$i];

					foreach my $subfieldnum ( 0..( scalar @used_subfields - 1 ) ) {
						push @values, $field->subfield( $used_subfields[$subfieldnum] ) . ' {' . $placeholders[$subfieldnum] . '}' if ( $field->subfield( $used_subfields[$subfieldnum] ) );
					}

					push @coldata, join ', ', @values;
				} else {
					push @coldata, scalar $field->subfield( $enumsubfields[$i] );
				}
			}

			$csv->print( $enum_out_fh, [ $biblionumber, $branchcode, @coldata ] );
			print {$enum_out_fh} "\n";
		}
	}

	foreach my $field ($this_record->field($histtag)) {
		my @coldata;

		foreach my $i ( 0..(scalar @histsubfields - 1) ) {
			if ( $histcolumns[$i] eq 'recievedlist' ) {
				my @values;

				my ( $enumlink, $enumseq ) = ( $field->subfield('8') =~ /(\d+)\.(\d+)/ );

				if ( $prepend_captions && $enumlink && $enumlinks{$enumlink} ) {
					my $enum = $enumlinks{$enumlink};
					foreach my $used_subfield ( split //, $histsubfields[$i] ) {
						push @values, ( $enum->subfield( $used_subfield ) // '' ) . ' ' . $field->subfield( $used_subfield ) if ( $field->subfield( $used_subfield ) );
					}
				} else {
					foreach my $used_subfield ( split //, $histsubfields[$i] ) {
						push @values, $field->subfield( $used_subfield ) if ( $field->subfield( $used_subfield ) );
					}
				}

				push @coldata, join ', ', @values;
			} else {
				push @coldata, scalar $field->subfield( $histsubfields[$i] );
			}
		}
		$csv->print( $hist_out_fh, [ $biblionumber, $branchcode, @coldata ] );
		print {$hist_out_fh} "\n";
		$written++;
	}
}

close $hist_out_fh;
close $enum_out_fh if ( $enum_out_fh );
close $in_fh;

print << "END_REPORT";


$recordnum records read.
$written records written.
END_REPORT

exit
