#!/usr/bin/env bash

#########################
# build foci file
#  awk -F, '{print $4 $1 $2 $3 $5}' b264_bp_robust_scrapped.txt | $0 > reg.foci
#  awk -F, '{print $4 $1 $2 $3 $6}' b264_bp_robust_scrapped.txt | $0 > robust.foci
#  awk -F, '{print $4 $1 $2 $3 $6}' b264_bp_robust_scrapped.txt | $0 > scrapped.foci
# 
# pipe in or give as input
# IFS seperated
# name, x, y, z, and class
#####################

#while getopts
projectID="ProjID20120322104451400000"

# print header
cat <<EOD
CSVF-FILE,0,,,,,,,,,,,,,,,,,,,,,,,,,
csvf-section-start,header,2,,,,,,,,,,,,,,,,,,,,,,,,
tag,value,,,,,,,,,,,,,,,,,,,,,,,,,
Caret-Version,5.65,,,,,,,,,,,,,,,,,,,,,,,,,
Date,2012-03-22T10:55:42,,,,,,,,,,,,,,,,,,,,,,,,,
comment,,,,,,,,,,,,,,,,,,,,,,,,,,
encoding,COMMA_SEPARATED_VALUE_FILE,,,,,,,,,,,,,,,,,,,,,,,,,
csvf-section-end,header,,,,,,,,,,,,,,,,,,,,,,,,,
csvf-section-start,Cells,27,,,,,,,,,,,,,,,,,,,,,,,,
Cell Number,X,Y,Z,Section,Name,Study Number,Geography,Area,Size,Statistic,Comment,Structure,Class Name,SuMS ID Number,SuMS Repeat Number,SuMS Parent Cell Base ID,SuMS Version Number,SuMS MSLID,Attribute ID,Study PubMed ID,Study Table Number,Study Table Subheader,Study Figure Number,Study Figure Panel,Study Page Reference Number,Study Page Reference Subheader
EOD

# for each x y and z print
index=-1
while read name x y z class; do
   let index++
   #echo "$index,$x,$y,$z,-1,$name,-1,,,0.000000,,,left,$class,-1,-1,-1,-1,-1,-1,$projectID,,,,,,"
   #echo "$index,$x,$y,$z,-1,$name,-1,,,0.000000,,,Correct Structure Only,$class,-1,-1,-1,-1,-1,-1,$projectID,,,,,,"
   echo "$index,$x,$y,$z,-1,$name,-1,,,0.000000,,,,$class,-1,-1,-1,-1,-1,-1,$projectID,,,,,,"
done

cat <<EOD
csvf-section-end,Cells,,,,,,,,,,,,,,,,,,,,,,,,,
EOD
#cat <<EOF
#csvf-section-start,Cell Study Info,10,,,,,,,,,,,,,,,,,,,,,,,,
#Study Number,Stereotaxic Space,Keywords,URL,Title,Authors,Citation,Comment,Partitioning Scheme Abbreviation,Partitioning Scheme Full Name,,,,,,,,,,,,,,,,,
#0,FLIRT,,,PowerBP,,,,,,,,,,,,,,,,,,,,,,
#1,MRITOTAL,,,PowerBP,,,,,,,,,,,,,,,,,,,,,,
#csvf-section-end,Cell Study Info,,,,,,,,,,,,,,,,,,,,,,,,,
#EOF
