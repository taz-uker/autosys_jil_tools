#!/usr/bin/perl

use 5.010;
use warnings;
use Data::Dumper;

#  This program will parse Autosys JIL into indendent JIL jobs
#  Second, it will then allow you to search for a matching string
# and give you the whole jil that matches that search string.
#
# written by Terry Pensel  04/2013

# Variable table

my $cnt = 0;             # counter of processing indicator
my $dummy;               # dummy variable to screen halting and display viewing.
my $end_of_line;         # stuff declared but not needed
my $first_part;          # split values for job name
my $input_file_jil;      # input source file for AS JIL.
my $input_file_jn;       # input file for processing job names or JIL.
my $input_fn;            # jil field name to search on
my $jn;                  # another job name
my $jobname;             # job name
my $jt_field_val;        # stuff declared but not needed
my $line;                # line of AS JIL
my $search_str;          # search string for field value
my $second_part;         # middle part that has job name
my $sjn;                 # job name from JIL source file
my $workingfile_name;    # working file name containing AS JIL
my %as_jil;              # resulting overall hash for sorting jil
my @adj_file;            # adj AS JIL file
my @all_jn;              # all jobnames from loaded AS JIL file
my @bad_jn;              # bad jil records in job name file
my @job_names =
  undef;            # array of job_names from input file of PLAIN OLD job names.
my @jobname;        # result of insert_job grep in DUAL sections
my @jobs_w_match;   # jobs that match the search_str
my @test;           # temp array for jil search results
my @total;          # holds total of search results
my @workingfile;    # working file contents containing AS JIL

# Start of Main Program

goto NEW_SEARCH unless defined $search_str;

MENU_START:

system("clear");

# Menu

say "\n\t\t\tAutosys JIL Extractor ";
say "\n\t\t\t\tcoded by Terry Pensel 04/2013\n";
say "\n";
say "\tThe SEARCH STRING was \"$search_str\" in the AS field \"$input_fn\".";
say "\nSelect an option below:\n";
say "\ta\) Generate file that lists the jobs names ONLY.";
say "\tb\) View lines that match the search string.";
say "\tc\) Generate JIL file of selected jobs.";
say "\td\) Enter new search criteria.";
say "\te\) View jobs names selected.";
say "\tf\) DUAL VIEW\: Job Names and selected lines.";
say "\tg\) DUAL PRINT\: Generate file of DUAL VIEW.";
say "\th\) Generate jil from a plain JOB list.";
say "\tq\) Exit";

print "\n---> ";    # prompt

my $option = <STDIN>;

given ($option) {
    when (/a/) { goto PRT_JOBS; }
    when (/b/) { goto VIEW_LINES; }
    when (/c/) { goto OUTPUT_JIL_FILE_OPTION; }
    when (/d/) { goto NEW_SEARCH; }
    when (/e/) { goto VIEW_JOBS; }
    when (/f/) { goto DUAL_VIEW; }
    when (/g/) { goto DUAL_PRINT; }
    when (/h/) { goto JOBLIST_2_JIL; }
    when (/q/) { exit; }
    default {
        print "You entered an invalid option. Please try again.\n";
        print "\t Hit \<ENTER\> to continue.\n";
        $dummy = <STDIN>;
        goto MENU_START;
    }
}

# Menu Option d
NEW_SEARCH:

system("clear");

print "\n\n Enter the field that you want to search on.\n";
print "      Note: Other than _ \(underscores\), do NOT enter\n";
print "            any special characters\, \: \;\,\%\, etc\.\n";
print "\n          Example:  owner\n...> ";
$input_fn = <STDIN>;
chomp $input_fn;
print "\n\n Enter the search_string for the $input_fn field.\n";
print "       Note: You need to preceed (escape) special characters with\n";
print "             a \(backslash\) \\ \n";
print
  "                  Example for \"\/tmp\/var\/log\" would be entered as\: \n";
print "                       \.\.\.\.\> \\\/tmp\\\/var\\\/log \n .....\> ";
$search_str = <STDIN>;
chomp $search_str;

print
  "\n\nYou are searching for the string \"$search_str\" in the Autosys jil \n";
print "\" $input_fn \" field from the AS jil file. \n\n";

NEW_JIL_SOURCE_FILE:

if ( defined $workingfile_name )
{    # reset all variables if new search is required.
    undef @all_jn;
    undef %as_jil;
    undef @jobs_w_match;
    undef @test;
    undef @total;
    undef @workingfile;
    undef @adj_file;
    undef $cnt;
}
else {
    $workingfile_name = shift @ARGV;
}

