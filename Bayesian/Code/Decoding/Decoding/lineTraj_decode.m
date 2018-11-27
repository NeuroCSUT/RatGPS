function [ bstRes, bstSpd, bstYInterc, bstTstLnBnd] = ...
    lineTraj_decode( pMat, tBinSz, sBinSz, yRange)

%LINETRAJDECODE Find best straight trajectory through postprob matrix
% Decoder returns a posterior probability matrix [pos bins [1cm] by time
% bins [1ms], typically [100,300] i.e. 100cm by 300ms]. Each bin is the
% prob the rat was at that pos at that time. Goal is to find the best
% constant speed trajactory (straight line) path through this matrix i.e.
% the line that is highest probability.
%
% Based on fast_best_line.m in FO_biased_replay writen orginally for the
% biased replay paper but not used
%
% Method is simple - for a given line sum the prob in the bins within a
% certain distance of the line (can be graded - see below), then
% iterate for different lines and find the
% one that includes the highest sum (actually mean) probability.
%
% Implementation is done with il_filter2 for speed - allows all offsets for a
% given line gradient to be tested at the same time. Note only lines of a
% given range of gradient are tested and only certain offsets are valid. A
% final criteria is that lines must include sufficient bins to be
% considered trustworthy (i.e. don't accept lines that just 'clip' the
% postProb matrix).
%
% DEFINING ROI AROUND LINE
% See inline function (around line 220) for code that defines the line with
% ROI - this can either be a hard cut off or graded. If the latter then the
% yRange needs to be large (100). Comment lines to change behaviour.
%
% RETURNED RESIDUAL
% This is the bit that has changed from fast_best_line.m Really want to
% know of all the variability in the pMat how much is the line explaining
% (i.e. how much does the ROI cover - needs to be weighted by the ROI if
% not a hard cut off I think)


% ARGS              [note most args are now hard coded]
% pMat              Posterior prob matrix with dim1 being spatial bins and
%                   dim2 being time. This is output of decoder indicating
%                   for each time bin the prob animal is at given point.
%                   Columns should sum to 1. [nPosBin x nTimeBin].
%                   Except note that columns with no data can be set to all
%                   0 (col with no data is one without spikes)
%
%
%
% tBinSz            Temporal bin size in s (temporal axis is the y-axis)
%                   [0.005]
%
% sBinSz            Spatial bin size in cm, likely to be 1cm [2]
%
% yRange            Define size of 'band' around line that is used to 
%                   calculated it's goodness of fit. This value should be 
%                   an integer and indicates the number of bins above and 
%                   below (in the y-axis) that are counted. Must be >0 and
%                   should be a whole number. NB for clarity: a value of 4 
%                   would generate a band of width 9 in the y dimension 
%                   i.e. 4 bins above and below the line.
%
%
% RETURNS
% bstRes            residual or probability of best fit line. Basically the
%                   the proportion of weights in the pMat that falls under
%                   the line
%
% bstSpd            [1x2]gradient of best fit line in both timeBin/posBin
%                   element1 and cm/s (element2)
%
% bstYInt           yIntercept of best fit line (see fitLine_CB2) but
%                   basically is posBin of intercept
%
%
% bstTstLnBnd       The line mask for pMat that gives the best residual
%                   i.e. using this as a logical mask of pMat will pull out
%                   all bins that contribute to the residual
% e.g.
%  [ bstGrd, bstInt, bstRes ] = fast_best_line( pMat, 0.001, 1, 100 )


% --- DEFINE HARD CODED VARS --------------------------------------------
% % Temporal bin size in s (temporal axis is the y-axis).
% tBinSz          =0.005; %[0.001] i.e. 1ms
% 
% % Spatial bin isze in cm, likely to be 1cm
% sBinSz          =2;

% Min and max speed to consider in cm/s e.g. [100,200] would test speeds
% between 100cm/s and 200cm/s for both postive and negative speeds ie.
% actually -100cm/s to -200cm/s as well as 100cm/s to 200cm/s.
% Effecitvly defines the range of gradients that are tested. The values are
% inlclusive so spdBnd [50,100] would include -100cm/s, -50cm/s, 50cm/s and
% 100cm/s
spdBnd          =[100,5000];

