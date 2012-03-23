Explore differences in preprocessing pipelines

# Visualize #
see matlab/connectThres.m for colorized connections
![Scrapped Pipeline vs bpregres](https://github.com/WillForan/PowerFoci/raw/master/matlab/scrapped.jpg)
dashed circle is negative change. solid dot is positive change. Top 1% shown.

# Cluster #
see countCompare.pl for percent identities

# Vizualize Foci in Caret # 
see generateFoci.sh for generating color and foci file to be imported into caret

## Using Caret ## 
* Load spec file: standard_mesh_atlas/Left...
* Load spec file: standard_mesh_atlas/Right.., select "Keep ..."
* Open Data: load .foci and .focicolor
	* if foci are on "Left" all will be shown
* Layers -> Foci -> Map Sterotacix Foci
	* pretend to edit a foci 
	* click map to surface (PALS doesnt work? -- need to figure out study linking)
	* Apply


# Visiualize Foci in AFNI #
see withAFNI/createSpheres.sh for generating sheres.
