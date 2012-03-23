% display a brain!

img=load_nii('MNI152lin_T1_2mm_brain_mask.nii');
brain=double(img.img);
prev=0;
p=[];
for x=1:91;
   for y=1:109
      for z=1:91;
         v=brain(x,y,z);
         if(prev~=v)
            p=[p; x y z];
         end
            prev=v;
      end
   end
end

[t,tnorm]=MyRobustCrust(p);
figure(1)
hold on
axis equal
h=trisurf( t,p(:,1),p(:,2),p(:,3),   ...
           'facealpha',0.4,          ...
           'facecolor',[1 1 1],      ...
           'edgecolor',[0.8 0.8 0.8] ...
         );
view(3);
axis vis3d