open FILE, "$workingfile_name"
  or die "Problem accessing the $workingfile_name, specifically $!\n";
@workingfile = <FILE>;
close(FILE);

foreach $line (@workingfile) {
    $line =~ s/^\s*//;    # remove leading spaces
    if ( $line =~ m/.*?(\/\*).*?(([a-z][a-z]+)).*?(\*\/)(.)/is ) {
        $line =
          "";    # removes comment line for easier processing will add back in.
    }
}

# extracts range of lines between insert_job: and a blank line
@adj_file = grep( /insert_job\:/ .. /^$/, @workingfile );

# builds array of jobnames called @all_jn

print "Building the job name list ... ";

# Getting just job names out of insert_job line

foreach $line (@adj_file) {
    if ( $line =~ /insert_job\:/ ) {
        $cnt++;
        print "\....\n"
          if ( $cnt % 1500 == 0 )
          ;    # visual processing of load into job name array @all_jn
        ( $first_part, $second_part, $jt_field_val ) = split /\:/, $line;
        $second_part =~ s/^\s+//;    # strips leading spaces
        ( $jobname, $end_of_line ) = split /\s+/, $second_part;
        push @all_jn, $jobname;
    }
}

print "Loading into hash ...";

foreach $line (@adj_file) {

    $line =~ s/^\s*//;               # remove leading space on each line

    if ( $line =~ /insert_job/ ) {
        $jn = shift @all_jn;
        if ( $line =~ /$jn/ ) {
            $cnt++;
            print "\....\n"
              if ( $cnt % 1500 == 0 );    # visual processing of load into hash
            push @{ $as_jil{$jn} }, $line unless defined $as_jil{$jn};
            next;
        }
    }
    elsif ( $line =~ /\:/ or $line =~ /^$/ ) {
        die 'No jobname yet' unless defined $jn;
        push @{ $as_jil{$jn} }, $line;
    }
    else {
        print "LINE $line\n ";
        die "I don't understand: $line ";
    }
}

foreach $jn ( keys %as_jil ) {
    @test = grep { /$input_fn/ && /$search_str/ } @{ $as_jil{$jn} };
    push @jobs_w_match, $jn if ( scalar @test > 0 );
    push @total, @test;
}

print
"\n\nTotal number of jobs that match the search string \"$search_str\"\: \n\t";
print scalar(@jobs_w_match), "\n";

print "Hit \<ENTER\> to goto main menu\n";
$dummy = <STDIN>;
goto MENU_START;

# Menu Option c
OUTPUT_JIL_FILE_OPTION:

system("clear");

say "Creating the custom AS jil file.\n";

say "\tThe SEARCH STRING was \"$search_str\" in the AS field \"$input_fn\".";

print "\nEnter the name of the output file you want the file to be \n";
print "\tPlease use a *.jil extension for your output file.\n";
print "\n\n Enter the file name. \n     ---> ";

my $output_file = <STDIN>;
chomp $output_file;

if ( -e $output_file ) {
    print
"ERROR\: File name \"$output_file\" is already in use.  Please select another file name for the jil output file.\n";
    print "\n\t Hit \<Enter\> to continue.\n";
    $dummy = <STDIN>;
    goto OUTPUT_JIL_FILE_OPTION;
}

open( OUT, ">$output_file" ) or die "File is not able to be created: $!";

foreach $jn (@jobs_w_match) {
    print OUT "\n" unless ( $jn eq $jobs_w_match[0] );
    print OUT
"\/\* \-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\- $jn \-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\- \*\/\n";
    print OUT "\n";
    foreach $line ( @{ $as_jil{$jn} } ) {
        print OUT "$line";
    }
}
close(OUT);

print "\n\n The file \"$output_file\" has been created with ",
  scalar @jobs_w_match, " that match \n";
print "the search criteria\: \"$search_str\"\n  YEAH!!!\n\n";

print "Hit \<ENTER\> to return to the main menu\n";
$dummy = <STDIN>;

goto MENU_START;

# Menu Option b
VIEW_LINES:

$cnt = 0;

system("clear");

print "\n\nHere are the lines that matched\:\n\n";

print
"\n\nTotal number of lines that match the search string \"$search_str\"\: \n\t";
print scalar(@total), "\n";

