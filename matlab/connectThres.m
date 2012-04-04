%%%%
%
%% Plot top 1% of absolute change in r for adj_bpreg_{robust,scrapped}
%
%%%%


%% pull in ajd_bpreg* and bb265coordinate
if (~ exist('bb264coordinate', 'var') )
    load adjmat_stats
end

%% set up an object so the bpreg types can be loop
pipe.bpregs.Normal    = adj_bpreg;
pipe.bpregs.Robust   = adj_bpreg_robust;
pipe.bpregs.Scrapped = adj_bpreg_scrapped;

pipe.simult.Normal    = adj_simult;
pipe.simult.Robust   =  adj_simult_robust;
pipe.simult.Scrapped =  adj_simult_scrapped;


% What graphs to calc/show
pipes = {'bpregs' 'simult'   'Diff'};
type  = {'Robust'  'Scrapped' 'Diff'};

% What percent of data?
percent=1;

%% for all pipes
for p=1:length(pipes);
    %% for both Robust and Scrapped
    for t=1:length(type)
        %% set up matrix to work on

        %  o  get delta R
        %  o  discard duplicate pairing by taking the lower triangle
        %  x  and removing(=0) the diagonal

        pipeA = pipes{p};
        pipeB = pipes{p};
        methA = 'Normal';
        methB = type{t};
        
        % type == diff means don't use normal as base
        if(strcmp('Diff',type{t}))
            methA = 'Scrapped';
            methB = 'Robust';
        end
        
        if(strcmp('Diff',pipes{p}))
            % don't do Diff/Diff -- doesn't say much to compare methods in
            % diff pipes
            % so instead do Normal vs Normal
            if(strcmp('Diff',type{t})); methB='Normal'; end
            
            pipeA = 'bpregs';
            pipeB = 'simult';
            methA = methB;
            
        end


        lowerTri = tril( pipe.(pipeA).(methA) - pipe.(pipeB).(methB)  );
        

        %lowerTri( logical( diag( 1:msize ) ) ) = 0; %should already be 0

        % bpregs.(type{1}) is the adj matrix for the given type
        % this size should be the same as bb256cords, 264
        msize = length( pipe.(pipeB).(methB) );


        %% get the top $percent% 
        [~,absort] = sort( abs( lowerTri(:) ) );
        absTop     = absort(end-ceil(percent*end/100):end);


        %% set up plot
        % with all roi coors in black
        figure;
        axis([-90,90,-90,90,-90,90]);
        plot3(bb264coordinate(:,1),bb264coordinate(:,2),bb264coordinate(:,3),'k.')
        hold on;

        % init distance var for ploting later
        distance      = zeros(length(absTop),2);
        threeDistance = zeros(length(absTop),4);

        % counter -- used to fill matrix for eucli. dist plot
        c=1;

        %% define a color spectrum 
        deltRmax=max(lowerTri(absTop));
        deltRmin=min(abs(lowerTri(absTop)));

        colorspectrum=jet;
        colormap(colorspectrum);
        caxis([deltRmin,deltRmax]);
        colorbar;

        colorstep=(deltRmax-deltRmin)/length(colorspectrum);

        RRdRFile = fopen(['roiRoiDeltR_' pipeA methA 'VS' pipeB methA,'.txt'],'w');
        %% for each of the top 1%
        for i=absTop'
            %% get the row and col
            row = ceil(i/msize);
            col = mod(i,msize);
            if col==0; col = msize; end

            %% get corresponding coordinates
            cor1 = bb264coordinate(row,1:3);
            cor2 = bb264coordinate(col,1:3);
            linecors=[cor1;cor2];

            %% plot line
            l=line(linecors(:,1),linecors(:,2),linecors(:,3));


            %% use colors to show cor. change
            % set the color based on value of delta R

            coloridx = floor( (abs(lowerTri(i)) - deltRmin)/colorstep);
                 
            % don't go out of bounds!
            if coloridx < 1; coloridx=1; end
            if coloridx > length(colorspectrum); coloridx=length(colorspectrum); end
            
            set(l,'Color', colorspectrum(coloridx,:));


            % change marker and style based on corrilation direction
            if(lowerTri(i) > 0 );
               set(l,'LineStyle','-','Marker','.');
            else
               set(l,'LineStyle','--','Marker','o');
            end

            %% make list of roi-roi deltR 
            fprintf(RRdRFile,'%i %i %f\n', col, row, lowerTri(i));

            %% build matrix for euclid dist graph

            distance(c,:)      = [lowerTri(i),pdist(linecors)];

            threeDistance(c,:) = [       ...
                abs(cor1(1) - cor2(1) )  ...
                abs(cor1(2) - cor2(2) )  ...
                abs(cor1(3) - cor2(2) )  ...
                lowerTri(i)              ...
            ];

            % increment counter
            c=c+1;

        end


        %% give a title and label
        title( [pipeA ':' methA ' - ' pipeB ':' methB] );
        xlabel('x');ylabel('y');zlabel('z');

        %% save distances for eculd dist graph
        dist.(type{t})      = distance;
        threeDist.(type{t}) = threeDistance;


    end
    
    %%%% plot euclian distance
    figure
    colors={'ko','bx','r.'}; %black circle and blue x
    title([pipeA ':' pipeB ' Top ',num2str(percent),'% \Delta r against distance']);
    axis([-.2,.2,0,180]);
    xlabel('\Delta r'); ylabel('euclidian dist');
    hold on;

    for t=1:length(type) 
        distance=dist.(type{t});
        plot(distance(:,1),distance(:,2),colors{t});
    end
    legend(type{1:length(type)},'Location','NorthEastOutside');
end



%% show change in r based on distance for each axis
%
% t=2;
% figure
% caxis([  min(threeDist.(type{t})(:,4)) ...
%          max(threeDist.(type{t})(:,4)) ...
%      ]);
%  
% a=scatter3(                          ...
%            threeDist.(type{t})(:,1), ... 
%            threeDist.(type{t})(:,2), ... 
%            threeDist.(type{t})(:,3), ...
%            10,                        ...
%            threeDist.(type{t})(:,4), ...
%            'filled'                  ...
%            );
% colorbar;
% title(['Top ' num2str(percent) ' %{\Delta}r ' type{t} ]);

