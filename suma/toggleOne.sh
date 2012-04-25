#!/usr/bin/env bash

##
#  
# USEAGE: ./toggleOne.sh  -d DOfile [-t tempfile] [-s specfile] [-v volume (implies -a)] [-a] [-e] [-c]
#    ./toggleOne.sh vis/hemi.dset.do                 # display vis/hemi... in suma
#    ./toggleOne.sh -t tmp.niml.do vis/hemi.dset.do  # use alternative (not .tmptoggleOne.niml.do)  temp file
#    ./toggleOne.sh -e                               # empty all .tmp* and rm them
#    ./toggleOne.sh -t tmp.niml.do -e                # empty tmp.niml.do and all .tmp* and rm them
#    ./toggleOne.sh -a  vis/hemi.dset.do             # display in afni too
# 
# * use temp file to display and toggle DO in suma
# * by default uses most recent temp file or .tmptoggleOne.niml.do
# * -c (color spectrum)  will try to find DOfile.svg and display it
#
##END
function helper { 
 sed -n 's/# //p;/##END/q' $0;
 exit 
}


while getopts "t:s:v:d:aceh?" opts; do
 case $opts in
  "d")    input=$OPTARG ;; # DO file to use
  "t")     temp=$OPTARG ;; # temp file to use
  "s") specFile=$OPTARG ;; # spec file to use
  "v") afniFile=$OPTARG; AFNI=1 ;; # volume to use
  "a")     AFNI=$OPTARG ;; # use afni? 
  "c")    color=1       ;; # try to display color spectrum
  "e")                     # empty everything!
      for tmp in $temp .tmp*; do
         [ ! -r $tmp ] && echo "nothing to empty!" && break
         echo $tmp
         echo -e "#segment\n87 -120 108 87 -120 108 0 0 0 0 0" > $tmp 
         DriveSuma -com viewer_cont -load_do "$tmp"
         echo -e "<nido_head />" > $tmp 
         DriveSuma -com viewer_cont -load_do "$tmp"
         rm $tmp
      done
      exit; # nothing left to do
   ;;
    *) helper ;;
 esac
done

# whats the input file
[ -z "$input" ] && input=$1   # risky short cut
[ -z "$input" -o ! -r "$input" ] && echo "Cannot read DOfile" && helper

# set temp file name if not given by -t 
[ -z "$temp" ] && temp=$(ls -c1 .tmp* 2>/dev/null|sed -e '1q') # not given a temp file
[ -z "$temp" ] && temp=".tmptoggleOne.niml.do" # not given temp file and none in current directory

echo "copying to $temp"
 
# specfile and subject volume not set? set it
[ -z "$specFile" ] && specFile=~/standard/suma_mni/N27_both.spec          # ziad's

echo using specfile $specFile

# do we want to tie to afni?
if [ -n "$AFNI" ]; then
   # set nifti file
   [ -z "$afniFile" ] && afniFile=~/standard/suma_mni/MNI_N27+tlrc        # ziad's

   echo using afni $afniFile

   # run suma linked to afni
   additSuma="-sv $afniFile"

   # run afni
   xterm -e "afni -niml $afniFile" &
fi

###### color?
if [ -n "$color" ]; then
 [ -r $input.svg ] && display $input.svg &
fi


###### display

# run suma if it's not already running
[ -z "$(ps x -o command | grep ^suma)" ] && xterm -e "suma -niml -spec $specFile $additSuma" & 

# copy to temp
cp -f "$input" "$temp"

# run in suma
DriveSuma -com viewer_cont -load_do "$temp"

# clean up 
#rm $temp
