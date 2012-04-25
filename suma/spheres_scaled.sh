#!/bin/bash

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



echo "Rescaling values from ${olow} -- ${ohigh} to ${rlow} -- ${rhigh}"

echo "<nido_head default_color='1 1 1' />" > ${outfile}

#note that rescaling is applied based on all data in the scale_file, not just L/R if requested

paste ${coord_file} ${scale_file} | while read x y z roinum scale; do
    [[ $x -lt 0 && ${hemi} == "r" ]] && continue
    [[ $x -gt 0 && ${hemi} == "l" ]] && continue

    #rescale
    scale=$( echo "scale=5; (($rhigh - $rlow)*($scale - $olow))/($ohigh - $olow) + $rlow" | bc )
    echo "<S coord='${x} ${y} ${z}' coord_type='fixed' rad='${scale}' />" >> ${outfile}
done
