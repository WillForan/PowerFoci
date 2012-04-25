#!/bin/bash
set -e

echo "Num arguments: $#"
if [ $# -lt 2 ]; then
    echo "Usage: spheres_scaled.sh coord_file scale_file <output_niml.do> <hemisphere=lr> <olow=min> <ohigh=max> <rlow=1> <rhigh=5>"
    exit 1
fi

coord_file="$1"
scale_file="$2"
if [ ! -f "$coord_file" ]; then
    echo "Coordinate file not found: ${coord_file}"
    exit 1
fi

if [ ! -f "$scale_file" ]; then
    echo "Scale file not found: ${scale_file}"
    exit 1
fi

#determine whether scale_file has second column denoting color mapping
numCols=$( awk 'NR==1{print NF}' "$scale_file" )

if [ $numCols -gt 2 ]; then
    echo "Unrecognized format for scale_file: $scale_file"
    exit 1
fi

outfile="scaledSpheres.niml.do"
if [ -n ${3} ]; then
    outfile="${3}"
fi

hemi="lr"
if [ -n ${4} ]; then
    hemi="${4}"
    hemi=$(echo ${hemi} | tr '[A-Z]' '[a-z]')
fi

xrange=($( cat "$scale_file" | sort -n | awk 'NR==1{print $1};END{print $1}' ))
olow=${xrange[0]}
ohigh=${xrange[1]}
rlow=1
rhigh=5
[[ $# -ge 5 && "${5}" != "min" ]] && olow="${5}"
[[ $# -ge 6 && "${6}" != "max" ]] && ohigh="${6}"
[ $# -ge 7 ] && rlow="${7}"
[ $# -ge 8 ] && rhigh="${8}"

#define colormap: using "Set3" from Color Brewer: http://colorbrewer2.org/
#will support up to 12 coloration values
colors=("141 211 199" \
    "255 255 179" \
    "190 186 218" \
    "251 128 114" \
    "128 177 211" \
    "253 180 98" \
    "179 222 105" \
    "252 205 229" \
    "217 217 217" \
    "188 128 189" \
    "204 235 197")

#echo ${#colors}

#remapcols=($( for ((c=0; c < ${#colors}; c++)); do echo "${colors[$c]}" | perl -slane 'print qw/"/, join("_", map {sprintf("%.4f", $_/255)} (@F)), qw/"/'; done ))
remapcols=($( for ((c=0; c < ${#colors}; c++)); do echo "${colors[$c]}" | perl -slane 'print join("_", map {sprintf("%.4f", $_/255)} (@F))'; done ))

#IFS="_"
#echo ${#remapcols[*]}
#echo ${remapcols[0]}
#echo ${remapcols[1]}
#exit 1

echo "Rescaling values from ${olow} -- ${ohigh} to ${rlow} -- ${rhigh}"

#note that rescaling is applied based on all data in the scale_file, not just L/R if requested

if [ $numCols -eq 1 ]; then
    echo "<nido_head default_color='1 1 1' />" > ${outfile}
    paste ${coord_file} ${scale_file} | while read x y z roinum scale; do
	[[ $x -lt 0 && ${hemi} == "r" ]] && continue
	[[ $x -gt 0 && ${hemi} == "l" ]] && continue

        #rescale
	scale=$( echo "scale=5; (($rhigh - $rlow)*($scale - $olow))/($ohigh - $olow) + $rlow" | bc )
	echo "<S coord='${x} ${y} ${z}' coord_type='fixed' rad='${scale}' />" >> ${outfile}
    done
elif [ $numCols -eq 2 ]; then
    echo "<nido_head default_color='0 0 0' />" > ${outfile}
    paste ${coord_file} ${scale_file} | while read x y z roinum scale col; do
	[[ $x -lt 0 && ${hemi} == "r" ]] && continue
	[[ $x -gt 0 && ${hemi} == "l" ]] && continue

        #rescale
	scale=$( echo "scale=5; (($rhigh - $rlow)*($scale - $olow))/($ohigh - $olow) + $rlow" | bc )
	#oldIFS="${IFS}"
	#IFS="_"
	#thisCol=$( echo ${remapcols[$col]} | sed 's/_/ /g' | sed 's/"//g' )
	thisCol=$( echo ${remapcols[$col]} | sed 's/_/ /g')
	#echo "<S coord='${x} ${y} ${z}' coord_type='fixed' rad='${scale} col='${remapcols[$col]}' />" >> ${outfile}
	#echo "<S coord='${x} ${y} ${z}' coord_type='fixed' rad='${scale}' col='${thisCol}' style='fill' stacks='20' slices='20' line_width='1.5' />" >> ${outfile}
	echo "<S coord='${x} ${y} ${z}' coord_type='fixed' rad='${scale}' col='${thisCol}' />" >> ${outfile}
	
	#IFS="${oldIFS}"
    done
fi