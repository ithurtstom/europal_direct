#!/usr/bin/perl

# This script is used to build directional corpus files out of the europarl parallel corpus files.
#
# Premises:
# 1. Execute the script on the level where there are two directories with the language abbrevations, e.g.
# directory ./en, directory ./fr which contain all (or a subset) of the europarl v6 small daily text files.
# In these two, make empty subdirectories, ./en/processed and ./fr/processed
# 
# 2. Execute the script like 'perl europarl_direct_ctags.pl ./fr ./en ./fr/processed ./en/processed EN yes (or no) correct (or uncorrect)
# 
# Arguments:
# 1: directory name for the original dailly text files in the translated language (target language for the directional corpus)
# 2: directory name for the original daily text files in the source language (source language for the directional corpus)
# 3: directory name for the processed text files in the translated language (target language files for the directional corpus)
# 4: directory name for the processed text files in the source language (source language files for the directional corpus)
# 5: source language variant name to be extracted (select one out of EN|DE|FR|ES|IT|PT|FI|SV|DA|NL|EL).
# 6: toggle to keep the SPEAKER and LANGUAGE tags in the files (type "yes" or "no") 
# 7: toggle to correct the LANGUAGE tags in both files first (type "correct" or "uncorrect")
#
# The script will:
# 
# 1. If argument 7 is "correct", the script will first correct all LANGUAGE="XY" tags in the files to be processed,
# because in europarl, the LANGUAGE tags can be provided in the files of one language, but may however 
# (because of automated, uncorrected extraction) be missing in the files of the another language. 
# The script therefore makes querys to an index file, which contains all language tag
# information of all the europarl files in all languages. This info is entered where missing in the files to be
# processed. This grows the directional corpus significantly.
#
# **************************************************************************************************
# Please make sure to first generate the index file with the script "europarl_language_tag_index.pl"
# **************************************************************************************************
#
# 2. The script continues to extract all sentences in the text files of the first directory, i.e. sentences tagged
# with the language indicated in command line argument 5 (e.g. EN, which means all sentences in the French files, 
# which originally have been English and therefore have been translated to French).
# Note: This will be your target language files for the directional corpus.
#
# 3. Extract all corresponding sentences from the second directory text files (which e.g. means, the corresponding
# original English source sentences). 
# Note: This will be your source language files for the directional corpus.
#
# Note: The script will not change your original files. All results are stored as
# text files named *.out (and *.ctags for corrected tags, or *.utags without corrected tags) in the folders
# /en/processed and /fr/processed. Each 'pair' of files has the same line number and is sentence aligned.
#
# Acknowledgments:
# The scripting for generating and querying the index file has mainly been done by another COMTIS project member:
# 
# Bruno Cartoni, Bruno.Cartoni@unige.ch
#
# COMTIS, Thomas Meyer, 03.11.2010. Thomas.Meyer@idiap.ch

use strict;
use warnings;

my @lines;                      # Array for the line numbers containing source language sentences.

my $indir1 =  $ARGV[0];         # Input directory name for the original daily text files (translated language).
my $indir2 =  $ARGV[1];         # Input directory name for the original daily text files (source language).
my $outdir1 = $ARGV[2];         # Output directory name for the processed text files (translated language).
my $outdir2 = $ARGV[3];         # Ouptut directory name for the processed text files (source language).

my $sourcelang = $ARGV[4];      # Source language variant name to be extracted (EN|DE|FR|ES|IT|PT|FI|SV|DA|NL|EL).

my $keeptags = $ARGV[5];	# Toggle to keep the SPEAKER and LANGUAGE tags ("yes" or "no").

my $correcttags = $ARGV[6];     # Toggle to correct missing LANGUAGE first ("correct" or "uncorrect") 


my $infile1;
my $infile2;           
my $outfile1;
my $outfile2;

