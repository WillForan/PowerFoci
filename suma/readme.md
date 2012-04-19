# Viewing coorilation changes
## Example
    ./segment.pl -r ../matrix/top30Low.adjlist -t 600 -m 30 -M 70 -p vis/30Low
    ./sumaTogglefile.sh 'vis/30*'
    [select number referencing 'vis/30Low-T600Dm30M70.dset.do']

with `sumaTogglefile.sh` still running, using `./segment.pl ... -d` will replace suma DOs with the newly created file.


## Requires
* list of xyz coordinates of ROIs with ROI id (for adjacency list) (orderd x y z roiID, expect delm. [,\s]+ )
    * bb244
    * bb264
* change in correlation between ROIs as matrix or adjacency list
    * ../matrix/top30Low.adjlist
    * ../matlab/txt/*.txt

## segment.pl
* (-r) provide adjacency list or matrix files and optionally number of segments (-t), min r (-m), and/or max r (-M)
* writes to vis/compare...

## sumaTogglefile.sh 'vis/*'
* open suma 
* list menu with all files in vis
* display chosen item


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
## old/view.sh ##

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

## old/segments*.pl ##

* pulls from `../matlab/txt/*txt`, the text ouptut of `../matlab/connectThres.m` (top 1%)
* further restrict to only 300 top corrilation changes
* uses `colors/rgbWhite{Blue,Red}.spec` for ad-hoc spectrum



