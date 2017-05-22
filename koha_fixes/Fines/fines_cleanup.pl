#!/usr/bin/perl
#---------------------------------
# Copyright 2013 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# 
# Modification log: (initial and date)
#
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -tidies up fine displays!
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -number of patrons modified

use autodie;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Modern::Perl;
use Readonly;
use Text::CSV_XS;
use C4::Context;
use C4::Accounts;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};
my $start_time             =  time();

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $written = 0;
my $problem = 0;

GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $dbh = C4::Context->dbh();
my $patron_sth = $dbh->prepare("SELECT DISTINCT borrowernumber FROM accountlines ORDER BY borrowernumber");
my $fines_sth  = $dbh->prepare("SELECT * from accountlines WHERE borrowernumber = ? AND accounttype != 'FU' ORDER BY date");
my $delete_sth = $dbh->prepare("DELETE FROM accountlines WHERE borrowernumber = ? AND accounttype != 'FU'");
my $fine_records_read = 0;
my $manual_credits    = 0;
my $patrons_cleared   = 0;

$patron_sth->execute();
my $stopper=0;

PATRON:
while (my $patron=$patron_sth->fetchrow_hashref()) {
   last PATRON if $debug and ($stopper);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);

   my $this_patron = $patron->{borrowernumber};
   $fines_sth->execute($this_patron);
   my $fines = $fines_sth->fetchall_hashref('accountno');

$stopper=1 if $this_patron==9404;
   $debug and say "------------------------------------";
   $debug and say "Borrower $this_patron";

   my $total_charges = 0;
   my $total_credits = 0;
  
COUNTUP: 
   foreach my $kee (sort {$a <=> $b} keys %$fines) {
      $fine_records_read++;
      $debug and say "$kee: $fines->{$kee}->{date}  $fines->{$kee}->{accounttype} $fines->{$kee}->{amount}";
      my $input = sprintf "%.2f",$fines->{$kee}->{amount};
      my $this_amount = sprintf "%d",($input*100);
      if ($fines->{$kee}->{accounttype} eq 'FU') {
         delete $fines->{$kee};
         next COUNTUP;
      }
      if ($fines->{$kee}->{accounttype} eq 'W') {
         $total_credits += abs( $this_amount);
     $debug and say "Running: $total_credits";
         delete $fines->{$kee};
         next COUNTUP;
      }
      if ($fines->{$kee}->{accounttype} eq 'LR') {
         $total_credits -= $this_amount;
         delete $fines->{$kee};
         next COUNTUP;
      }
      if ($fines->{$kee}->{amount} > 0) {
         $total_charges += int $this_amount;
      }
      else {
     $debug and say "THIS: $this_amount";
         $total_credits += int abs ($this_amount);
     $debug and say "Running: $total_credits";
         delete $fines->{$kee};
      }
   }
   $debug and say "Total charges $total_charges/100!";
   $debug and say "Total credits $total_credits/100!";

   if ($total_charges == $total_credits){
      $debug and say "No fines to write!";
      if ($doo_eet) {
         $delete_sth->execute($this_patron);
      }
      foreach my $kee (sort {$a <=> $b} keys %$fines) {
         if ($fines->{$kee}->{accounttype} ne 'L') {
            delete $fines->{$kee};
         }
         else { 
            $fines->{$kee}->{amountoutstanding}=0;
         }
      }  
      $patrons_cleared++;
   }

   if ($total_credits > $total_charges) {
      $total_credits -= $total_charges;
      $total_credits /= 100;
      $total_credits *= -1;
      $debug and say "Manual credit of $total_credits!";
      if ($doo_eet) {
         $delete_sth->execute($this_patron);
         manualinvoice($this_patron,undef,'Manual credit','C',$total_credits,'Credit leftover from fines cleanup March 2013');
      }
      foreach my $kee (sort {$a <=> $b}  keys %$fines) {
         if ($fines->{$kee}->{accounttype} ne 'L') {
            delete $fines->{$kee};
         }
         else { 
            $fines->{$kee}->{amountoutstanding}=0;
         }
      }
      $manual_credits++;
      next PATRON;
   }

   if ($total_credits < $total_charges) {
      my $money_to_spend = $total_credits;
SPENDDOWN:
      foreach my $kee (sort {$a <=> $b} keys %$fines) {
         
         my $this_one = int $fines->{$kee}->{amount}*100;
         if (!$money_to_spend) {
            $fines->{$kee}->{amountoutstanding} = $this_one/100;
            next SPENDDOWN;
         }
         $debug and say "Key: $kee This: $this_one Spend: $money_to_spend";
         if ($money_to_spend < $this_one) {
   $debug and say "LESS";
            $this_one -= $money_to_spend;
            $fines->{$kee}->{amountoutstanding} = $this_one/100;
            $money_to_spend = 0;
            next SPENDDOWN;
         }
         $money_to_spend -= int ($fines->{$kee}->{amount} *100);
         if ($fines->{$kee}->{accounttype} ne 'L') {
            delete $fines->{$kee};
         }
         else {
            $fines->{$kee}->{amountoutstanding} = 0;
         }
      }
      if ($doo_eet) {
         $delete_sth->execute($this_patron);
      }
   }
   $debug and $stopper and print "STOPPER FOUND\n";
   $debug and print Dumper(%$fines);

