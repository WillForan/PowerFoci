# SUMA visualize  #

<table><tr><td>
 Between pipelines: R_bpreg - R_simult for normal
 </td><td>
 Within pipeline: R_normal - R_scrapped for bpreg </td></tr>
 <tr><td>
 <img src="https://github.com/WillForan/PowerFoci/raw/master/suma/pics/betweenPipe-rotate.gif">
 </td><td>
 <img src="https://github.com/WillForan/PowerFoci/raw/master/suma/pics/withinPipe-rotate.gif">
 </td></tr>
</table>
## view.sh ##

brings up two suma windows 

* delt r: bpregs vs simult (Normal)  
* delt r: normal vs scrapped (bpreg) 

viewing

* `vis/*do` segments created from `../matlab/txt/*txt` in form of `roi1 roi2 deltaR` by `segments_xyz.pl`
* and nodes from `create_xyz.sh`

suma cortical surface is from the specfile `suma_mni/N27_both.spec`

## create*.sh ##

uses roi from Power et al: `../b264_bp_robust_scrapped.txt`. Clustered from Kai''s matlab output

* create.sh uses  `SurfaceMetrics -closest_node` to put coords on mesh
    * losses 15 on the rh to subcoritical areas 
        * `viewMatchMismatch_do.sh` to visualize 
    * use create_xyz.sh instead, but cannot change views (e.g. flat)

## segments*.pl ##

* pulls from `../matlab/txt/*txt`, the text ouptut of `../matlab/connectThres.m` (top 1%)
* further restrict to only 300 top corrilation changes
* uses `colors/rgbWhite{Blue,Red}.spec` for ad-hoc spectrum