% Also define the increment step to iterate through speed e.g. should we
% test speeds every 1cm/s (i.e. -200, -199, -198) or every 2cm/s or 5cm/s.
% Larger numbers will give fewer increments (faster) but lower fidelity.
spdInc          =50;

% Define size of 'band' around line that is used to calculated it's
% goodness of fit. This value should be an integer and indicates the number
% of bins above and below (in the y-axis) that are counted. Must be >0 and
% should be an an number
% yRange          =14; %[100 of graded] [10 or 14 for hard]

% Also have a requirement for final line to be some minimum length - to
% avoid situations where a line just cuts through a small section of the
% pMat and scores a (spurious) high score. Lines of less than this number
% are discarded.
minLgth         =size(pMat,2)/3;



% --- HOUSE KEEPING -----------------------------------------------------
% Use parallel loops (parfor) to speed up calculation - initiate cluster
gcp;


% --- MAIN CODE ---------------------------------------------------------
% Size of pMat - used several times
szPM1           =size(pMat,1);
szPM2           =size(pMat,2);

%Replace nan with 0
pMat(isnan(pMat))=0;

% Deterine the range of gradient that will need to be tested and
% express in terms of sBins per tBin
spd2Test        =-spdBnd(2):spdInc:spdBnd(2);
spd2Test        =spd2Test(~(spd2Test > -spdBnd(1) & spd2Test < spdBnd(1))); %Remove slow speeds
spd2Test        =(spd2Test ./sBinSz) .*tBinSz;
nSpd2Test       =length(spd2Test);
clear           spdBnd


% Now loop over each gradient to test and in each loop test all possible
% offsets for a line of that gradient. First do some preallocation for
% speed. Each loop returns the mean probability of bins in the pMat covered
% by the line and the band around it as well as the raw number of bins
% covered. These are stored in 2d mats of size [nOffsets tested x nSpds
% tested]
[meanP, bestOffSet]           ...
    =deal (zeros(nSpd2Test,1)); %nOffset x nSpds tested.

pMatOnes        =ones(size(pMat)); %Mat of ones the same size as pMat

parfor nn       =1:nSpd2Test
    
    %Main step is to calculate the sum of pMat bins that overlap with a
    %line of specific gradient for all allowed offsets. Start by defining
    %line and the band around it as a mat.
    
    
    %Use an  function to define the line - partly to keep code tiday
    %and because it's called in multiple places. The two mats returned are
    % a zeros and ones mat defining just the line (tstLn) and a similar mat
    %defining the line plus band arround it defined by yRange (tstLnBnd).
    %Each has dim [variables x szPM2] i.e. second dim is same as pMat
    [tstLn, tstLnBnd]   =lineTraj_define_line(szPM2, spd2Test(nn), yRange);
    
    
    %Now do the main step - use il_filter2 to convolve the tstLn with the pMat
    %so effectivly testing the overlap between the line and pMat at all
    %offsets - to make this step faster just use the 'valid' opperator but
    %first zero pad dim1 of pMat
    tmpMeanP        =il_filter2(tstLnBnd, padarray(pMat,[size(tstLn,1),0]));
    
    
    %Use similar method to get the actual lenght of the line
    tmpLineLength   =il_filter2(tstLn, padarray(pMatOnes,[size(tstLn,1),0]));
    
    %Now discard data points corresponding to line that is too short and
    %store the details of the line that gives the highest fit.
    tmpMeanP(tmpLineLength<minLgth)  =0; %Set ones that are too short to 0
    [meanP(nn), bestOffSet(nn)]  =max(tmpMeanP); %Store max and ind.
end
clear tmp* tst* nn


%Finally from the result of the loop extract the details of the line that
%gave the best fit i.e. the value of the fit, the gradient and intercept.

%NL. bestRes is the highest mean prob per bin of the overlap between pMat
%and line found. tmpInd is the index into meanP (i.e. loop index) that gave
%this result. Normalise the prob explained by the total amount of prop to
%make it more meaningful.
[bstRes, tmpInd]    =max(meanP);
bstRes              =bstRes./sum(pMat(:));
%bestSpd is the spd (still in sBins per tBins) that gave the highest result
bstSpd              =spd2Test(tmpInd); %Speed in sBins per tBin
bstSpd(2)           =bstSpd(1)*sBinSz ./tBinSz; %Speed in cm/s 


