% display a brain!

%load_nii from http://www.mathworks.com/matlabcentral/fileexchange/8797
img=load_nii('MNI152_T1_2mm_brain_mask.nii');
brain=double(img.img);

%code from http://soundsfromthenorth.com/?p=3
%img.img is 91x109x91
[xsize,ysize,zsize]=size(img.img);
prev=0;
p=[];

% find edges
% v is 0 or 1
% only care about edges (changes in v<->prev) 
for x=1:xsize;
   for y=1:ysize;
      for z=1:zsize;
         v=brain(x,y,z);
         
         if(                                   ...
             prev~=v &&                          ... % there must be a change
              (                                 ...
                isempty(p) ||                   ... % always take the first
                (pdist([x y z;p(end,:)]) > 20   ... % skip if too close
                 || max([x y z] - p(end,:) > 10))... % in any dim
              )                                 ...
            )
            p = [p; x y z];
            prev=v;
         end

      end
   end
end


% downsample -- take 5x fewer points
% use pdist computation in for loop instead
% p=p(1:5:end,:);

% brain is 2mm so multiply positions by 2
p = p .* 2;

% and then recenter
%  assume dimensions are symetric
%  and the meadian value should be zero
for dim=1:3
    p(:,dim) = p(:,dim)  - median( p(:,dim) );
end



%MyRobustCrust from http://code.google.com/p/atlasnavigator/
[t,tnorm]=MyRobustCrust(p);
h=trisurf( t,p(:,1),p(:,2),p(:,3),   ...
           'facealpha',0.4,          ...
           'facecolor',[.7 .7 .7],   ...
           'edgecolor',[.8 .8 .8]    ...
         );
% view(3);
% axis vis3d