for $line (@total) {
    print "$line";
    $cnt++;
    if ( $cnt % 18 == 0 ) {
        print "\n\nHit \<ENTER\> to continue\n";
        print "\nEnter \(\"q\" for quit\) to exit to main menu.\n";
        $dummy = <STDIN>;
        chomp $dummy;
        goto MENU_START if ( $dummy eq "q" );
    }
}

print "\n\nHit \<ENTER\> to return to the main menu\n\n";
$dummy = <STDIN>;

goto MENU_START;

# Menu Option a
PRT_JOBS:

$cnt = 0;

system("clear");

say "\tThe SEARCH STRING was \"$search_str\" in the AS field \"$input_fn\".";

print "\nEnter the name of the output file you want the file to be \n";
print "\n\n Enter the file name. \n     ---> ";

$output_file = <STDIN>;
chomp $output_file;

if ( -e $output_file ) {
    print
"ERROR\: File name \"$output_file\" is already in use.  Please select another file name for the jil output file.\n";
    print "\n\t Hit \<Enter\> to continue.\n";
    $dummy = <STDIN>;
    goto PRT_JOBS;
}

open( OUT, ">$output_file" ) or die "File is not able to be created: $!";

foreach $line (@jobs_w_match) {
    print OUT "$line\n";
}

close(OUT);
print "\n\nYou have succesfully created the output file \"$output_file\"\n";

print
"\n\nThe total number of job names in this list that match the search string \"$search_str\"are\: \n\t";
print scalar(@jobs_w_match), "\n";

print "\n\nHit \<ENTER\> to return to the main menu\n\n";
$dummy = <STDIN>;

goto MENU_START;

# option e
VIEW_JOBS:

$cnt = 0;

system("clear");

print "\n\nHere are the jobs that matched\:\n\n";

foreach $line (@jobs_w_match) {
    print "$line\n";
    $cnt++;
    if ( $cnt % 18 == 0 ) {
        print "\n\nHit \<ENTER\> to continue\n\n";
        print "\nEnter \(\"q\" for quit\) to exit to main menu.\n";
        $dummy = <STDIN>;
        chomp $dummy;
        goto MENU_START if ( $dummy eq "q" );
    }
}

close(OUT);
print "\n\nYou have created the output file \"$output_file\"\n";

print
"\n\nTotal number of jobs that match the search string \"$search_str\"\: \n\t";
print scalar(@jobs_w_match), "\n";

print "\n\nHit \<ENTER\> to return to the main menu\n\n";
$dummy = <STDIN>;
goto MENU_START;

DUAL_VIEW:

system("clear");

$cnt = 0;

print
"\n\nTotal number of jobs that match the search string \"$search_str\"\: \n\t";
print scalar(@jobs_w_match), "\n\n\n";

foreach $jn ( keys %as_jil ) {
    @test = grep { /$input_fn/ && /$search_str/ } @{ $as_jil{$jn} };
    @jobname = grep { /insert_job\:/ } @{ $as_jil{$jn} };
    if ( scalar @test > 0 ) {
        print "@jobname";
        print "@test\n";
        $cnt++;
        if ( $cnt % 9 == 0 ) {
            print "\n\nHit \<ENTER\> to continue\n\n";
            print "\nEnter \(\"q\" for quit\) to exit to main menu.\n";
            $dummy = <STDIN>;
            chomp $dummy;
            goto MENU_START if ( $dummy eq "q" );
        }
    }
}

print "Hit \<ENTER\> to goto main menu\n";
$dummy = <STDIN>;
goto MENU_START;

DUAL_PRINT:

system("clear");

say "\tThe SEARCH STRING was \"$search_str\" in the AS field \"$input_fn\".";

print "\nEnter the name of the output file you want the file to be \n";
print "\n\n Enter the file name. \n     ---> ";

$output_file = <STDIN>;
chomp $output_file;

if ( -e $output_file ) {
    print
"ERROR\: File name \"$output_file\" is already in use.  Please select another file name for the jil output file.\n";
    print "\n\t Hit \<Enter\> to continue.\n";
    $dummy = <STDIN>;
    goto PRT_JOBS;
}

open( OUT, ">$output_file" ) or die "File is not able to be created: $!";

$cnt = 0;

print
"\n\nTotal number of jobs that match the search string \"$search_str\"\: \n\t";
print scalar(@jobs_w_match), "\n\n\n";

foreach $jn ( keys %as_jil ) {
    @test = grep { /$input_fn/ && /$search_str/ } @{ $as_jil{$jn} };
    @jobname = grep { /insert_job\:/ } @{ $as_jil{$jn} };
    if ( scalar @test > 0 ) {
        print OUT "@jobname";
        print OUT "@test\n";
    }
}