tag_correction();               # go to sub first and check if command line option is defined

    while (defined($infile1 = glob($indir1."/processed/*.*"))) {                   # process all files (either *.ctags or *.utags in directory ./XY/processed) 
        $outfile1 = $outdir1."/".substr($infile1,rindex($infile1,"/")+1).".out";  
        open (IFILE1, "<$infile1") or die "Can't open $infile1: $!";                     
        open (OFILE1, ">$outfile1") or die "Can't create file: $!";        
        
        my $isTranslatedSentence;
    
    while (<IFILE1>) {   
        if ($_ =~ /^<SPEAKER/) {
            $isTranslatedSentence = $_ =~ /LANGUAGE="$sourcelang"/;                 # lookup source language sentences                   
                }
                if (defined ($keeptags) && $keeptags eq ("yes")) {
                     push(@lines, $.) if $isTranslatedSentence && $_ !~ /^<P/;      # keep SPEAKER / LANGUAGE tags 
		     print OFILE1 if $isTranslatedSentence && $_ !~ /^<P/;
		}
		else {
		     push(@lines, $.) if $isTranslatedSentence && $_ !~ /^</;       # delete all tags
                     print OFILE1 if $isTranslatedSentence && $_ !~ /^</;
                }    
        }  
  }             
      while (defined($infile2 = glob($indir2."/processed/*.*"))) {                  # process all files (either *.ctags or *.utags in directory ./XY/processed)    
        $outfile2 = $outdir2."/".substr($infile2,rindex($infile2,"/")+1).".out";  
        open (IFILE2, "<$infile2") or die "Can't open $infile2: $!";                     
        open (OFILE2, ">$outfile2") or die "Can't create file: $!";

        while (<IFILE2>) {
            foreach my $line (@lines) {                                             # lookup all corresponding sentences
            print OFILE2 if $. == $line;
            } 
        }
  }
    close(IFILE1) or die "Can't close $infile1: $!";                                # generate *.out files in ./XY/processed
    close(OFILE1) or die "Can't close $outfile1: $!";               
    close(IFILE2) or die "Can't close $infile2: $!";                
    close(OFILE2) or die "Can't close $outfile2: $!";              

print "europarl directional corpus has been generated\n";


