function [err,decXY,trueXY,mlVal, nCells]=decode_crunchDataRaulVariant( dirFln, tet2use, varargin)
%DECODE_CRUNCHDATA Loads data, gets ratemaps, decodes for all timesteps
% Master function for decoding. Reads raw data from disk, creates ratemaps,
% select spikes and parameters for decoding, then decodes location.
%
%
% ARGS [takes 2 to 8]
% dirFln            Directory and filename of set file e.g.
%                   'd:/data/123.set'
%
% tet2use           [nTet x 1] Col vector specifying which tets to use. Cut
%                   files are assumed to follow standard naming convention
%
% tBin              [scalar] Optional defaults to [0.5] if not supplied.
%                   Time window length
%                   in seconds, this controls
%
% cValid            [scalar] Optional, defaults to [0.1]. Specify if cross
%                   validation is required (if not set to 1) and if so what
%                   proportion of the data to hold back in the test set
%                   [0.1]
%
% tBinOverlap       [scalar]. Optional, defaults to [0]. Specify if time
%                   bins should overlap (set to 0 if not) and if so by how
%                   much(0 to <1) where 1 would be (meaningless full
%                   overlap)
%
% smthPS            [scalar]. Optional, defaults to [0]. The spike train
%                   be smoothed with a Gaus kern before getting the spike
%                   count per window for the decoding. Specify the sigma of
%                   the Gaus in pos_samp (0 for no smoothing). Try 1.5.
%
% ppm               [scalar]. Optional. Specifiy the pixels per meter (PPM)
%                   for the recording trial. If not specifed or empty the
%                   PPM is read from the pos.header file but in some cases
%                   this may be incorrect, in these situations is useful to
%                   specify externally.
%
% posDat            [structure] Optional. Replaces the pos.xx bit of the
%                   data.xxx standard structure. Use for using linearised
%                   data in which case the posData.xy needs to be replace
%                   and the matching headers 'window_max_x', 'window_min_x',
%                   'window_max_y', and 'window_min_y' need to be updated.
%                   posData.xy. Note if using linearised data the
%                   y value of dataPos.xy should be set to a fixed value).
%                   Note ppm should match this new data.
%
%
%
% RETURNS
% err               Vector of decoding errors at each timestep (error being
%                   distance betweewn true and decoded location in pixels).
%                   Unporocessed bins are nan
%
% decXY             Decoded location in xy pair (cm) at each time bin -
%                   unprocessed steps are nan
%
% trueXY            Actualy xy (cm) location at each timestep
%
% mlVal             Value of peak bin in post at each time step
%
% nCells            Number of cells used [scalar integer]


% e.g.
% dirFln = '/Users/caswell/Dropbox/tmpRaul/R2142 - screening/20140806_R2142_screening.set';



% --- VARS ----------------------------------------------------------------

% Fixed variables first
%Specify which is the junk cell in the cut file (i.e. which is ignored). NB
%in cut files made by tint is normally 0 but in klusterkwik is 1.
junkCell            =0; %In cut file ignore this cluster (0 for cut, 1 for clu)

%Ratemap variables are fixed
sBin                =2; %Spatial binsize in cm for binning the ratemap
kernSz              =1.5; %Smoothign kern for smoothing the ratemap
kernType            ='gaus';%Smoothing kern type 'gaus' or 'boxcar'


% Default vaiables second - these can be superceeded by values that are
% passed in.

% Specify default time bin length
tBin                =0.5; %Time bin length in s

% In ML & deep learning normal to test (decode) with a different data set
% used to train (generate rateamaps) - this is to prevent over fitting.
% Basic idea is that some portion of the data is held back to
% decode with and rest is used to build the ratemaps. Typically 10%/90%.
% The test 10% is itterated round. Specify proportion to hold back in test
% set - typically 10% i.e. 0.1 or specify 1 to not hold any back.
cValid              =0.1; %Specify portion to keep back for test [1] or [0.1]


