#!perl
BEGIN { use CGI::Carp qw(carpout);  open(LOG, ">>_error2.txt") or  die("Unable to open mycgi-log: $!\n");  carpout(LOG);  }
BEGIN { $SIG{"__DIE__"}  = $SIG{"__WARN__"} = sub { my $error = shift; chomp $error; $error =~ s/[<&>]/"&#".ord($&).";"/ge; print "Content-type: text/html\n\n$error\n"; exit 0; } }

# Copyright 2016-2020 Zawy, MIT license

# This program ranks how similar a "baseline text file is to files in a directory. Meant for words using "a to z" characters.
# It's based on finding least "entropy difference" which is probably very close to n-gram methods. 
# It's my implementation of Kullback–Leibler divergence aka relative entropy.
# The algorithm is: 
# Get the same number of words from each "known" author file to compare as long as they have at least 
# as many words as "baseline" unknown author file.  If a word is in baseline that is not in a "known" file, then
# give that word 0.25 value as if it occurred 1/4 of 1 time in the file.
# Let Ai = frequency of word "i" in baseline file, and Bi = freq of word i in comparison file.
# relative entropy = sum over all i { Ai*(log(Ai/Bi)) }
# Lowest relative entropy is closest match.
# 
# Can work on 7KB files (1,000 words) if known files are 50KB. Both at 50KB is darn good.
# Accuracy, approx: 50% in 1st place given 20 authors in same genre with 50k files.
# Use SVMLink open software ranking capability for professional work.

$windows ='no';
if ($windows eq 'yes' ) { $blah='\\';  }  # windows
else { $blah = '/'; }  # linux

########   TELL PROGRAM WHAT IT NEEDS TO KNOW #########
open(F,"<author_ignore_words.txt") or $words_to_ignore=''; $words_to_ignore=join('',<F>); close F;  # comment these 2 lines out if the word list is small and use the scalar below
 $words_to_ignore=~s/\n/\|/g;
# $words_to_ignore= 'bitcoin|node|nodes|general|generals|byzantine|encrypted|hash| cryptographic|coin|cryptography|coins|encrypt|messages|port|cryptography|network|cash|currency|transaction|ecash|security|distributed|asics|cpu|fee|fees|rsa|ip|ec-dsa|prebitcoin|decentralized|decentralize|transactions|hashcash|anonymous|cypherpunks|satoshi|money|http|smtp|tcp|arpanet|proof-of-work|nakamoto|block|blocks|chain|blockchain|proof|work'; # for example bitcoin|blockchain|byzantine|
# $baselinefile='author_baseline.txt'; 

$baselinefile = 'unknown_author.txt'; # author's text for comparison to authors in $dir. Stays in same directory as this program
$baselinesize = -s $baselinefile; # get size of file in bytes
$buffer = 1.07; # $buffer=1.07 helps assure enough words are pulled in from known files, but it means the "known" files must be > 7% bigger
$min_file_size = $buffer*$baselinesize;
# $dir='authors_all'; # all files > 30% bigger than baseline file to make sure enough words are retireved.
$dir = 'known_authors';

$smallest =1000000000;
opendir(DIR, $dir) or die $!;
while ($file = readdir(DIR)) {
   if ($min_file_size < -s ".$blah$dir$blah$file" and $file =~ m/\.txt$/) {
		push(@files,$file);
		if (-s ".$blah$dir$blah$file" < $smallest) { $smallest = -s ".$blah$dir$blah$file"; }
  }
}
closedir(DIR);

$oversize = $smallest/$baselinesize/$buffer;

########          PRINT HTML HEADER         #######
print"Content-type: text/html\n\n<html><H3>Author Comparison, and entropy of authors</H3>
$baselinefile is $baselinesize bytes. <BR>
known directory: $dir<BR>
Words to ignore: $words_to_ignore<BR>";

if ($smallest == 1000000000) { print "\n\n No file found in the $dir folder."; exit; }

#######       RUN PROGRAM        ######
open(F,"<$baselinefile") or die $!; read(F,$c,$baselinesize); close F;
%baseline_count=get_word_counts($c); # stores count (value) of each word (key).

print "Using first " . int($smallest) . " bytes of known files\nOversize value is $oversize\nBuffer is $buffer\n\n$ignore\n\n";

foreach $file (@files) {
    open(F, "<.$blah$dir$blah$file")  or die $!;
   # open(GG, ">temp_out_$file") or die $!; 
    read(F,$c,$baselinesize*$oversize*$buffer); close F;
    %known_count=get_word_counts($c);
     foreach $word (keys %baseline_count) {
		$m=$baseline_count{$word};
		# begin core calculation
		$k = $known_count{$word}/$oversize;
		 if ($known_count{$word} < 1 ) { $k=.25/$oversize; } # 0.25 was determined by experiment
		$scores{$file}+=$m*log($m/$k);  # Kullback–Leibler divergence aka relative entropy
		# end core calculation
	} # next word
	$scores{$file} /= $total_words;
 #  close GG;
}  # next file
######      FINISHED  ----- PRINT RESULTS     ##########
print "First $total_words words from baseline text above and known texts below were compared.<BR><BR>";
@ranked = sort {$scores{$a} <=> $scores{$b} } keys %scores;
foreach $file (@ranked) { $rank++;
	print "$rank " . int($scores{$file}) . " = $file <br>";
}

exit;
########       SUBROUTINE        #########
sub get_word_counts {  $c=$_[0];
    $c=lc $c; # ignore capitalization
    $c=~s/'|`|´|’//g; 
   # $c=~s/[^a-z ,.:;'"?!\(|\)]/ /gs;   $c=~s/(\.|,|\!|\?|;|:|'|\(|\))/ $1 /gs;  # keep punctuation
   $c=~s/[^a-z ]/ /gs; # no punctuation, no numbers
   $c=~s/ +/ /gs;
   if ($words_to_ignore ne '') {$c=~s/ $words_to_ignore / /gsi;}
  @c=split(" ", $c);
  if ($firsttime eq '')  { $total_words=$#c; $firsttime='nope';}
  else { $#c=$total_words*$oversize; }
  undef %count;
     foreach $c (@c) { $count{$c}++; $num_words{$file}++;}  # get word counts
    # foreach $c (@c) {  $y=$z; $z=$c; $count{"$y $z"}++;$num_words{$file}++; } # as word pairs
    # foreach $c (@c) { $x=$y; $y=$z; $z=$c; $count{"$x O $z"}++; $num_words{$file}++;}  # missing middle
    # foreach $c (@c) { $x=$y; $y=$z; $z=$c; $count{"$x $y $z"}++;$num_words{$file}++; }   # triples
return %count;  }