sub tag_correction
{ 
    # if command line option is "uncorrect", just copy the files as *.utags to ./XY/processed and return to main
    
    unless (defined ($correcttags) && $correcttags eq ("correct")) { 
      while (defined($infile1 = glob($indir1."/*.txt")) && defined($infile2 = glob($indir2."/*.txt"))) {                         
        $outfile1 = $outdir1."/".substr($infile1,rindex($infile1,"/")+1).".utags";
        $outfile2 = $outdir2."/".substr($infile2,rindex($infile2,"/")+1).".utags";   
        open (UNCORRECTFILE1, "<$infile1") or die "Can't open $infile1: $!";
        open (UNCORRECTFILE2, "<$infile2") or die "Can't open $infile2: $!";    
        open (UNCORRECTEDFILE1, ">$outfile1") or die "Can't create file: $!";
        open (UNCORRECTEDFILE2, ">$outfile2") or die "Can't create file: $!";
        
        while (<UNCORRECTFILE1>) {         # just copy every file to ./XY/processed/*.utags
           print UNCORRECTEDFILE1;
        }
        
        while (<UNCORRECTFILE2>) {
            print UNCORRECTEDFILE2;
        }
    }
        close(UNCORRECTFILE1);
        close(UNCORRECTFILE2);
        close(UNCORRECTEDFILE1) or die "Can't close $outfile1: $!"; 
        close(UNCORRECTEDFILE2) or die "Can't close $outfile2: $!"; 
        
        return;         # return to main without any correction
    }
    
    # start of tag correction section
    
    my @infile1_content;
    my @infile2_content;
    my $line1;
    my $line2;
    
    
    # declare hash to consult index file
    my %index;
        
    # initialize index hash from europarl_language_index.txt
    
    open (INDEX_CLEANED, "<europarl_language_index_v6.txt") or die "Index file does not exist! Please create it with 'europarl_language_tag_index.pl'!";
    
    while (<INDEX_CLEANED>) {
        chomp;
        $_ =~ /(.*)\t(.*)/;
        my $index_number = $1;
        my $lang = $2;
        $index{$index_number} = $lang;
    }
    close (INDEX_CLEANED);
    
    # start correction: all files are stored as *.ctags in ./XY/processed
          
    while (defined($infile1 = glob($indir1."/*.txt")) && defined($infile2 = glob($indir2."/*.txt"))) {                         
        $outfile1 = $outdir1."/".substr($infile1,rindex($infile1,"/")+1).".ctags";
        $outfile2 = $outdir2."/".substr($infile2,rindex($infile2,"/")+1).".ctags";   
        open (CORRECTFILE1, "<$infile1") or die "Can't open $infile1: $!";
        @infile1_content = <CORRECTFILE1>;
        close (CORRECTFILE1);
        open (CORRECTFILE2, "<$infile2") or die "Can't open $infile2: $!";
        @infile2_content = <CORRECTFILE2>;
        close (CORRECTFILE2);
        
        open (CORRECTEDFILE1, ">$outfile1") or die "Can't create file: $!";
        open (CORRECTEDFILE2, ">$outfile2") or die "Can't create file: $!";
  

     my $filespeakerid;
     my $new_index;
     my $filename;
     my $indexlanguage;
     my $filelanguage;

    foreach $line1 (@infile1_content) {
	 
	 # create new hash with file info to match with index info
	    
	 if ($line1 =~ /^<SPEAKER ID="?(\d*)"?/) {
		   $filespeakerid = $1;
		   $infile1 =~ /\.\/.*\/(.*).txt/;
		   $filename = $1;
		   $new_index = $filename."-SP".$filespeakerid;
        }
        
        # when $line1 contains no language tag, lookup index if there should be one
        
         if ($line1 =~ /^<SPEAKER/ && $line1 !~ /LANGUAGE/ && exists $index{$new_index}) {
                $indexlanguage = $index{$new_index};
                $line1 =~ s/SPEAKER ID="?\d*"?/SPEAKER ID=$filespeakerid LANGUAGE="$indexlanguage"/;      # magic tag inserting here
                print CORRECTEDFILE1 $line1;
            }
         
        # when $line1 contains no language tag and index has a diverging one, print line as is
        
         elsif ($line1 =~ /^<SPEAKER/ && $line1 !~ /LANGUAGE/ && exists $index{$new_index}) {
             $indexlanguage = $index{$new_index};
                if ($indexlanguage =~ /#/) {
                    print CORRECTEDFILE1 $line1;
                }
         }
         
         # when $line1 contains language tag, lookup index and check if it's the same
        
         elsif ($line1 =~ /LANGUAGE="([A-Z]+)"/ && exists $index{$new_index}) {
             $filelanguage = $1;
             $indexlanguage = $index{$new_index};
            if ($filelanguage eq $indexlanguage) {
                    print CORRECTEDFILE1 $line1;
            }
            
            # when $line1 contains language tag, but index has a diverging one, delete existing language tag
                        
            elsif ($indexlanguage =~ /#/) {
                    $line1 =~ s/LANGUAGE="[A-Z]+"//;
                    print CORRECTEDFILE1 $line1;
            }
         }
         else {
            print CORRECTEDFILE1 $line1;
         }              
    }
    
        foreach $line2 (@infile2_content) {
	 
	 # create new hash with file info to match with index info
	    
	 if ($line2 =~ /^<SPEAKER ID="?(\d*)"?/) {
		   $filespeakerid = $1;
		   $infile2 =~ /\.\/.*\/(.*).txt/;
		   $filename = $1;
		   $new_index = $filename."-SP".$filespeakerid;
        }
        
        # when $line2 contains no language tag, lookup index if there should be one
        
         if ($line2 =~ /^<SPEAKER/ && $line2 !~ /LANGUAGE/ && exists $index{$new_index}) {
                $indexlanguage = $index{$new_index};
                $line2 =~ s/SPEAKER ID="?\d*"?/SPEAKER ID=$filespeakerid LANGUAGE="$indexlanguage"/;      # magic tag inserting here
                print CORRECTEDFILE2 $line2;
            }
            
         # when $line2 contains no language tag and index has a diverging one, print line as is   
            
         elsif ($line2 =~ /^<SPEAKER/ && $line2 !~ /LANGUAGE/ && exists $index{$new_index}) {
             $indexlanguage = $index{$new_index};
                if ($indexlanguage =~ /#/) {
                    print CORRECTEDFILE2 $line2;
                }
         }
         
         # when $line2 contains language tag, lookup index and check if it's the same
         
         elsif ($line2 =~ /LANGUAGE="([A-Z]+)"/ && exists $index{$new_index}) {
             $filelanguage = $1;
             $indexlanguage = $index{$new_index};
            if ($filelanguage eq $indexlanguage) {
                    print CORRECTEDFILE2 $line2;
            }   
            
            # when $line2 contains language tag, but index has a diverging one, delete existing language tag
                     
            elsif ($indexlanguage =~ /#/) {
                    $line2 =~ s/LANGUAGE="[A-Z]+"//;
                    print CORRECTEDFILE2 $line2;
            }
         }
         else {
            print CORRECTEDFILE2 $line2;
         }              
    }    
 }
  close(CORRECTEDFILE1) or die "Can't close $outfile1: $!";  # generate correct *.ctags files and return to main
  close(CORRECTEDFILE2) or die "Can't close $outfile2: $!";    
}
