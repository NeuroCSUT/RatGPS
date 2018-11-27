function [ smthDir ] = easy_make_polarplot( data, tet, cell, exactCut )
%EASY_MAKE_POLARPLOT Simple wrapper to bin data & generate polar ratemap
% An wrapper function for beginers to bin, smooth and
% generate a polar ratemas. This is the partner function to
% easy_make_ratemap (which does something similar for a polar ratemap)
%
% ARGS
% data      [structure] the standard data strucutre returned by read_DACQ.m

% tet       [scalar] the tetrode number that we're interested in

% cell      [scalar] the cell number we're interested in

% exactCut  [col vector] output of read_cut_file.m specifying for the given
%           tetrode which spikes belong to which cells


%
% RETURNS 
% smthDir   [nBins x 1] Col vector of firing rate in each polar bin. Note
%           count round in CCW direction from x-axis. Final polar map is
%           smoothed with a boxcar of width 5 bins - each bin being 6deg.


% --- MAIN ---------------------------------------------------------------

%Assume we want a 6deg bins (i.e. 60 bins) bin direction data to determine 
% how long the animal spent facing each direction t
binDir      =bin_data('dwell', 'direction', 6, data.pos);


%Then bin the spikes to get the spike count for the same direction bins -
%first have to find the spike times of the spikes from the cell we're
%interested in
ind2use     =exactCut==cell;
ind2use     =ind2use(1:length(data.tetrode(tet).pos_sample)); %Truncate as it's sometimes too long
spkPosSmp   =data.tetrode(tet).pos_sample(ind2use); %Pos sample for each spike from this cell
binSpk      =bin_data('spikes', 'direction', 6, data.pos, spkPosSmp);


%Finally divide the spike count for each bin by the amount of time the
%animal spent in that bin and smooth to get a nice looking ratemap -
%smoothing is 5 bin boxcar (i.e. each bin in the final ratemap is set to
%be the mean of it's own value and the value of the surounding bins upto 2
%bins away) - this is standard.
smthDir     =make_smooth_ratemap(binDir, binSpk, 5, 'boxcar', 'circ');
smthDir     =smthDir(:); %Force to col vect


end

