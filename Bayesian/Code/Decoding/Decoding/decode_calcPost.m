function [ post ] = decode_calcPost( obsSpk, rm, tBin, varargin)
%DECODE_CALCPOST Given spikes & ratemap get posterior probability
% Decodes spatial location based on historic and current spikes. For each
% time step activity in population of cells is compared with ratemaps and a
% posterior probability of the animal being in different locations is
% calculated assuming possion dynamics.
%
% Replaces functions that were specialised for 1D or 2D, this works for
% both. Also take either a single time bin or multiple time bins and hence
% outputs either a single posterior or a sequence of them. Also works for
% non-integer spike counts (approximates factorial with gamma function)
%
% Note fourth argument (which is optional) allows the normalisation to be
% turned off so the posterior doesn't sum to 1. Be careful with this since
% ratemap bins with 0hz spikes will each yield a probability of 1 if no
% spikes are observed.
%
% Calculation of the posterior  is based on that which
% we used in Towse (2014) which is based on Mathis (2012) eq 3.1 page9.
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
% post          =decode_calcPost(mySpikes, myRms, 0.2); %Will normalise
% or
% post          =decode_calcPost(mySpikes, myRms, 0.5, false); %No normalise


% --- HOUSE KEEPING ---
% Need to add a small number to avoid having zeros in the expected number
% of spikes. If expected spikes for a given bin is 0 and we have a single
% spike then the probability of this is 0 which is clearly not useful.
smallV          =eps.^8;

nCell           =size(obsSpk,1);
[envSize(1), envSize(2), ~]=size(rm);
nTBin           =size(obsSpk,2);

if nCell ~= size(rm,3)
    error('Number of cells in tBin and rm do not match');
end

if nargin==3 %Proceed as normal with normalisation if not specified
    normalise       =true;
elseif ~islogical(varargin{1})
    error('4th variable ''normalise'' must be empty, true or false');
else
    normalise       =varargin{1};
    clear varargin
end




% --- MAIN ---

% - First calculated expected number of spikes and take exponents
rm              =rm + smallV; %Add a small number so there are no zeros
expecSpk        =rm*(tBin); %[env size 1 x env size 2 x nCells]
expon           =exp(-expecSpk); %Exponent of equation.


% - Second process observed spikes
obsSpk          =shiftdim(obsSpk, -2); %3d [1 x 1 x nCells x nTimeBins]
factObsSpk      =gamma(obsSpk+1);


% - Third caculate the posterior prob for all timebins
wrking          =bsxfun(@power, expecSpk, obsSpk); %[envSize1 x envSiz2 x nCells x nTimeBins]
wrking          =bsxfun(@rdivide, wrking, factObsSpk);
wrking          =bsxfun(@times,wrking, expon);
post            =prod(wrking,3); %Non normalised prob [envSize1 x envSize2 x 1 x nTimeBins]
post            =reshape(post, [envSize(1), envSize(2), nTBin]);

% Finally do we normalise so that the post sums to 1 - this is the default
% position
if normalise
    post        =bsxfun(@rdivide, post, nansum(nansum(post,1),2)); %Normalise 1&2 dim sum to 1
end



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

