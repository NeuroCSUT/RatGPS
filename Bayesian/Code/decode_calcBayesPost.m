function [ post ] = decode_calcBayesPost( obsSpk, rm, dm, tBin)
%DECODE_CALCBAYESPOST Bayes decoding of pos given spikes & history
% Decodes spatial location based on several factors: i) spikes in observed
% time window (and knowledge of historic spikes), ii) p(x), historic
% probability of being at location x, iii) decoded location in time steps
% preceeding the current one. 
%
% Re. the latter factor. In other words we assume the animal is unlikely 
% to move far from the the last decoded loction. Since the code does not 
% have access to groudn truth location this does introduce the  possibility 
% of it sticking with an erroneous decode. Note also this closeness prior 
% is applied as a 2D gaussian centred on the previous decode location with 
% a sigma proportionate to the mean running speed in the last 15 time
% windows.

% Other than that code is similar to the naive ML decoder
% decode_calcPost which: for each time step activity in population of
% cells is compared with ratemaps and a posterior probability of the animal
% being in different locations is calculated assuming possion dynamics.
% Note because we must have access to the previously decoded location the
% code is sequential and hence slow
%
%
% Calculation of the posterior  is based on that which
% we used in Towse (2014) which is based on Mathis (2012) eq 3.1 page9.
% Full Bayes approarch is adapted from Zhang et al 1998. (J NeuroPhys)
% specfically page 1024 onwards. See eq 36 for version without history and
% note that compared to the standard ML method division by factorial is not
% applied.
%

%
%
% ARGS          3 or 4 required
% obsSpks       [nCells x nTimeBin] number of observed spikes for each cell
%               per time bin. Note will work for non integer values.
%
% rm            [env size 1 x env size 2 x nCells] stacked ratemaps for all
%               cells being analysed. Should be smoothed with unvisted
%               bins set as nan. Order of cells in 3rd dim should match
%               obsSpks. If 1D track dim2 should have size=1.
%
% dm            [env size 1 x env size 2] dwell map indicating for the same
%               period as the rm the time in seconds spent by the animal in
%               each bin.
%
% tBin          time bin width in s (e.g. 0.2 for 1D more for 2D)
%
% normalise     [not required - if not present defaults to true]. Specifiy
%               whether the resulting posterior should be normalised to sum
%               to 1. Either true or false
%
% RETURNS
% post          Posterior prob [envSz1 x envSz2 x nTimeBin] probability
%               animal is in each bin in environment
%
%
% e.g.
% post          =decode_calcBayesPost(mySpikes, myRms, dm, 0.2);



% --- HOUSE KEEPING ---
% Need to add a small number to avoid having zeros in the expected number
% of spikes. If expected spikes for a given bin is 0 and we have a single
% spike then the probability of this is 0 which is clearly not useful.
smallV          =eps.^8;

% When doing the closness prior need to calculate speed from some number of
% previous time steps (note time step lenght is defined by tBin). This
% variable defines how many time steps to use - also how many steps have to
% be missed off the start before speed can be calculated.
% Sensible range 5 to 15
nStepForVel     =5; % for 2D
%nStepForVel     =15; % for 1D

% Calculate mean speed in previous time steps and use that to define a
% sigma for the closeness prior. Can apply a scalling factor to that.
% Default shoudl be 1 i.e. sigma = mean distance travelled in one step
% NB for Ardi paper use 1 for open field and 5 for linear track
speedScaleFact  =1; % for 2D 
%speedScaleFact  =5; % for 1D

nCell           =size(obsSpk,1);
[envSize(1), envSize(2), ~]=size(rm);
nTBin           =size(obsSpk,2);

if nCell ~= size(rm,3)
    error('Number of cells in tBin and rm do not match');
end




% --- MAIN ---

% Can do most of the calculation as a parallel step but eventually have to
% loop over the position dimension - decode then apply movement prior

% - Zero. Calculate p(x) i.e. probability of dwell in location x. NB must
% use a smoothed dwell maps but retain Nans for unvisted i.e. assume we
% will not decode to unvisited bins.
px              =dm./nansum(dm(:));


% - First calculated expected number of spikes and take exponents
rm              =rm + smallV; %Add a small number so there are no zeros
expecSpk        =rm*(tBin); %[env size 1 x env size 2 x nCells]
expon           =exp(-expecSpk); %Exponent of equation.


% - Second process observed spikes
obsSpk          =shiftdim(obsSpk, -2); %3d [1 x 1 x nCells x nTimeBins]
% factObsSpk      =gamma(obsSpk+1);


% - Third caculate the posterior prob for all timebins
wrking          =bsxfun(@power, expecSpk, obsSpk); %[envSize1 x envSiz2 x nCells x nTimeBins]
% wrking          =bsxfun(@rdivide, wrking, factObsSpk);
wrking          =bsxfun(@times,wrking, expon);
post            =prod(wrking,3); %Non normalised prob [envSize1 x envSize2 x 1 x nTimeBins]
post            =reshape(post, [envSize(1), envSize(2), nTBin]);
post            =bsxfun(@rdivide, post, nansum(nansum(post,1),2)); %Normalise otherwise next step rounds to 0
post            =bsxfun(@times, post, px);
post            =bsxfun(@rdivide, post, nansum(nansum(post,1),2)); %Normalise 1&2 dim sum to 1
% NB line above is now the equivalent of eq 36 from Zhang et al


% Now have to loop and apply movement prior. Basic idea is that at each
% step we decode location from the previous step, then apply gaussian prior
% centred on that point with sigma adjusted to be proportional the the
% speed inferred from the previous steps.

%Do some preallocation
[xx,yy]         =meshgrid(1:size(dm,2), 1:size(dm,1));
[iS, jS, sigma] =deal([]);
lastFewPos      =zeros(nStepForVel,2); %Store prior pos to calc speed
pNewXGivenX     =ones(size(dm))./numel(dm); %for 1st step flat prior

for nn          =1:size(post,3)
       
    post(:,:,nn)    =post(:,:,nn).*pNewXGivenX; %Combine movement prior with post
    
    %Next steps are only used 
    if nn>=nStepForVel
        
        pNewXGivenX =exp(- (((xx-jS).^2 + (yy-iS).^2)./(2*sigma.^2))); %2d guassian focused on last pos
        pNewXGivenX =pNewXGivenX./(sum(pNewXGivenX(:))); %normalise to sum=1
    end
    
    %Now find peak from this step which is used to constrain next step
    [~,maxInd]  =max(reshape(post(:,:, nn),[],1)); %ML decode use for next step
    [iS,jS]     =ind2sub(size(dm), maxInd);% ML decode subscript
    lastFewPos  =[lastFewPos(2:nStepForVel,:); [iS,jS]]; %Discrad oldest pospoint add new
    speed       =mean(sum(diff(lastFewPos).^2,2).^0.5); %Speed is mean over last second in bins/sample
    sigma       =speed *speedScaleFact; %Fixed constant scaling of speed measured in bins/time step
    
 
    
    
end
post            =bsxfun(@rdivide, post, nansum(nansum(post,1),2)); %Normalise 1&2 dim sum to 1


%DEBUGGING - COMMENT OUT
% figure(1)
% subplot(1,3,1);
% imagesc(post), title('Post prob'), axis equal;
% for nn          =1:size(wrking,3)
%     subplot(1,3,2);
%     imagesc(rm(:,:,nn)), title('Rate map'), axis equal;
%     subplot(1,3,3);
%     imagesc(wrking(:,:,nn)), title('Prop for this cell'), axis equal;
%     fprintf('Hit a key ...\n');
%     pause;
% end

end

