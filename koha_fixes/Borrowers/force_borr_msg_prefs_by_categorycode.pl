#!/usr/bin/perl
# DO NOT USE TRUNCATE!!!!!
# Copyright (C) 2011 Tamil s.a.r.l.
# edited by Joy Nelson 2012
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;
BEGIN {
# find Koha's Perl modules
# test carefully before changing this
use FindBin;
eval { require "$FindBin::Bin/../kohalib.pl" };
}
 
use C4::Context;
use C4::Members::Messaging;
use Getopt::Long;
use Pod::Usage;
 
   
sub usage {
       pod2usage( -verbose => 2 );
       exit;
   }
   

   
sub force_borrower_messaging_defaults {
       my ($doit, $category) = @_;
   
       $category = '' if (!$category);
       print $category;
   
       my $dbh = C4::Context->dbh;
       $dbh->{AutoCommit} = 0;
   
       my $sth = $dbh->prepare("SELECT borrowernumber, categorycode FROM borrowers WHERE categorycode = ?");
       $sth->execute($category);
       while ( my ($borrowernumber, $categorycode) = $sth->fetchrow ) {
           print "$borrowernumber: $categorycode\n";
           next unless $doit;
           C4::Members::Messaging::SetMessagingPreferencesFromDefaults( {
               borrowernumber => $borrowernumber,
               categorycode   => $categorycode,
           } );
       }
       $dbh->commit();
   }
   
   
my ($doit, $category, $help);
my $result = GetOptions(
       'doit'     => \$doit,
       'categorycode:s' => \$category,
       'help|h'   => \$help,
);
   
usage() if $help;
   
force_borrower_messaging_defaults( $doit, $category );
  
=head1 NAME
   
force-borrower-messaging-defaults
   
=head1 SYNOPSIS
   
force-borrower-messaging-defaults 
force-borrower-messaging-defaults --help
force-borrower-messaging-defaults --doit
   
=head1 DESCRIPTION
   
If the EnhancedMessagingPreferences syspref is enabled after borrowers have
been created in the DB, those borrowers won't have messaging transport
preferences default values as defined for their borrower category. So you would
have to modify each borrower one by one if you would like to send them 'Hold
Filled' notice for example.
   
This script create transport preferences for all existing borrowers and set
them to default values defined for the category they belong to.
  
=over 8
 
=item B<--help>
  
Prints this help
  
=item B<--doit>
  
 
 
=back
  
=cut
  

