function [ err,decXY, trueXY, mlVal] = decode_processPost( post, posData, sBin, winLim)
%DECODE_PROCESSPOST Use ML  to decode posterior prob & measure accuracy
% Having calculated the posterior probability matrix now use it to actually
% decode location - take max liklihood estimate (i.e. most probable bin -
% if several are joint just pick on at random). Based on decoded location
% all so calculate several measures of performance: decodeError - Euclidian
% distance between true and decoded location; probAtTrueLoc - the value of
% the probability matrix at the animals actual location.
%
% NB. To ignore speicific time steps set all values in the post for that
% timestep to nan.
%
% ARGS
% post          The posterior probability matrix returned by
%               decode_calcPost.m [envSz1 x envSz2 x nTimeBin]. TimeBins
%               with all nan valus are ignored
%
% posData       The pos branch of the standard tint strucutre e.g.
%               data.pos (which has true position in xy pairs of pixels)
%
% sBin          Spatial binsize in pixels (NOTE not in cm)
%
% pos2use       [nPos x 1] Index into data.pos.xy indicating which pos
%               points were used for decoding. If not specified defaults to
%               allOfPos i.e. (1:length(data.pos.xy)). Note only complete
%               time windows are considered - if length(pos2use) is not
%               exactly divisible by tBin then trailing pos are ignored.
%               NB2. pos2use must be a continuous sequence.
%
% winLim        Pos_samples defining the start and end of each window.
%               These bins are inclusive hence if start and end pos are w
%               and v then spikes falling in pos samp w and v are counted
%               in that bin. [nBin x 2] [start, end]. Note this matrix is
%               retruned by decode_getSpkCnt
%
%
% RETURNS
% err           Vector of decoding errors at each timestep (error being
%               distance betweewn true and decoded location in PIXELS).
%               Unprocessed bins are nan
%
% decXY         Decoded location in xy pair (pixels) at each time bin -
%               unprocessed steps are nan. Locatin is decoded to a bin at
%               each time step, the centre of that bin is returned as the
%               decoded location.
%
% trueXY        Actualy xy location of the bin centre that the rat inhabits
%               during each time step (i.e. find mean location in each time
%               window, allocate that to a bin, use centre of that bin)
%
% mlVal         Value of peak bin in post at each time step
%







% --- Main 
% Start to process the pos_samp associated with each time window
tBin        =winLim(1,2) - winLim(1,1) +1; %Time windows size in pos samp
nTWin       =size(winLim,1); % ... and number of time windows

% Create a full index into posData.xy for each window
winFullPosInd=bsxfun(@plus, winLim(:,1), (0:(tBin-1))); %[nWin x WinSize in Possamp]



%For each of those time windows figure out the rats mean locations
truePosX    =mean(reshape(posData.xy(winFullPosInd,1),nTWin,tBin),2);
truePosY    =mean(reshape(posData.xy(winFullPosInd,2),nTWin,tBin),2);
trueXY      =[truePosX(:), truePosY(:)]; %Still in pixels
clear truePosX truePosY

%Convert those locations to a bin, and use this to get the bin centre
tmpPosData  =posData; %Have to create a dummy posdata to get resutls in
tmpPosData.xy=trueXY;
[~, binned_index] = ...
    bin_data('dwell', 'position', sBin, tmpPosData);
clear tmpPosdata;

%Find the centre of each bin in PIXELS - this is used to get the location
%of true position and decoded position
[xx,yy]     =meshgrid(((1:size(post,2))-0.5).*sBin, ((1:size(post,1))-0.5).*sBin);
if size(xx,1)==1
    xx      =xx';
    yy      =yy';
end

%Use the binning of true location to look up the assocated bin centres
trueXY      =[xx(binned_index), yy(binned_index)];


% ---
% Now decode to a location using a ML frame work and compare with true
% location
% So on each time step find the maxvalue and decode to that bin - if
% several have the same max value pick one at random.
[mlVal, mlInd]=deal(zeros(nTWin,1));
decXY       =zeros(nTWin,2);

for n       =1:nTWin %Fast without parfor!
    curPost         =post(:,:,n);
    [tmpVal, tmpInd]=max(curPost(:)); %select max
    tmpInd          =tmpInd(randperm(length(tmpInd),1));%If multiple take 1@rand
    mlVal(n)        =tmpVal(1); %Store value in post at ML decode location
    mlInd(n)        =tmpInd; %Store the decoded bin index
    
    decXY(n,:)      =[xx(tmpInd), yy(tmpInd)]; %Decode value in pix 
end


err         =sqrt(sum((decXY - trueXY).^2,2)); %Euclid decode error


%Debug
% warning('In debug code in decode_procesPos - comment out/n');
% for nn      =1:nTWin
%     test        =zeros(size(post(:,:,1)));
%     test(mlInd(nn))=1; %Mark decoded bin with 1
%     test(binned_index(nn))=2; %Mark true bin with 2
%     
%     subplot(1,2,1)
%     imagesc(test);
%     title(['Error in pix:' num2str(err(nn))]);
%     
%     subplot(1,2,2)
%     hist(err);
%     title('error in pix histogram');
%     
%     figure(gcf);
%     pause
% end



end

