function [ spkCnt, winLim ] = ...
    decode_getSpkCnt(spkPos, strEndPos, winWdth, varargin)
%DECODED_GETSPKCNTPERWINDOW Number observed spks per window & window extent
% Central step in Bayes decode is comparing the observed number of spikes
% in a given time bin with the expected number. This function returns the
% obsereved number of spikes and also determines the extent of the bins
% given the specified start time and window width. As extras it can also
% deal with overlapping time windows and spike counts that are smoothed
% (hence are non-intergers).
% Note all timings are conducted in pos_samples e.g. window width is in
% pos_samples, as is spikes times etc.
%
%
% ARGS
% spkPos        The times of the observed spikes as possamples - repeates
%               are allowed. [nSpk x 1]
%
% srtEndPos     The first and last posample in the range to be considered.
%               Note that this range may be truncated if it is not
%               divisible by winWdth. [1 x 2]. These values are inclusive
%               i.e. both the start and end pos sample will be included in
%               the counts (the end might not if the window size doesn't
%               exactly divided into the nPos)
%
% winWdth       Length of time window in pos_samples, bust be int [scalar]
%
% winOverlap    Optional. Overlap as proportion of neighbouring windows, 
%               defaults to 0 (no overlap if unspecified) might typically
%               use 0.5 (must be <1). Must be int [scalar].
%
% winSmth       Optional. Defaults to 0 no smoothing if not specified.
%               Otherwise is the sigma (in pos_samples) of a Gaussian that
%               is used to smooth the spikes rates before binning. Hence
%               spike counts will be non-integer.
%
% RETURNS
% spkCnt        Number of spikes in each window [nBin x 1]. NB includes
%               spikes that are equal to the lower and upper bin limits
%
% winLim        Pos_samples defining the start and end of each window.
%               These bins are inclusive hence if start and end pos are w
%               and v then spikes falling in pos samp w and v are counted
%               in that bin. [nBin x 2] [start, end]


% --- HOUSE KEEPING ------------------------------------------------------
if nargin==3
    winOverlap      =0;
    winSmth         =0;
elseif nargin==4
    winOverlap      =varargin{1}; %Win overlap specifed
    winSmth         =0;
else
    winOverlap      =varargin{1}; 
    winSmth         =varargin{2};
end

spkPos          =spkPos(:)'; %Force to row vect

% --- MAIN ---------------------------------------------------------------
% 1. Start by defining the edge of the windows
% Start of each window starts with the first pos specified in srtEndPos(1)
% and advances by winWdth - winOverlap. The list of end points starts with
% the srtEndPos(1) + winWdth and then advances by winWdth - winOverlap. 
% winWdth-winOverlap is the amount of possamp the edge of the window
% advances on each step - call this winAdvance
if winOverlap >=1, error('winOverlap must be less than 1'); end
winOverlap      =round(winWdth*winOverlap); %Convert to possamp
nPosSamp        =strEndPos(2)-strEndPos(1)+1; %Total number of posSamp to use
winAdvance      =winWdth-winOverlap; %nPosSamp window edge advances each step.
nWin            =floor((nPosSamp - winWdth)/winAdvance)+1; %Number of windows
winLim          =round(repmat((0:nWin-1)',[1,2]) .* winAdvance ...
    + repmat([0,winWdth-1],[nWin,1]) +strEndPos(1)); %Start and end of all the windows
winPos          =int32(bsxfun(@plus, winLim(:,1), 0:(winWdth-1))); %[nWin x nPosSampInEach] possamp in each window


%2. Interm step in binning is to get the spike count per bin - need to do
%this so that we can smooth if necessary. Only consider the bins that are
%actually used (i.e. within range winLim(1) and winLim(end).
spkCntFineSamp  =winLim(1):winLim(end); %Pos samp corresponding to each fine bin
spkCntFine      =histc(spkPos, spkCntFineSamp);
clear spkCntFineSamp

%Now smooth if required
if winSmth>0 %Then smth
    %Make a 1D (row) smth kern but normalise to avoid edge effects
    smthKern        =fspecial('gaussian', [1, ceil(winSmth*5)], winSmth);
    spkCntFine      =filter2(smthKern, spkCntFine);
    spkCntFine      =spkCntFine ./ filter2(smthKern, ones(size(spkCntFine)));
end


%3. Finally bin into the final spkCnt. Does this by using the pos samples
%assigned to each window (winPos) to select out of the spikes binned in
%spkCntFine. Note need to conver the pos samples to an index by subtracting
%a value so the first value in winPos becomes 1
spkCnt          =sum(spkCntFine(winPos-winPos(1)+1),2); %[nWin x 1]


end