%NL. Time bin overlap - currently set to half timewindow - windows overlap
%one another. Set to 0 for no overlap, is measured in proportion of time
%window 0 to <1
tBinOverlap         =0;

%NL. Smooth the spike counts per pos bin before calculating spike count per
%window. If specifed is the sigma in pos_samp of the Guassian used to
%smooth. 0 for no smoothing.
smthPS              =5; %Smoothing of spike train before getting counts

%NL. Truncate start of trial. In some circumstances it's useful not to use
%the first n seconds of a trial (which might be unreliable etc). Leave
%empty not to trunctate at all otherwise specify in seconds how much to
%lose.
truncS              =[]; %[] or 25 for linear track



% --- HOUSEKEEPING --------------------------------------------------------
if length(varargin)>=1, tBin=varargin{1}; end %specify tBin length
if length(varargin)>=2, cValid=varargin{2}; end %specify cross validation
if length(varargin)>=3, tBinOverlap=varargin{3}; end %time bin overlap
if length(varargin)>=4, smthPS=varargin{4}; end % spike rate smoothing
if length(varargin)>=5, ppm=varargin{5}; else ppm=[]; end %pixels per meter
if length(varargin)>=6, posData=varargin{6}; else posData=[]; end %replacement posData

curDir              =cd; %Starting directory
tBinPS              =50*tBin; %Time bin size in possamp (aka window size)




% --- MAIN ----------------------------------------------------------------
% --- First load in all the raw data that is required. -------------------
% Get the directory and filename
tmpFileSep          =find(dirFln==filesep);
dirNm               =dirFln(1:tmpFileSep(end)-1);
clear tmp*
cd(dirNm) %Change to data direcotry

data                =read_DACQ(dirFln); %Load trial data

%Now replace the posdata.xy if this was passed in
if ~isempty(posData)
    data.pos        =posData;
end
clear posData



% We assume the cut files follow standard naming procedure e..g
% filename_x.cut where the x is the tetrode number
for n               =1:length(tet2use) %Loop over loading the cutfiles
    exactCut{tet2use(n)} =read_cut_file([dirFln '_' num2str(tet2use(n)) '.cut']);
    tmp                  =unique(exactCut{tet2use(n)});
    tmp                  =tmp(tmp>junkCell);
    cell2use{n}          =tmp;
    tet2useAg{n}         =ones(length(tmp),1).*tet2use(n);
end

tetCellPair             =[vertcat(cell2use{1,:}),vertcat(tet2useAg{1,:})]; %ncell x 2 mat
nCells                  =size(tetCellPair,1);
clear nn tmp cell2use tet2use tet2useAg
cd(curDir);         %Change back to working dir

% Now turncate the start of the trial if required (i.e. if turncS is not
% empty). Need to remove poitns from pos, spike time stamps and exact cut.
if ~isempty(truncS)
    %Truncate start of file
    fprintf(['Truncating first ' num2str(truncS) 's of data.\n']);
    
    nPos2Rmv            =truncS*50; %n pos sample to remove from start
    data.pos.xy         =data.pos.xy(nPos2Rmv+1:end,:);
    
    for kk              =1:length(exactCut) %loop over tetrodes
        if isempty(exactCut{kk})
            continue %That tetrode isn't used skip to next
        else
            posSamp2Rmv      =find(data.tetrode(kk).pos_sample<=nPos2Rmv);
            data.tetrode(kk).pos_sample =...
                data.tetrode(kk).pos_sample(length(posSamp2Rmv)+1:end) - nPos2Rmv;
            exactCut{kk}     =exactCut{kk}(length(posSamp2Rmv)+1:end);
        end
    end
    
end


% --- Second loop over the tetrodes and cells to get the ratemaps and spike
% counts that will be used to decode. -------------------------------------

%Decide on spatial bin size, first check if PPM was passed in, if so use
%that but otherwise read from the heade file (specified from DACQ) and use
%that
if isempty(ppm)
    ppm              =key_value('tracker_pixels_per_metre', data.settings);
    ppm              =str2num(ppm{1});
