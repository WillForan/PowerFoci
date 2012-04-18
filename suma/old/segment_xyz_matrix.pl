#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;
#use v5.14;
#max and min
my %opts= (m=>30, M=>70);
getopts('m:M:',\%opts);
######
# 
#  o make hash from node_coord file   { roi# -> node }
#
#  o write line segments node -> node if roi# mapping exists
#  o colorize based on deltaR
#
#####

#collect stats
use Statistics::Descriptive;
my $stat = Statistics::Descriptive::Full->new();

# all ROIs
#

my %roiNode;
my %roiXYZ;
my $OutOfRange=0;

open my $nodeCoor, '../matrix/bb244_coordinate' or die "cannot open coord file: $!\n";
while(<$nodeCoor>){
 my ($x,$y,$z) = (split /\s+/)[0..2];
 $roiXYZ{$.}="$x $y $z";
}
close $nodeCoor;

# read in colors
#
my %color=();
my $numColors;
# for colors white to xxxx
for my $colorfile ('Blue','Red') {
   open my $colorFile, "colors/rgbWhite$colorfile.spec" or die "cannot open 'rgbWhite$colorfile.spec': $!\n";
   while (<$colorFile>) {
    next unless m/#(.{2})(.{2})(.{2})/;
    # push hex converted to rgb 0->1 => hash{blue|red}= ([1 1 0], [.5 .5 .5], ...)
    push @{$color{$colorfile}}, [map {(hex $_)/256} ($1,$2,$3) ];
   }
   close $colorFile;
   # numColors to use is min of colors in either file
   $numColors = $#{$color{$colorfile}} if (!$numColors || $numColors > $#{$color{$colorfile}});
}


# what are the changes in corrilation?
#
my $RRdRfile = "../matrix/bpreg_m_simult_luna.txt"; my $name="bpreg-simult";
my ($max,$min) = (0,100);

open my $output, ">vis/$name-$opts{m}-$opts{M}.dset.do" or die "cannot open '>vis/$name': $!\n";
print $output "#segments\n";
my @deltRs = ();
open my $RRdR, $RRdRfile or die "cannot open $RRdRfile: $!\n";
while (<$RRdR>) {
 next if $.<2;
 chomp;
 my @row= split;
 my $n1=$roiXYZ{$.};
 #exists
 if(!$n1) { print STDERR "$.: not in roi range skipping row\n"; next}

 for (0..$.-2) {
  my $r2=$_+1; # roi's are one based
  my $dr=$row[$_];
  my $n2=$roiXYZ{$r2};
  # have node?
  if(!$n2) { print STDERR "$r2: not in roi range, skipping column\n"; next}
   


  ## get eclidian dist between cors (stored as space delm. in n{1,2})
  my @xyz; my $edist=0;
  # get cords
  push @xyz, [split /\s/,$_ ] for ($n1,$n2);
  # sum dist of pairwise addition
  $edist += $_ for map { ($xyz[0][$_] - $xyz[1][$_] )**2 } 0..2; 
  # sqrt
  $edist = $edist**.5;

  $stat->add_data($edist); 
  unless($edist >= $opts{m} && $edist <= $opts{M}) {  $OutOfRange++;  next}


  ## store corrilation
  push @deltRs, [$n1,$n2,$dr,$edist];

  ## get min and max for colors
  ## this effort is discarded later
  #$dr = abs($dr);
  #$max = $dr if $dr > $max; 
  #$min = $dr if $dr < $min; 

 }
}

#### Stats #####
print "$OutOfRange out of range\n";

print join ("\t", qw/count max min mean std_dev variance/),"\n";
print join ("\t", $stat->count, map {sprintf "%.3f",$_} 
                      ($stat->max, $stat->min, $stat->mean, 
                       $stat->standard_deviation, $stat->variance)),"\n";
#start again for only what is cept
$stat = Statistics::Descriptive::Full->new();
$stat->add_data(map {$_->[3]} @deltRs); 

print join ("\t", $stat->count, map {sprintf "%.3f",$_} 
                      ($stat->max, $stat->min, $stat->mean, 
                       $stat->standard_deviation, $stat->variance)),"\n";




###############
# only take top of the top
my $listmax=$#deltRs<300?$#deltRs:300;
my @topDelts = sort { abs($b->[2])<=>abs($a->[2]) } @deltRs[0..$listmax];
# get new max and min
$min = 100;
$max = 0;
for(map {$_->[2]} @topDelts){
   my $dr=abs($_);
   $max = $dr if $dr > $max;
   $min = $dr if $dr < $min;
}
print "file\tRmin Rmax\n";
print "$name\t$min $max\n";
################

# set step  
my $colorstep = ($max-$min)/$numColors;

#draw the line
for my $cor (@topDelts) {
 # red is positive, blue is negative
 my $sign='Red';
 $sign='Blue' if $cor->[2] < 0;




 ## set color
 # delta-min/steps ==> where in spectrum value is
 my $coloridx = int((abs($cor->[2])-$min)/$colorstep);
 # sometimes we go over
 $coloridx=$numColors if $coloridx > $numColors;
 # get rgb given a color idx
 my @rgb = @{@{$color{$sign}}[ $coloridx  ]};

 # print endpoints (both cords) color (r g b) and width
 print $output join(" ",@{$cor}[0,1], @rgb, .5),"\n";
}

close $output;
print "DriveSuma -echo_edu -com viewer_cont -load_do vis/$name\n";