CHARGE:
   foreach my $kee (sort {$a <=> $b} keys %$fines) {
      my $this_amount = int ($fines->{$kee}->{amount} * 100);
      my $outstanding = int ($fines->{$kee}->{amountoutstanding} * 100);
      if ($doo_eet){
        _invoice_them($this_patron,
                      $fines->{$kee}->{itemnumber},
                      $fines->{$kee}->{description},
                      $fines->{$kee}->{accounttype},
                      $fines->{$kee}->{date},
                      $fines->{$kee}->{note},
                      $fines->{$kee}->{timestamp},$this_amount/100,$outstanding/100);
      }
   }
   $written++;
}

print << "END_REPORT";

$i borrowers read.
$fine_records_read fine records examined.
$patrons_cleared borrowers had zero balances, so all records were dropped.
$manual_credits borrowers had credit balances applied as manual credits.
$written records written.
$problem records not modified due to problems.
END_REPORT

my $end_time = time();
my $time     = $end_time - $start_time;
my $minutes  = int($time / 60);
my $seconds  = $time - ($minutes * 60);
my $hours    = int($minutes / 60);
$minutes    -= ($hours * 60);

printf "Finished in %dh:%dm:%ds.\n",$hours,$minutes,$seconds;

exit;

sub _invoice_them {
    my ( $borrowernumber, $itemnum, $desc, $type, $date, $note, $timestamp, $amount, $outstanding ) = @_;
    my $dbh      = C4::Context->dbh;
    my $notifyid = 0;
    my $insert;
    if ($itemnum) {
       $itemnum =~ s/ //g;
    }
    my $accountno  = getnextacctno($borrowernumber);
    if (   ( $type eq 'L' )
        or ( $type eq 'F' )
        or ( $type eq 'A' )
        or ( $type eq 'N' )
        or ( $type eq 'M' ) )
    {
        $notifyid = 1;
    }

    if ( $itemnum  ) {
        my $sth = $dbh->prepare(
            "INSERT INTO  accountlines
                        (borrowernumber, accountno, date, amount, description, accounttype, amountoutstanding, 
                         itemnumber,notify_id,note,timestamp)
        VALUES (?, ?, ?, ?,?, ?,?,?,?,?,?)");
     $sth->execute($borrowernumber, $accountno, $date, $amount, $desc, $type, $outstanding, $itemnum,$notifyid, $note,$timestamp) || return $sth->errstr;
  } else {
    my $sth=$dbh->prepare("INSERT INTO  accountlines
            (borrowernumber, accountno, date, amount, description, accounttype, amountoutstanding,notify_id,note,timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?,?,?,?)"
        );
        $sth->execute( $borrowernumber, $accountno, $date, $amount, $desc, $type,
            $outstanding, $notifyid,$note,$timestamp );
    }
    return 0;
}

