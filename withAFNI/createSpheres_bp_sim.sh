#!/usr/bin/env bash
for type in {5,6}; do
   case $type in
      5) name=bpreg  ;;
      6) name=simult ;;
   esac

   3dUndump  -xyz -srad 7 -overwrite                          \
             -prefix mask_${name}.nii.gz                      \
             -master mni_icbm152_t1_tal_nlin_asym_09c_2mm.nii \
             <(awk -F,  '{print $1,$2,$3,$'$type'}'           \
                        ../matrix/bb244_communities_bpreg_simult-corrected.csv)
           
done
