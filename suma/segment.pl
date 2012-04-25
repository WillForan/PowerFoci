#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;
#use v5.14;
#max and min

my %opts=(n=>'../matrix/bb264_bp_robust_scrapped.txt', # node file
          #r=>'../matrix/top30Low.adjlist', # relationship (adjlist) file matching glob
          t=>'300',                        # top ### of connections to consider
          p=>'vis/compare',                # output prefix
          m=>'0',                          # min distance
          M=>'200',                        # max distance
          H=>'lr',                         # hemisphere
          l=>'1');                         # line width

getopts('n:r:t:T:p:m:M:s:S:c:C:l:H:hdx',\%opts);
######
# 
#  o make hash from node_coord file   { roi# -> node }
#
#  o write line segments node -> node if roi# mapping exists
#  o colorize based on deltaR
# 
#####
if ( exists $opts{T} && $opts{T} >1 ) { print "-T percent should be <= 1\n"; exit }
if ( $opts{t} < 1 ) { print "-t > 1 and an int\n"; exit }

if (exists $opts{h} || !exists $opts{r}) {
 print <<HERE;
$0 
   -r relationship (adj list or matrix)
   -t how many segmants to show (top) ($opts{t})
   -T percent (as .1 for 10%) segments to keep (precedence over -t)
   -p output prefix ($opts{p})
   -m min dist of connection  ($opts{m})
   -M max dist of connection  ($opts{M})
   -H hemisphere to keep {l,r,lr} ($opts{H})
   -n ROI (nodes) e.g ../matrix/bb244_coordinate  ($opts{n})
   -s spectrum min corr (default min of data; vals <= will be same color)
   -S spectrum max corr (default max of data; vals >= will be same color)
   -c corr min          (default unset)
   -C corr max          (default unset)
   -l line width        ($opts{l})
   -d display           write to temp file [.tmp* must already exist]
                        and do suma thing
   -x debug
   -h help

ROI node file delm. by [,\\s]+
determines matrix or adj by first line being more than 3 columns
m <= dist <= max

bb2*4 must match matrix dimensions. 
There is no check to make sure this is the case
It should be okay to always use bb264 for adj list format. 

HERE

   exit;
}

#collect stats
use Statistics::Descriptive;
my $stat = Statistics::Descriptive::Full->new();

# all ROIs
#

my %roiNode;
my %roiXYZ;
my $OutOfRange=0;
my $isAdj=0;

# euclid dist function
# also checks corr range if given
sub getDist {
 my ($n1,$n2,$dr) = @_;
 ## get euclidean dist between cors (stored as space delm. in n{1,2})
 my @xyz; my $edist=0;
 # get cords
 push @xyz, [split /\s/,$_ ] for ($n1,$n2);
 # sum dist of pairwise addition
 $edist += $_ for map { ($xyz[0][$_] - $xyz[1][$_] )**2 } 0..2; 
 # sqrt
 $edist = $edist**.5;

 $stat->add_data($edist); 
 #  min <= dist <= max 
 unless( $opts{m} <= $edist && $edist <= $opts{M}) {  $OutOfRange++;  return}

 # min <= corr <= max
 if( exists $opts{c} && $dr <= $opts{c}) {  $OutOfRange++;  return}
 if( exists $opts{C} && $dr >= $opts{C}) {  $OutOfRange++;  return}

 return $edist;


}

# determine matrix or adj list
# set isAdj to true if less than 4 feilds
open my $RRdR, $opts{r} or die "cannot open $opts{r}: $!\n";
$_=<$RRdR>;
$isAdj = 1 if scalar(split/\s/)<4;
print "Adj? $isAdj\n" if exists $opts{x};
print "hem? $opts{H}\n" if exists $opts{x};
close $RRdR;

# find node coordinates
# use line number for ROI if input is  matrix
# use 4th column          if           adj list
open my $nodeCoor, $opts{n} or die "cannot open coord file $opts{n}: $!\n";
while(<$nodeCoor>){
 my ($x,$y,$z) = (split /[,\s]+/)[0..2];
 # if this is a matrix use the line number as the ROI number
 my $idx=$.;
 # if this is an adj matrix, need the actual ROI number (should be next in coord file)
 $idx=(split /[,\s]+/)[3] if $isAdj; 
 # add to hash
 $roiXYZ{$idx}="$x $y $z";
}
close $nodeCoor;

