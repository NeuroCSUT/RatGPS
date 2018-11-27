function [p, d] = pxd(spikes, times)
% PXD Calcs & plots ML estimates of true spatial & dir firing plots
%
% Generates and plots the fields and polar_plot resulting from a maximum
% likelihood factorial model of influences of place (p) and direction (d)
% on cell firing, assuming Poisson noise. Standard (spikes/dwell_time)
% plots are also shown for comparison. See Burgess, Cacucci, Lever, O'Keefe
% Hippocampus (2005) for details of procedure, although slightly different
% binning and smoothing of data is used in this reference.
%
% The algorithm is run until the fractional change in the likelihood of the
% data is less than 'accuracy' (e.g. 0.00001, i.e. until 'convergence') or
% for max_iter iterations (e.g. 1000, i.e. 'non-convergence').
%
% The pxd ratemap and polar data are plotted along with the standard p,d
% for comparison. All are smoothed by the specified boxcars.
%
% IMPORTANT. Spatial bins shouldn't be too small - specifically if there
% are too many spatial bins then the result will be unstable. Suggest
% setting bin size so number of spatial bins does not exceed 30 x 30 (so
% roughly 3cm bins in a 1m square). Directional bin size is less
% problematic.
%
% ARGS
% spikes    [n_dir_bins x n_posY_bins x n_posX_bins] Hist of spike count in
%           the 3D matrix defining place by direction. Will typically be
%           generated using histnd.m
%
% times     [same dim as spikes] Similar to spikes but the dwell time
%           counts for those bins. This should be in seconds not pos samp.
%
%
% RETURNS
% p         [y_bins x x_bins] Unsmoothed positional firing ratemap
% d         [1 x d_bins] Unsmoothed directional firing ratemap
%
% Use e.g.:
% [p, d] = pxd(spikes, times);
%
% NB is closely based on Neil's original code used by MIA for mTint which
% can be found in mTint repository.


% --- VARS ---------------------------------------------------------------
% max_iter  [scalar] Maximum number of iterations to perform before quiting
%           more takes longer. Previously was 30 but recommend 1000 (1000)
max_iter        =1000;

% accuracy  [scalar] If change in log likelihood per iteration falls below
%           this then the algorithm has converged (0.000001)
accuracy        =0.000001;

% tol       [scalar] Tolerance, replaces expected firing rate values less
%           than tol (usually due to unvisited states) to avoid log(0)
%           divergence in loglikelhood, and to avoid division  by zero in
%           p_estimate and d_estimate.
tol             =0.1;

converged = 0; %Preallocated as 0


% --- MAIN ---------------------------------------------------------------

% --- Error catch
if ( sum( size(spikes) == size(times) ) ~= 3 )
    error(1, ' matrices spikes and times have different dimensions');
    return
end


% --- Main loop
%Main loop over the ML procedure - before first loop seed initial guess
[nd, ny, nx]    =size( spikes);
fit             =1;
p               =ones( ny, nx); %Initial guess
d               =ones( nd, 1 );
for iter        =1:max_iter 
    %Note in Niel's original code d is estimated first - the order actually
    %changes the outcome if too many spatial bins are used e.g. 50 x 50
    d               =d_estimate(p, spikes, times, tol);
    p               =p_estimate(d, spikes, times, tol);
    prev_fit        =fit;
    
    % NB log likelihhod is a negative (the smaller in magnitude the better)
    fit             =loglikelihood(p, d, spikes, times, tol);
    if( abs(prev_fit - fit) < -accuracy*fit )
%         fprintf(1, ' converged, loglikelihood: %f\n', fit);
        converged = 1;
        break;
    end
end

% --- Decide what to return
if( converged == 0 )
    warning('PXD did not converge, returning nans');
    [p,d]       =deal(nan); %Return nans
else
    % Converged - return the ratemaps but note have an extra normalisation
    % step to ensure that the area under the ratemaps (spatial and polar)
    % are equal to nSpikes/time. This is not necessarily the case after the
    % ML procedure
    tot_spikes  =sum(spikes(:));
    time_per_bin=squeeze(sum(times,1)); %time per spatial bin in s
    pred_spikes =sum(sum(p.*time_per_bin));
    p           =p.*(tot_spikes/pred_spikes);% adjusted pos rate
    
    time_per_bin=squeeze(sum(sum(times,2),3)); %time per dir bin in s
    pred_spikes =sum(d.*time_per_bin);
    d           =(d.*(tot_spikes/pred_spikes))';
    
end
end

% --- SUB FUNCTIONS -------------------------------------------------------
function p = p_estimate(d, spikes, times, tol)
% spikes and times are matrices with dimensions: nd ny nx
% d is a vector of length nd
% estimate matrix p(i1, i2) = (sum_j spikes(j, i1, i2) )/ ( sum_j( d(j)*times(j, i1, i2) )
% returns [-1 -1; -1 -1] if there's a problem

[~,ny, nx]     =size(spikes);

temp = repmat(d, [1 ny nx]);
denom = squeeze(sum(temp.*times, 1));
% if denom is 0 (most likely as times=0) we don't know what rate p to predict,
% if denom < tol, make p small: p = spikes*tol
denom( denom<tol ) = 1/tol;
p = squeeze(sum(spikes, 1))./denom;
end


% ---
function d = d_estimate(p, spikes, times, tol)
% spikes and times are matrices with dimensions: nd ny nx
% p is a matrix of size ny nx (y down)
% estimate vector d(j) = (sum_i1i2 spikes(j, i1, i2) )/ ( sum_i1i2( p(i1, i2)*times(j, i1, i2) )
% returns [-1 -1] if there's a problem

[nd , ~, ~]     =size(spikes);

temp            =repmat(p, [1 1 nd]);
temp            =permute(temp, [3 1 2]);
denom           =squeeze(sum(sum(temp.*times, 2), 3));
% if denom is 0 (most likely as times=0) we don't know what rate p to predict,
% if denom < tol, make p small: p = spikes*tol
denom( denom<tol ) =1/tol;
d               =squeeze(sum(sum(spikes, 2), 3))./denom;

end


% ---
function fit = loglikelihood(p, d, spikes, times, tol)
% spikes and times are matrices with dimensions: nd ny nx
% p is a matrix of size ny nx (y down), d is a vector of length nd
% find log likelihood of spikes(j, i1, i2) under model: expected(j, i1, i2) = p(i1, i2).d(j).t(j, i1, i2)
% assuming Poisson noise, i.e.: p(n spikes) = expected^n exp(-n) / n!
% fit = sum_ji1i2( spikes(j, i1, i2)*log(expected(j, i1, i2)) - expected(j, i1, i2) - log( spikes(j, i1, i2)! )
% NB log(expected) is replaced by log(tol) where expected < tol (e.g. 0.000001) to avoid log(0) divergence.
% uses gammaln(n+1) = log(n!)

[nd, ny, nx] = size(spikes);

temp1 = repmat(p, [1 1 nd]);
temp1 = permute(temp1, [3 1 2]);
temp2 = repmat(d, [1 ny nx]);
expected = temp1.*temp2.*times;
%
% log diverges for expected number of spikes = 0, if less than tol, replace with tol.
%
expected2 = expected;
expected2( expected < tol ) = tol;
fit = sum(sum(sum( spikes.*log(expected2) - expected - reshape(gammaln(spikes + 1), [nd ny nx]))));
end
