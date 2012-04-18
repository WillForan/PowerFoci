#!/usr/bin/env bash

##
#  
# USEAGE: sumaTogglefile.sh  <'*.do.1D'>
#    e.g. ./sumaTogglefile.sh 'vis/*.do.D1'
# 
#    first argument is glob/wildcard 
#    matching files to toggle in suma
#    
#    to use a spefile
#    specFile=my.spec ./sumaTogglefile.sh
# 
#
# * make reused temp file 
# * list files matching DOwildcard
# * replace/load selected Displayable Objects file
#
##END
function helper { 
 sed -n 's/# //p;/##END/q' $0;
 exit 
}

[ -z "$1" -o -n "$2" ] && echo -e "***
Bad arguments? Try ./ for current dir
make sure *,{},etc are trapped/escaped (e.g '*DO' not just *DO)
if matching two globs, put both in same quote pair ('*DO *do')
***" 1>&2 && helper


# make path absolute
glob="$1"
[[ "$glob" =~ "^\/" ]] || glob="$(pwd)/$1"

# get all files matching input + empty
files=( $(ls -1 $1) empty)
# count of all files+empty so exit can be the last thing
last=${#files[@]}

# can we do anything?
[ $last -lt 2 ] && echo "No files matched $1." && helper
 
# specilfe not set? set it
[ -z "$specFile" ] && specFile=~/src/PowerFoci/suma/suma_mni/N27_both.spec

# can we tell if suma is running, is it running?
[ -n "$(which pgrep)"  ] && [ -z "$(pgrep suma)" ] && xterm -e "suma -spec $specFile -niml" &

#make the temp file and store it's location
temp="$(mktemp .tmpXXX)"

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
   cp -f "${files[$response]}" "$temp" 2>/dev/null || echo -e "#spheres\n0 0 0 0 0 0 0" > $temp

   # load the temp file in display
   DriveSuma -echo_edu -com viewer_cont -load_do "$temp"
done

# clean up 
rm $temp
