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


# make path absolute glob after dir will still mess it up (e.g. if vis/, vis* won't work)
path=$1; [ -d "$path" ] && path="$path/*"
append=""; [[ "$path" =~ ^/ ]] || append="$(pwd)/"  

# get all files matching input + empty
files=($(ls -1 $path) empty.1D empty.niml.do)
# count of all files+empty so exit can be the last thing
last=${#files[@]}

# can we do anything?
[ $last -lt 2 ] && echo "No files matched $1." && helper
 
# specfile and subject volume not set? set it
[ -z "$specFile" ] && specFile=~/standard/suma_mni/N27_both.spec          # ziad's
#[ -z "$specFile" ] && specFile=~/standard/colin27/SUMA/colin27_both.spec # michael's
echo using specfile $specFile

# do we want to tie to afni?
if [ -n "$AFNI" ]; then
   # set nifti file
   [ -z "$afniFile" ] && afniFile=~/standard/suma_mni/MNI_N27+tlrc # ziad's
   #[ -z "$afniFile" ] && afniFile=~/standard/colin27/SUMA/brain.nii    # michael's
   echo using afni $afniFile

   # run suma linked to afni
   additSuma="-sv $afniFile"

   # run afni
   xterm -e "afni -niml $afniFile" &
fi

# run suma if it's not already running
[ -z "$(ps x -o command | grep ^suma)" ] && xterm -e "suma -niml -spec $specFile $additSuma" & 
# run afni?

#make the temp file and store it's location
temp="$(mktemp .tmpXXX.niml.do)"

# while the universe exists
while : ; do
   # redo file list every new selection attempt
   files=($(ls -1 $path|sed -e "s:^:$append:") empty.1D empty.niml.do)
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

   # assume there aren't files named empty*
   # or that empty is actually an empty file so it doesn't matter
   case ${files[$response]} in 
    empty.1D )
      echo -e "#segment\n87 -120 108 87 -120 108 0 0 0 0 0" > $temp ;;
    empty.niml.do )
      echo -e "<nido_head />" > $temp ;;
    * )
      #cp or make an empty.1D
      cp -f "${files[$response]}" "$temp" 2>/dev/null || echo -e "#segment\n87 -120 108 87 -120 108 0 0 0 0 0" > $temp
   esac

   # load the temp file in display
   DriveSuma -echo_edu -com viewer_cont -load_do "$temp"
done

# clean up 
rm $temp