# read in colors
#   two spectrums. one for positive, one for negative
my %color=();
my $numColors;
# for colors white to xxxx
#for my $colorfile ('WhiteBlue','WhiteRed') {
for my $colorfile ('WhiteBlue','RedYellow') {
   open my $colorFile, "colors/rgb$colorfile.spec" or die "cannot open 'rgb$colorfile.spec': $!\n";
   while (<$colorFile>) {
    next unless m/#(.{2})(.{2})(.{2})/;
    # push hex converted to rgb 0->1 => hash{blue|red}= ([1 1 0], [.5 .5 .5], ...)
    push @{$color{$colorfile}}, [map {(hex $_)/256} ($1,$2,$3) ];
   }
   close $colorFile;
   # numColors to use is min of colors in either file
   $numColors = $#{$color{$colorfile}} if (!$numColors || $numColors > $#{$color{$colorfile}});
}


# what are the changes in correlation?
#
my ($max,$min) = (0,100);

# set up output file
# if we want percent, put that in filename - otherwise use num top
my $fnt=(exists $opts{"T"})?"$opts{T}p":"$opts{t}";
my $filename="$opts{p}-T${fnt}Dm$opts{m}M$opts{M}";
# add any other defined options
for (qw/c C s S/){ $filename.="$_$opts{$_}" if exists $opts{$_} }
# add file extension
$filename.="$opts{H}.dset.do";

open my $output, ">$filename" or die "cannot open '>$filename..': $!\n";
print $output "#segments\n";

my @deltRs = ();

# read in file

my @adjList=();

##### READ MATRIX
sub readMatrix {
   while (<$RRdR>) {
    next if $.<2; # no information in first line that's not elsewhere
    chomp;
    my @row= split;
    my $r1=$.;

    for my $col (0..$.-2) {
     my $r2=$col+1; # roi's are one based
     my $dr=$row[$col];

     # add to adjList
     push @adjList, [$r1,$r2,$dr];
    }
   }
}
##### READ adjlist
sub readAdjList {
   while (<$RRdR>) {
    chomp;
    my ($r1,$r2, $dr) = split;
    push @adjList, [$r1,$r2,$dr];
   }
}


# open the relationship file (matrix or adj list)
open $RRdR, $opts{r} or die "cannot open $opts{r}: $!\n";

# run one of the two read in functions
if ($isAdj) { readAdjList }
else        { readMatrix  }
# and close the file
close $RRdR;

for my $rel (@adjList) {
 # what is the node for the roi
 #my $n1 = $roiNode{$r1};
 #my $n2 = $roiNode{$r2};
 my ($r1,$r2,$dr) = @{$rel};
 my $n1 = $roiXYZ{$r1};
 my $n2 = $roiXYZ{$r2};

 #DEBUG: what nodes are we looking at
 print "$r1 $r2 $dr\t$n1\t$n2\n" if(exists $opts{x});

 # Hemisphere restriction
 my $xcor1 =  (split /\s+/, $n1)[0]; my $xcor2 =  (split /\s+/, $n2)[0]; 
 if( $opts{H} !~ /l/i && ( $xcor1 <= 0 || $xcor2 <= 0 ) ) { print "lost $n1<->$n2 to L\n" if $opts{x}; next }
 if( $opts{H} !~ /r/i && ( $xcor1 >= 0 || $xcor2 >= 0 ) ) { print "lost $n1<->$n2 to R\n" if $opts{x}; next }
 
 # are the nodes visible?
 print STDERR "$r1: not in rois/node_coord.1D\n" if !$n1;
 print STDERR "$r2: not in rois/node_coord.1D\n" if !$n2;
 next if (!$n1 or !$n2);


 # store corrilation
 my $edist=getDist($n1,$n2,$dr);
 push @deltRs, [$n1,$n2,$dr,$edist] if $edist;
}




###############
# first sort based on dr
my @topDelts = sort { abs($b->[2])<=>abs($a->[2]) } @deltRs;

