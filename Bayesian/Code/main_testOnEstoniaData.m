function [bstMean, bstMedian, tWin2Test, meanErr, medianErr, animalStruct] = main_testOnEstoniaData( )
%MAIN_TESTONESTONIADATA Test decoding accross different time windows
% Note decXY and trueXY are only returned for the last animal run


% --- VARS ----------------------------------------------------------------
%Specify the time windows to use in seconds
tWin2Test       =0.2 : 0.2: 4;


%Specify cross validation to use 0.1 for 10% test set or 0.02 for 2%
%(50fold)
cValid          =0.1; %[0.1]

%Specify window overlap (0 to <1) specify proportion of window to overlap
% note this is fixed at half the window
tBinOverlap    = (tWin2Test*0.5)./tWin2Test; 



% --- TRIALS AND TETS TO LOAD ---------------------------------------------
dataDir         ='/home/deepmind/projects/RatGPS/Bayesian/Data/'; %will append
%Specify trials to load and tets to use - not note usiing r2335 and r2142
%due to too few cells
%Screening open field

% for 2D uncomment the following block (lines 29 to 36)
% Now specify file name, tetrode to use and PPM
isZmaze       =false;
fileTet         ={
    'R2192 - screening/20141001_R2192_screening', [9,10,11,12,13,14,15,16], 350;
    'R2198 - screening/20140920_R2198_screening', [9,10,12,13,14,16], 359;
    'R2217 - screening/20141218_R2117_screening', [9,10,11,12,13,14,15], 349;
    'R2336 - screening/20151104_R2336_screening', [9,10,11,12,13,14,15,16], 373;
    'R2337 - screening/20151127_R2337_screening', [9,10,11,12,13,14,15,16], 378
    };


% for 1D uncomment the following block (lines 45 to 60)
% 1D Track - z maze
% REMEMBER we now exlude first 25s of linear track trial - set in
% decodeCrunch
% Note true PPM of the z-maze is 324 but when using linearised this changes
% to 100 since scale is in cm
%isZmaze         =true;
%fileTet         ={
%    'R2192 - track/20140110_R2192_track1', [9,10,11,12,13,14,15,16], 100;
%    'R2198 - track/20140920_R2198_track1', [9,10,12,13,14,15,16], 100;
%    'R2217 - track/20141218_R2217_track1', [9,10,11,13,14,15], 100;
%    'R2336 - track/20151104_R2336_track1', [9,10,11,12,13,14,15,16], 100;
%    'R2337 - track/20151127_R2337_track1', [9,10,11,12,13,14,15,16], 100
%    };
% 
%fileMat         ={
%    'R2192 - track/cbLinearisedPos_R2192';
%    'R2198 - track/cbLinearisedPos_R2198';
%    'R2217 - track/cbLinearisedPos_R2217';
%    'R2336 - track/cbLinearisedPos_R2336';
%    'R2337 - track/cbLinearisedPos_R2337'
%    };


%Not used - too few spikes
% 'R2142 - screening/20140806_R2142_screening', [9,10,11,12,13,16];
% 'R2335 - screening/20151026_R2335_screening', [10,12,15,16];



% --- MAIN ---------------------------------------------------------------
nAnimal         =size(fileTet,1);

[meanErr, medianErr] =deal(zeros(length(tWin2Test),nAnimal)); %[win x nAnimal]
nCells          =zeros(nAnimal,1);



h               =waitbar(0,'Looping over trials');
for kk          =1:nAnimal %Loop over animals
    %Deal with situation in which we need to linearise the data
    if isZmaze %zMaze data - so load the linearised data
        load([dataDir, fileMat{kk}]); %loads linPos [1 x nPts]
        linPos      =[linPos', ones(size(linPos')).*2];
        
        %Load the data file to use to create new dataPos
        data                =read_DACQ([dataDir, fileTet{kk,1}]); %Load trial data
        dataPos             =data.pos;
        dataPos.xy          =linPos; %Update pos.xy
        dataPos.header{fliplr(strcmp(dataPos.header, 'window_max_x'))}=...
            num2str(round(max(linPos(:,1)))+1);
        dataPos.header{fliplr(strcmp(dataPos.header, 'window_min_x'))}=...
            num2str(round(min(linPos(:,1)))-1);
        dataPos.header{fliplr(strcmp(dataPos.header, 'window_max_y'))}='3';
        dataPos.header{fliplr(strcmp(dataPos.header, 'window_min_y'))}='1';
        clear data linPos
        
    else
        dataPos             =[];
    end
    
    
    for nn          =1:length(tWin2Test) %Loop over window length for each animal
        
        %Note now changed this next line to use a version of
        %decode_crunchData that is in this directory (changed name not to
        %confuse with the version in git)
        [err, decXY, trueXY, ~, nCells(kk)]=decode_crunchDataRaulVariant ...
            ([dataDir, fileTet{kk,1}], fileTet{kk,2}, tWin2Test(nn), cValid, tBinOverlap(nn), 0, fileTet{kk,3}, dataPos);
        
        %Build structure for when we need all the data for each animal
        dataStruct(nn).tWin        =tWin2Test(nn);
        dataStruct(nn).decodedXY   =decXY;
        dataStruct(nn).trueXY      =trueXY;
        dataStruct(nn).err         =err;
        dataStruct(nn).nCells      =nCells(kk);
        
        meanErr(nn,kk)              =mean(err);
        medianErr(nn,kk)            =median(err);
    end
    waitbar(kk/nAnimal);
    
    %Build a strucuture over animals
    animalStruct(kk).animal         =fileTet{kk,1};
    animalStruct(kk).dataStruct     =dataStruct;
    
    
end
close(h);

%Now for each animal find the min error for mean and median
[bstMean, ind]  =min(meanErr,[],1);
bstMean(2,:)    =tWin2Test(ind);
[bstMedian, ind]=min(medianErr,[],1);
bstMedian(2,:)  =tWin2Test(ind);
clear ind


