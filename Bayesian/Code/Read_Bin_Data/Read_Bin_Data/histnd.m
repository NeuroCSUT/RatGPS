function [nd_array, nd_bins] = histnd(nd_data, nd_ranges, bin_size)
% HISTND Bins columnar N dimensional data into an Nd array.
% Based on MIA's histnd provided with mTint. Primarily for binning spatial
% and/or directional data. Also used for pxd analysis which requires
% simultaneous binning of position and direction data.
% NB have checked the result of this code against the old histnd, they
% match.
% *
%
% NB dimensions of the returned array match the order of dimensions
% in nd_data - hence if data is passed to this function as x then y then
% nd_array will need to be transposed to get it in xy format.
%
% ARGS
% nd_data   [n_data_points x n_dim] Raw data for each element to bin 
%           (e.g. for PXD spatial data [posX, posY, dir])
%
% nd_ranges [1 x n_dim] or [2 x n_dim] First row containins the maximum 
%           permitted value of the data in the corresponding column of 
%           nd_data (e.g. [window_max_x, window_max_y, 360]). If second row
%           is present that indicates the minimum permitted value and is
%           subtracted from teh corresponding nd_data column before binning
% 
% bin_size  [1 x n_dim] the size of the bins to be used to bin the
%           corresponding columns of nd_data (e.g. for spatial [8, 8, 6]).
%           NB order matches the order of data dimensions in nd_data and
%           nd_ranges
%
% RETURNS
% nd_array  [n_dim mat of size defined aprox by nd_ranges./bins_size]
%           Carries the binned data (i.e. nd histogram)
%
% nd_bins   [n_data_points x n_dim] The bin that each data points has been
%           assigned to. e.g. for spatial data [xBin, yBin] - so to get an
%           index for the 2D binned position would need to do sub2ind
%
%
% EXAMPLE
%  bin    =histnd(posdata.xy(pos2use,:), [extent_x, extent_y], [binSize, binSize])


% ---
% 1) Do some checks
[n_el, n_dim]       =size(nd_data);
if n_dim~=size(nd_ranges,2)
    error('nd_data and nd_ranges must have same number of columns');
end



% ---
% 2) Normalise data and allocate to bins
% NB after dividing by bin size will round up. To deal with values that are
% 0 and hence woudl end up in bin 0 and not 1 we add eps to the 0 values.
% Hence effectively the bin edges run from n> x >=n+1 expect for bin 1
% where n>= x >= n+1
if size(nd_ranges,1)==2 %Then subtract min values in nd_ranges
    nd_data         =bsxfun(@minus, nd_data, nd_ranges(2,:));
end

nd_bins             =bsxfun(@rdivide, nd_data, bin_size);
nd_bins(nd_bins==0) =nd_bins(nd_bins==0)+eps; %Deal with lower edge of lowest bin
nd_bins             =ceil(nd_bins); %Round to integer bins


% ---
% 3) Cound and fix bad points
% Points that are too low - add to first bin
bad_low_points      =find(nd_bins < 1);
nd_bins(bad_low_points)=1;

% Points that are too high - add to last bin)
max_bin             =ceil(nd_ranges(1,:)./bin_size);
bad_high_points     =bsxfun(@gt, nd_bins, max_bin);
tmp_max             =repmat(max_bin, [n_el,1]);
nd_bins(bad_high_points)=tmp_max(bad_high_points);
bad_high_points     =any(bad_high_points,2);
clear tmp*


% ---
% 4) Do the histogram using accumarray
if length(max_bin)==1; max_bin=[max_bin,1]; end %for accumarray
nd_array            =accumarray(nd_bins, 1, max_bin);



% --- 
%5) Give warning if there are too many bad points (i..e >10%)
if ((sum(bad_low_points) + sum(bad_high_points)) / n_el) > 0.1
    warning('>10% of binned data points in HISTND are outside expected range.');
end
