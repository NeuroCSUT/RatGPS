function [ smthRm ] = easy_make_ratemap( data, tet, cell, exactCut )
%EASY_MAKE_RATEMAP Simple wrapper function to bin data & generate ratemap
% An wrapper function for beginers to control the binning, smoothing and
% generation of ratemaps.
%
% ARGS
% data      [structure] the standard data strucutre returned by read_DACQ.m

% tet       [scalar] the tetrode number that we're interested in

% cell      [scalar] the cell number we're interested in

% exactCut  [col vector] output of read_cut_file.m specifying for the given
%           tetrode which spikes belong to which cells

% vars      structure with variables describing bin size etc load from
%           default_read_vars
%
% RETURNS 
% rm        the ratemap - bin size is specified in vars

if nargin < 4
    exactCut = data.tetrode(tet).clusterIDs;
end


% --- MAIN ---------------------------------------------------------------

%Assume we want a 2cm square spatial bin - so determine what the correct
%PPM to use to get this is (i.e. based on the pixels per metre how big
%shoudl the spatial bins be in pixels?)
ppm         =key_value('pixels_per_metre',  data.pos.header, 'num'); %Get pixels per meter
binPix      =(ppm/100)*2; %Bin size in pixels


%Next bin the position data to determine how long the animal spent in each
%area of the environment
binPos      =bin_data('dwell', 'position', binPix, data.pos);


%Then bin the spikes to get the spike count for the same spatial bins -
%first have to find the spike times of the spikes from the cell we're
%interested in
ind2use     =exactCut==cell;
ind2use     =ind2use(1:length(data.tetrode(tet).pos_sample)); %Truncate as it's sometimes too long
spkPos      =data.tetrode(tet).pos_sample(ind2use); %Pos sample for each spike from this cell
binSpk      =bin_data('spikes', 'position', binPix, data.pos, spkPos);


%Finally divide the spike count for each bin by the amount of time the
%animal spent in that bin and smooth to get a nice looking ratemap -
%smoothing is 5 bin boxcar (i.e. each bin in the final ratemap is set to
%be the mean of it's own value and the value of the surounding bins upto 2
%bins away) - this is standard.
smthRm      =make_smooth_ratemap(binPos, binSpk, 5, 'boxcar');

end