% ---
%Offset is harder to understand - first thing to remember is that
%co-ordinate system is -1 from the bin subscript (i.e the first x bin is
%equivalent to x=0 and same for y). The offset is related to the value of
%the convolution that gives the highest overlap between pMat and mask but
%is complicated by the fact that both the pMat and the mask are padded (and
%the mask can have a postive or negative gradient)

%Start by getting the best tstLn back - this is padded like the ones used
%above
[tstLn, tstLnBnd]             =lineTraj_define_line(szPM2, spd2Test(tmpInd), yRange);

%NB. -2 is correct in next line [fairly sure of that] because we have -1
%from the convolution since bin 1 is actually equivalent to lag of 0 and we
%have -1 from converstion between matrix coor and real coord.
bstYInterc          =...
    bestOffSet(tmpInd) + find(tstLn(:,1)) - size(tstLn,1) -2;


% ---
%Also want to return the exact tstLnBnd that best fits the pMat. Do this by
%padding the tstLnBnd in much the way the pMat is padded for the il_filter2
%then selecting out of that
%First find how much has to be added to top or removed from top of tstLnBnd
% tmpYShift           =bstYInterc - find(tstLn(:,1))-1;
% if tmpYShift <0 %negative shift
%     %Check if tstLnBnd is large enough to select out of or if it needs
%     %padding
%     tmpSzDif        =size(tstLnBnd,1) - (-tmpYShift+szPM1-1);
%     if tmpSzDif<0 %Not large enough
%         bstTstLnBnd     =tstLnBnd(-tmpYShift:end,:);
%         bstTstLnBnd     =padarray(bstTstLnBnd, abs(tmpSzDif), 0, 'post');
%     else
%     bstTstLnBnd         =tstLnBnd(-tmpYShift:-tmpYShift+szPM1-1,:);
%     end
% else
%     bstTstLnBnd         =padarray(tstLnBnd,tmpYShift,0, 'pre');
%     %Check if this is now large enough to select out of or if it needs
%     %padding
%     tmpSzDif            =size(bstTstLnBnd,1) - szPM1;
%     if tmpSzDif<0 %Not large enough
%         bstTstLnBnd     =padarray(bstTstLnBnd, abs(tmpSzDif), 0, 'post');
%     else
%     bstTstLnBnd         =bstTstLnBnd(1:szPM1,:);
%     end
% end

bstTstLnBnd         = ...
    lineTraj_reget_lnBnd( size(pMat), bstSpd(1), bstYInterc, yRange);


% If no line is found - e.g. if the pMat is too short (in time) to support
% any valid lines (all lines are too short) or if there is no data. Then
% bestRes will be 0. Catch these and return nans
if bstRes == 0 %No fit (probably) - so return nan
    [bstRes, bstYInterc, bstTstLnBnd]         =deal(nan);
    bstSpd      =ones(1,2).*nan;
end




% --- DEBUG STUFF --------------------------------------------------------
%Can comment all this out once code is functioning correctly
% fprintf('\n!!!Remember to comment out this debug code once running well!!!.\n\n');
% subplot(1,3,1) %First show pMat
% imagesc(pMat);
% hold on
% plot([1, szPM2], [0, bstSpd(1) * (szPM2-1)] + (bstYInterc +1), 'w');
% hold off
% axis square
% 
% subplot(1,3,2) %pMat with band on it
% imagesc(pMat);
% hold on
% [i,j]       =ind2sub([szPM1, szPM2], find(bstTstLnBnd));
% scatter(j,i,'rx');
% hold off
% axis square
% 
% subplot(1,3,3); %Just band
% imagesc(bstTstLnBnd);
% hold on
% plot([1, szPM2], [0, bstSpd(1) * (szPM2-1)] + (bstYInterc +1), 'w');
% hold off
% title(num2str(bstRes));
% axis square
% close all;

end



% --- INLINE FUNCTIONS ---------------------------------------------------

%----
function filtRes            =il_filter2(a,b)
%In line version of filter2 to replace matlab version - matlab version does
%lots of  tests to see if data is seperable then ends up doing a conv2
%anyway (after first rotating the filter by 180 deg). Also note the the
%order of the arguments is reversed. I've also hardcodes that we need the
%'valid' operator.

filtRes          =conv2(b, rot90(a,2), 'valid');
end