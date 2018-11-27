function [allMeanErr, allMedianErr] = main_testOnEstoniaData_downsamp( )
%MAIN_TESTONESTONIADATA_DOWNSAMP Version of master file allowing
%downsampling of cell numbers and only applicable to r2192. The appropriate
%number of cells to use should be specified in text files in a subdirectory
%to the directory containing this file.
%
% NB this is also only applicable to 2D data


% --- VARS ----------------------------------------------------------------
%Specify the time windows to use in seconds
tWin2Test       =1.2; %using a fixed time window here, the best one for R2192

%Specify cross validation to use 0.1 for 10% test set or 0.02 for 2%
%(50fold)
cValid          =0.1; %[0.1]

%Specify window overlap (0 to <1) specify proportion of window to overlap
% note this is fixed at half the window
tBinOverlap     =(tWin2Test*0.5)./tWin2Test;



% --- TRIALS AND TETS TO LOAD ---------------------------------------------
dataDir         ='/home/deepmind/projects/RatGPS/Bayesian/Data/'; %will append
%Specify trials to load and tets to use - not note usiing r2335 and r2142
%due to too few cells
%Screening open field

%Now specify file name, tetrode to use and PPM
fileTet         ={
    'R2192 - screening/20141001_R2192_screening', [9,10,11,12,13,14,15,16], 350;
    };

dwnSamp         ={
    'RandDownSamp/random_IDs_5.txt', 5;
    'RandDownSamp/random_IDs_10.txt', 10;
    'RandDownSamp/random_IDs_15.txt', 15;
    'RandDownSamp/random_IDs_20.txt', 20;
    'RandDownSamp/random_IDs_25.txt', 25;
    'RandDownSamp/random_IDs_30.txt', 30;
    'RandDownSamp/random_IDs_35.txt', 35;
    'RandDownSamp/random_IDs_40.txt', 40;
    'RandDownSamp/random_IDs_45.txt', 45;
    'RandDownSamp/random_IDs_50.txt', 50;
    'RandDownSamp/random_IDs_55.txt', 55;
    };


% --- MAIN ---------------------------------------------------------------
[allMeanErr, allMedianErr]=deal(zeros(size(dwnSamp,1),10));
h               =waitbar(0,'Looping over down samp sets');
for jj          =1:size(dwnSamp,1); %Loop over the downsamp mat
    %Load the text file to loop over
    fId             =fopen(dwnSamp{jj,1});
    cellsList       =fscanf(fId, '%f', [dwnSamp{jj,2},inf]); %Read each column
    fclose(fId);
    cellsList       =cellsList+1; %Plus 1 because these are numbered from 0
    nCellLoop       =size(cellsList,2);
    [meanErr, medianErr] =deal(zeros(length(tWin2Test),nCellLoop)); %[win x nCellLoop]
   
    
    for kk          =1:nCellLoop %Loop over cell sets
        cell2use            =cellsList(:,kk);
        dataPos             =[];
        
        for nn          =1:length(tWin2Test) %Loop over window length for each animal
            [err, ~, ~, ~]=decode_crunchData_SpecicCells ...
                ([dataDir, fileTet{1,1}], fileTet{1,2}, cell2use, tWin2Test(nn), cValid, tBinOverlap(nn), 0, fileTet{1,3}, dataPos);
            meanErr(nn,kk)              =mean(err);
            medianErr(nn,kk)            =median(err);
        end
    end
    
    allMeanErr(jj,:)    =meanErr;
    allMedianErr(jj,:)  =medianErr;
    
  waitbar(jj/size(dwnSamp,1));  
end
 close(h);

 save downSampResultsCompl.mat allMeanErr allMedianErr dwnSamp
