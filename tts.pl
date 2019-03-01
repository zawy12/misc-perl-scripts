#!/usr/bin/perl

# @ Copyright 2019 Zawy, MIT license

# This is for speaking the text of book.txt while following 
# the words on the command line. Displays 5 sentences at a time.
# Instructions: 
# Install espeak.
# Place book to be read in book.txt and run this script:
# perl tts.pl <sentence number> <speed>
# use CTRL-C to exit

open(F,"<book.txt") or die "Could not open the book.txt you want to hear. $!";
@a=<F>; close F;
$a= join("\n", @a);
$a=~s/\r//g;  
$a=~s/\n/ /g;
$a=~s/-\n//g;
$a=~s/ +/ /g;
$a=~s/`|’/'/g;
$a=~s/”|“/"/g;
$a=~s/ *\. *\. *\.//;
$a=~s/([^a-zA-Z0-9,!\?"'.\n ]+)//g;
# $a=~s/\n+ *\n*/\n/g;
@a=split(/\./, $a);
$start = $ARGV[0];
$speed = $ARGV[1];

$SIG{INT}  = sub { $interrupted = 1; };

for ($i=$start; $i<=$#a; $i+=5) {
  system("clear");
	print "\nSentence $i of $#a\n\n";
	for ($j=0;$j<5;$j++) {
		$a[$i+$j] =~ s/\.//g;
		print "$a[$i+$j].\n\n";
		$a[$i+$j] =~ s/'|"//g;
	}
	for ($j=0;$j<5;$j++) {
		if ($interrupted) {goto FIN;}
  	$b=`espeak -s $speed -p 70 '$a[$i+$j]'`;
	}
}
FIN:
exit;