# set listmax to the number of comparisons if less than what is specified as -t on cli
# or use percent, percent takes precedence
$opts{t} = int($opts{T}*$#deltRs) if exists $opts{T};
my $listmax=$#deltRs<$opts{t}?$#deltRs:$opts{t}-1;

# only take top of the top
@topDelts=@topDelts[0..$listmax];

## get new max and min for color spectrum calculation
$min = 100; $max = 0;
for(map {$_->[2]} @topDelts){
   my $dr=abs($_);
   $max = $dr if $dr > $max;
   $min = $dr if $dr < $min;
}



#############
# Colorize
# and output
#############

# undo all the stats work if we have spectrum max/mins
$max = $opts{S} if exists $opts{S};
$min = $opts{s} if exists $opts{s};

# set step  
my $colorstep = ($max-$min)/$numColors;

#draw the line
for my $cor (@topDelts) {
 # red is positive, blue is negative
 my $sign='RedYellow';
 $sign='WhiteBlue' if $cor->[2] < 0;

 ## set color
 # delta-min/steps ==> where in spectrum value is
 my $coloridx = int((abs($cor->[2])-$min)/$colorstep);
 # sometimes we go over
 $coloridx=$numColors if $coloridx > $numColors;
 # get rgb given a color idx
 my @rgb = @{@{$color{$sign}}[ $coloridx  ]};

 # print endpoints (both cords) color (r g b) opacity and width
 print $output join(" ",@{$cor}[0,1], @rgb, 1, $opts{l}),"\n";
}
close $output;

################
#### Stats #####
################

sub getStats {
 # get new stats if we have an array to wrok on
 if (@_ != 0) {
  $stat = Statistics::Descriptive::Full->new();
  $stat->add_data(map {$_->[3]} @_); 
 }

 # count and map all stats to .3f
 return  ($stat->count, 
         map {sprintf "%.3f",$_}  
           ($stat->max, $stat->min, $stat->mean, 
            $stat->standard_deviation, $stat->variance
           )
         );
}

print "Distance\n",
      join ("\t", qw/set count max min mean std_dev variance/),"\n",
      join ("\t", "all"  , getStats()          ),"\n",
      join ("\t", "excld", getStats(@deltRs)   ),"\n",
      join ("\t", "Top"  , getStats(@topDelts) ),"\n";

print "R\n",
      join("\t", qw/Top min max/),"\n",
      join("\t", $#topDelts+1, 
                 map {sprintf "%.4f", $_} ($min, $max)
          ),"\n";

print "\nexcluded $OutOfRange based on range qualifications\n";

print "\nColor\n";
print "$numColors colors  [", join(":", map {sprintf "%.4f",$_} ($min,$colorstep,$max)), "]\n";
for my $spect (qw/RedYellow WhiteBlue/) {
 print "$spect ";
 #print( (map { sprintf "%02x", $_*256 } @{@{$color{$spect}}[$_]})," ") for (0, $#{$color{$spect}});
 print( (map { sprintf "%4i", $_*256 } @{@{$color{$spect}}[$_]})," ") for (0, $#{$color{$spect}});
 print "\n";
}
print "\n";

# create an SVG object
open my $svgOut, ">$filename.svg" or die "cannot open svgout:$!\n";
use SVG;
my ($swidth, $sheight) = (100, 200);
my $svg  = SVG->new(width=>$swidth,height=>$sheight);
my $step = $sheight/$numColors;
my $spect = 'RedYellow';
for my $cidx (0.. $numColors-1){
my $ypos = $cidx*$step;

$svg->rectangle(
      id=>"rect_$cidx", x=>40, width=>$swidth-40, y=>$ypos, height=>$step+1,
      'stroke'=>"none",
      'fill'=> "rgb(".join(',', map {$_*256} @{@{$color{$spect}}[$cidx]}).")"
      #'style' => 'stroke:none;fill:#ff0000;fill-opacity:1'
     );
#only show what value is top, middle, and bottom
if ( $cidx == 0 || $cidx == $numColors-1 || $cidx == int(($numColors-1)/2) ) {
   $svg->text( id=>"text_$cidx", x=>1,  y=> $ypos +($ypos>=$step?0:12) )->cdata(sprintf "%.4f" , $min+$colorstep*$cidx);
}

}
print $svgOut $svg->xmlify;
close $svgOut;




##################
# Suma stuff
#
# want to display (using currently opened suma)
if (exists $opts{d}) {

   my $cmd=<<CMDEND;
     f=\$(ls -tc .tmp* 2>/dev/null|sed 1q); 
     [ -n "\$f" ] && cp "$filename" "\$f" \\
     && DriveSuma -echo_edu -com viewer_cont -load_do "\$f"   
CMDEND

   system("$cmd");

   ## print nodes
   # index nodes
   my %topnodes;
   for my $i (@topDelts) {
    $topnodes{$i->[$_]}++ for (0,1);
   }
   open $output, ">.tmpROISpheres.niml.do" or die "cannot open '>.tmpROISpheres.niml.do': $!\n";
   print $output "<nido_head default_color='1 1 1' />\n";
   print $output "<S coord='$_' coord_type='fixed' rad='1' />\n" for (keys %topnodes);

   close $output;
   $filename =~ s/\.do/.spheres.niml.do/;
   system("cp .tmpROISpheres.niml.do $filename");
   system("DriveSuma -echo_edu -com viewer_cont -load_do .tmpROISpheres.niml.do");
} else {
# don't want to display, but tell how to

   print "DriveSuma -echo_edu -com viewer_cont -load_do $filename\n";
}