close(OUT);

print "\n\n The file \"$output_file\" has been created with ",
  scalar @jobs_w_match, " that match \n";
print "the search criteria\: \"$search_str\"\n  YEAH!!!\n\n";

print "Hit \<ENTER\> to return to the main menu\n";
$dummy = <STDIN>;

goto MENU_START;

JOBLIST_2_JIL:

system("clear");

# Verify that all jobs names exist in JIL file

# If JIL file OK,  generate subset of JIL file for job names list

say "Enter the job name list that you want to build the AS JIL from.";

say "   Note\: This list can contain job and box names ONLY!!!\n\n";

chomp( $input_file_jn = <STDIN> );

# Test to see if job list file exists

unless ( -e $input_file_jn ) {
    say "This job list file \"$input_file_jn\" does not exist. Try again.";
    say "\nHit \(ENTER\) to continue.";
    $dummy = <STDIN>;
    goto JOBLIST_2_JIL;
}

# Load job list into job list array

open( IN_JN, "$input_file_jn" )
  or die "Problem processing the $input_file_jn, specifically $!";
@job_names = <IN_JN>;
close(IN_JN);

# Verify job list contains no special characters -- Just job names

$cnt = 0;

foreach $jn (@job_names) {
    chomp($jn);
    $cnt++;
    push( @bad_jn, "\n$cnt $jn\n" ) if ( $jn =~ /\W+/ );
}

if ( ( scalar @bad_jn ) > 0 ) {
    print "@bad_jn\n";
    say "You have ", scalar @bad_jn, " bad records in the job name file.";
    say
"\nYou will have to clean up the file before this file \($input_file_jn\) can be used";
    say "Hit \<ENTER\> to go to the main menu";
    $dummy = <STDIN>;
    goto MENU_START;
}
else {
    say "Your job name file is clean.  YEAH! Let\'s move on.";
    say "\nHit \<ENTER\> to continue.";
    $dummy = <STDIN>;
}

LOAD_NEW_JIL_FILE:

say "\n\n The current Autosys jil source file is $workingfile_name\n";

say
  "  NOTE\:  The output file will ONLY contain fields that are present in the";
say "          in the AS jil source file\n";

say "The Autosys jil source file is $workingfile_name\. ";
say "Is this the file you want to use\? \(y\)es\ or \(n\)o";

chomp( $option = <STDIN> );

if ( $option eq "n" ) {

    say
"Please enter the name of the file of the Autosys JIL source file you want to use.";
    say
"    NOTE:  You will have to enter option \"h\" again to load the right JIL source file for changes.\n";
    chomp( $input_file_jil = <STDIN> );
    unless ( -e $input_file_jil ) {
        say "$input_file_jil does NOT exist";
        say "\n Hit \<ENTER\> to continue";
        $dummy            = <STDIN>;
        $workingfile_name = $input_file_jil;
        goto NEW_JIL_SOURCE_FILE;
    }
}
elsif ( $option eq "y" ) {
    say
"\nYou have decided to keep and use the $workingfile_name as you Autosys JIL source file.";
}
else {
    say "Please enter y or n  for \(y\)es or \(n\)o";
    say "\nHit \(ENTER\) to continue.";
    $dummy = <STDIN>;
    goto LOAD_NEW_JIL_FILE;
}

print "\nEnter the name of the output file you want the file to be \n";
print "\n\n Enter the file name. \n     ---> ";

$output_file = <STDIN>;
chomp $output_file;

if ( -e $output_file ) {
    print
"ERROR\: File name \"$output_file\" is already in use.  Please select another file name for the jil output file.\n";
    print "\n\t Hit \<Enter\> to continue.\n";
    $dummy = <STDIN>;
    goto LOAD_NEW_JIL_FILE;
}

open( OUT, ">$output_file" ) or die "File is not able to be created: $!";

GENERATE_JIL:

while ( scalar(@job_names) ) {
    $jn = pop @job_names;
    chomp($jn);
    foreach $sjn ( keys(%as_jil) ) {
        if ( $jn eq $sjn ) {
            print OUT "@{ $as_jil{$jn} }\n";
            next;
        }
    }
}

say "\n\nThe new JIL file \($output_file\) based off of the job names.";
say
" contained in \($input_file_jn\) and the source JIL of \($workingfile_name\)";

print "\n\t Hit \<Enter\> to continue.\n";
$dummy = <STDIN>;
goto MENU_START;

exit