end
xyBinSz          =ppm/100*sBin; %spatial bin size in pixels




% --- Thrid. Also loop over cross validation steps. -----------------------
nCVstep         =1/cValid; %Number of cross validation steps
nPosPerCVstep   =floor(length(data.pos.xy)/nCVstep);
posByCVstep     =1:nPosPerCVstep*nCVstep;
posByCVstep     =reshape(posByCVstep, [], nCVstep); %[nPosPerStep x nCVstep]
cvSteps         =1:nCVstep;

%Decide how many windows there are - hard to do if there are overlaps so
%just run a dummy testSet
tmpTestPos      =posByCVstep(:,1);
tmp             =decode_getSpkCnt([], [tmpTestPos(1), tmpTestPos(end)], tBinPS, tBinOverlap, smthPS);
nTWin           =size(tmp,1);
clear tmp

%Some preallocation
[err, mlVal]    =deal(zeros(nTWin,nCVstep)); %[nTWin x nCVsteps]
[decXY, trueXY] =deal(zeros(nTWin,2,nCVstep)); %[nTWin x 2 x nCVsteps]


for nCV         =1:nCVstep
    testPos     =posByCVstep(:,cvSteps(nCV));
    if nCVstep==1 %No cross validation - testPos=trainPos
        trainPos        =testPos;
    else %There is cross validation trainPos~=testPos
        trainPos    =reshape(posByCVstep(:, cvSteps(cvSteps~=nCV)),[],1);
    end
    
    %For speed preallocate the entire ratemap stack and the spike count stack
    binPos          =bin_data('dwell', 'position', xyBinSz, data.pos, trainPos); %just dwell
    rms             =zeros(size(binPos,1), size(binPos,2), nCells);
    spkCnt          =zeros(nCells, nTWin);
    
    
    for n           =1:nCells % is slower with parfor!
        t               =tetCellPair(n,2);
        spkPosSamp      =data.tetrode(t).pos_sample(exactCut{t}==tetCellPair(n,1)); %All possamp for this cell inc repeates
        pos2useTrain    =spkPosSamp(ismember(spkPosSamp, trainPos)); %Just spkPosSamp for training aka building rms
        binSpk          =bin_data('spikes', 'position', xyBinSz, data.pos, pos2useTrain);
        rms(:,:,n)      =make_smooth_ratemap(binPos, binSpk, kernSz, kernType); %smooth ratemaps
        
        if n==1 %On first loop
            [~, dms]        =make_smooth_ratemap(binPos, binSpk, kernSz, kernType); %smooth dwellmap
        end
  
        
        %Determine for the test spikes how many arrived in each of the
        %time windows:
        [spkCnt(n,:),  winLim]   =...
            decode_getSpkCnt(spkPosSamp, [testPos(1), testPos(end)], tBinPS, tBinOverlap, smthPS);
    end
    clear n t pos2use* binSpk
    
    
    % --- Fourth decode and get measures of performance -------------------
    %Store this for each fold of the cross validation
%     post            =decode_calcBayesPost(spkCnt, rms, dms, tBin); %3D mat [envSz1 x envSz2 x nTBin] FULL BAYES
 post            =decode_calcPost(spkCnt, rms, tBin); %3D mat [envSz1 x envSz2 x nTBin] OLD ML 
    
    %NL. decodes from the post - all returned values are in pixels
    [ err(:,nCV), decXY(:,:,nCV), trueXY(:,:,nCV), mlVal(:,nCV)] =...
        decode_processPost(post, data.pos, xyBinSz, winLim);
end

err             =err./ppm.*100; %Convert err to cm
decXY           =decXY./ppm.*100;
trueXY          =trueXY./ppm.*100;

%Reshape the results for presentation into col vectors or in the case of xy
%pairs [nWin x 2]
err             =err(:);
decXY           =reshape(permute(decXY,[2,1,3]), 2,[])';
trueXY          =reshape(permute(trueXY,[2,1,3]), 2,[])';
mlVal           =mlVal(:);


end

