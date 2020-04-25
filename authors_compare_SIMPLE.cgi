#!perl
BEGIN { use CGI::Carp qw(carpout);  open(LOG, ">>_error2.txt") or  die("Unable to open mycgi-log: $!\n");  carpout(LOG);  }
BEGIN { $SIG{"__DIE__"}  = $SIG{"__WARN__"} = sub { my $error = shift; chomp $error; $error =~ s/[<&>]/"&#".ord($&).";"/ge; print "Content-type: text/html\n\n$error\n"; exit 0; } }

# This may run only on windows due to directory handling
$windows ='no';
if ($windows eq 'yes' ) { $blah='\\';  }
else { $blah = '/'; }

# This program ranks how similar a text baseline file author is to known file authors. Meant for English words.
# Can work on 7KB files (1,000 words) if known files are 50KB. Both at 50KB is darn good.
# Accuracy, approx: 50% in 1st place given 20 authors in same genre with 50k files.
# Use SVMLink open software ranking capability for professional work.
# Author: Scott Roberts, 2016.
########   TELL PROGRAM WHAT IT NEEDS TO KNOW #########
open(F,"<author_ignore_words.txt") or $words_to_ignore=''; $words_to_ignore=join('',<F>); close F;  # comment these 2 lines out if the word list is small and use the scalar below
 $words_to_ignore=~s/\n/\|/g;
# $words_to_ignore= 'bitcoin|node|nodes|general|generals|byzantine|encrypted|hash| cryptographic|coin|cryptography|coins|encrypt|messages|port|cryptography|network|cash|currency|transaction|ecash|security|distributed|asics|cpu|fee|fees|rsa|ip|ec-dsa|prebitcoin|decentralized|decentralize|transactions|hashcash|anonymous|cypherpunks|satoshi|money|http|smtp|tcp|arpanet|proof-of-work|nakamoto|block|blocks|chain|blockchain|proof|work'; # for example bitcoin|blockchain|byzantine|
# $baselinefile='author_baseline.txt'; # unknown author. Stays in directory with this program
$baselinefile = 'chris.txt';
$baselinesize=-s $baselinefile; # get size of file in bytes
$buffer=1.1; # helps assure enough words are pulled in from known files
$min_file_size = $buffer*$baselinesize;
$dir='authors_all'; # all files > 30% bigger than baseline file to make sure enough words are retireved.

$smallest =1000000000;
opendir(DIR, $dir) or die $!;
while ($file = readdir(DIR)) {
   if ($min_file_size < -s ".$blah$dir$blah$file" and $file =~ m/\.txt$/) {
		push(@files,$file);
		if (-s ".$blah$dir$blah$file" < $smallest) { $smallest=-s ".$blah$dir$blah$file"; }
  }
}
closedir(DIR);

$oversize=$smallest/$baselinesize/$buffer;

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
    open(GG, ">$blahtemp$blahout_$file") or die $!;
    read(F,$c,$baselinesize*$oversize*$buffer); close F;
    %known_count=get_word_counts($c);
     foreach $word (keys %baseline_count) {
		$m=$baseline_count{$word};
		 if ($known_count{$word} < 1 ) { $k=.25/$total_words/$oversize; }
		else { $k = $known_count{$word}/$oversize; }
		if ($m > $k) {
			$scores{$file}+=log($m/$k);
			if ($known_count{$word} >= 1 ) { print GG "$m\t$known_count{$word}\t$word\n"; }
		}
	} # next word
   close GG;
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