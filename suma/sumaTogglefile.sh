#!/usr/bin/env bash

##
# make common temp file to replace load Displayable Objects in suma
#
# first argument is glob/wildcard matching files to toggle in suma
##

[ -z "$1" ] && echo "No arguments? I'll list current folder, is that what you want?"

# is suma running?
specFile=/home/foranw/src/PowerFoci/suma/suma_mni/N27_both.spec
[ -z "$(pgrep suma)" ] && xterm -e "suma -spec $specFile -niml" &

temp=$(mktemp)
# get all files matching input + empty
files=( $(ls -1 $1) empty)
# count of all files+empty so exit can be the last thing
last=${#files[@]}

# can we do anything?
[ $last -lt 2 ] && echo "No files matched $1." && exit

# while the universe exists
while : ; do
   # enumerate files
   count=0
   for f in ${files[*]} "exit"; do 
     echo -e "$count:\t$f";
     let count++
   done

   # prompt and capture file choice
   echo -n "reponse: "; read response
   # stop if choose exit, or bad input (e.g. error in numeric compare, number too big )
   [ $response -lt $last ] || break

   # assume trying to copy empty is going to fail 
   # or that empty is actually an empty file
   cp -f "${files[$response]}" "$temp" || echo -e "#spheres\n0 0 0 0 0 0 0" > $temp

   # load the temp file in display
   DriveSuma -echo_edu -com viewer_cont -load_do "$temp"
done

# clean up 
rm $temp
