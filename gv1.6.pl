#!/usr/bin/perl
#
# This program will find alll the global variables used in the HR, HC and cs jobs.
#

use 5.010;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Data::Dumper;

# Variable Table

my $workingfile_name;
my @workingfile;
my $line;
my @adj_file;
my $first_part;
my $second_part;
my $jt_field_val;
my @all_jn;
my $jobname;
my $jn;
my $end_of_line;
my $conditions;
my @all_conditions;
my $cond_line;
my $cond; 
my %all_gv;
my @all_gv_items;
my @list_gv;
my %list_gv2job;
my %as_gv;
my $gvs;
my $one;
my $cnt;
my $gv;

# define input jil file

 $workingfile_name = shift @ARGV;


open FILE, "$workingfile_name" or die "Problem accessing the $workingfile_name, specifically $!\n";
@workingfile = <FILE>;
close(FILE);

# build hash of global variables by jobname keys $jn

# Requirements for JIL file
# 1) Only insert_job: and <jobname> on the this line
# 2) The condition: line can not have spaces between the global variable and the equal sign and the value. 



foreach $line (@workingfile) {    
      if ($line =~ /insert_job\:/) { # get job name $jn
            ( $first_part, $second_part ) = split /\:/, $line;
             $second_part =~ s/^\s+//;    # strips leading spaces
             $jn = $second_part; 
               chomp($jn);       
        }
        if ($line =~ /condition\:/) {  # gets condition line  
            
           ($first_part, $conditions) = split(/\:/, $line);

           $conditions =~ s/^\s*// ;  # strips leading spaces 
            
           @all_conditions = undef if (scalar @all_conditions); #declares temp var for conditions values

           @all_conditions = split(/\&/, $conditions);
            # print "Job Name $jn\n"; 
            # print "ALL CONDITONS\n";
            # print "@all_conditions\n";

           my @all_gv_items = undef if (scalar @all_gv_items);

           @all_gv_items = grep { /\bv\((.*?)\b/ } @all_conditions; #finds all gv's in line
           # print "Job Name \n $jn\n";
           # print "ALL_GV_ITEMS @all_gv_items\n";
           $gvs = join (" ", @all_gv_items) if (scalar @all_gv_items); #convert to string for easy of processing
           $all_gv{$jn} = $gvs if defined $gvs; 
         }     
}              

    
# output file for verification of data structure
open OUT, ">gv_report0624.txt" or die "File was not able to be created: $!"; 

#print OUT Dumper (%all_gv);


# Translate routine from key/value pairs ($jobname/@all_gv_line) in %all_gv hash 
#  to a global variable/job name ($gv/@jobs) into the hash %list_gv2job  


@list_gv = values %all_gv;


my @total_gv ; # total number of gv's 

foreach $line (@list_gv) {
  @all_gv_items = split /\s+/, $line;
  push @total_gv, @all_gv_items; 
}

# print stats and list GV's

print OUT "\n\nTotal Global Variables on WORKDEVAE\n\n";
print OUT scalar @total_gv, " \n\n";

# print "Hit \<ENTER\> to continue.\n";
# my $dummy = <STDIN>; 

my @uniq_gv = uniq(sort(@total_gv));

print OUT "\nUNIQUE GLOBAL VARIABLES\n\n";
foreach (@uniq_gv) {
  print OUT "$_\n" ;
} 

print OUT "\nThe total number of UNIQUE global variables.\n\n";
print OUT scalar @uniq_gv, "\n\n" ;

# print "Hit \<ENTER\> to continue.\n";
# $dummy = <STDIN>; 

printf OUT "  %20s %18s\n\n", "Global Variable", "Job Name";

my @output_index;
my @uniq_gv_output; 

foreach $gv (@uniq_gv) {
     foreach $jn (keys %all_gv){
          #print "ALL GV $all_gv{$jn}\n";
          #print "GV  $gv\n";
          if (index($all_gv{$jn}, $gv) != -1) {
              printf OUT "  %5s %25s \n", $gv, $jn; 
              $line = "$gv      $jn";
              push @output_index, $line ;
              } 
     }
}


 
close(OUT);

# print Dumper(\%all_gv);

exit;

