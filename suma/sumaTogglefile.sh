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
files=( $(ls -1 $glob) empty)
# count of all files+empty so exit can be the last thing
last=${#files[@]}

# can we do anything?
[ $last -lt 2 ] && echo "No files matched $1." && helper
 
# specfile not set? set it
[ -z "$specFile" ] && specFile=~/standard/suma_mni/N27_both.spec

# run suma if it's not already running
[ -z "$(ps x -o command | grep ^suma)" ] && xterm -e "suma -spec $specFile -niml" &

#make the temp file and store it's location
temp="$(mktemp .tmpXXX.niml.do)"

# while the universe exists
while : ; do
   # redo file list every new selection attempt
   files=( $(ls -1 $glob) empty)
   last=${#files[@]}

   # enumerate files
   count=0
   for f in ${files[*]} "exit"; do 
     echo -e "$count:\t$f"|sed "s:$(pwd)/::";
     let count++
   done

   # prompt and capture file choice
   echo -n "reponse: "; read response

   # handle choice oddnes
   [ -z "$response" ] && break                                        # ctrl-d
   [ "$response" -ge 0 -o "$response" -lt 0 2>&-  ] 2>&- || continue  # not a number 
   [ $response -eq $last ] && break                                   # stop if choose exit 
   [ $response -gt $last -o $response -lt 0 ] && \
     echo "oops? $response not in range!"     && \
     sleep 1 && continue                                              # number is too big or too small

   # assume trying to copy empty is going to fail 
   # or that empty is actually an empty file
   cp -f "${files[$response]}" "$temp" 2>/dev/null || echo -e "#spheres\n0 0 0 0 0 0 0" > $temp

   # load the temp file in display
   DriveSuma -echo_edu -com viewer_cont -load_do "$temp"
done

# clean up 
rm $temp
