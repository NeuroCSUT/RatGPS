function [binned_array, binned_index] = ...
    bin_data(var2bin, var2binby, binSize, posdata, pos2use)
% BIN_DATA Bins spike and pos data into polar or spatial ratemaps
% NB. This code is closley derived from mTint files of a similar name but
% those files are now incomparable with use outside of mTint. Also note
% this code previously called bin_pos_data but that function has now been
% incorporated into this one. Binning is done by histnd which has also been
% extensivly rewriten for speed.
%
% NB. Assumes that posdata.xy has already had the window extent subtracted
% from it (i.e. [0,0] is the top left corner of the tracked window not the
% whole camera window). This is generally the case
%
% Generally next step after binning by this function will be
% make_smooth_ratemap.m which smooths both dwell_time and spikes then
% divides to get a ratemap. Note if using 'pxd' option then returned arrays
% are already rates and will need to be smoothed which can also be done by
% make_smooth_ratemap.m (see notes in that function).
%
% Note1. When using 'pxd' it is important that the number of spatial bins
% and number of directional bins are roughly equal (probably within a
% factor of two). This likely means spatial bins will be large (i.e. ~4cm
% for a 1m square) while directional bins will be narrow (i.e. 1deg or
% 0.5deg)
%
% Note2. This function can also return a second variable indicating for
% each data point in pos2use the location within binned_array that it is
% allocated to. This is returned as an index and is not returned for 'pxd'.
% It is only calculated if the second  variable is requested).
%
%
% ARGUMENTS
% var2bin           [string] Specifies what is being counted and hence what
%                   units of returned binned_array is:
%                   'dwell_time' or just 'dwell' returned array is in
%                   seconds (i.e. nPosSample divided by sample rate;
%                   'spikes', returned array is in spike counts.
%
% var2binby         [string] Specify what to bin:
%                   'position' creates a spatial map;
%                   'direction' polar map;
%                   'speed' histogram over speed;
%                   'pxd' is a special case calls the pxd code and returns
%                   binned_array as a cell array with {1} being pos and {2}
%                   being dir. For 'pxd' the var2bin is ignored as the
%                   values returned are always rates. Note for 'pxd' make
%                   sure the number of spatial bins and directional bins
%                   are roughtly similar
%
% binsize           [vector of length 1 or 2] Specifies size of the bins
%                   to use for bining. For 'position' bin size is assumed
%                   to be square (i.e. binsize * binsize) and the range to
%                   be binned is the area tracked by the camera (using
%                   window_min_x etc). If bining position then the units
%                   are pixels. If binning direction the units are degrees
%                   and should exacly evenly into 360 [typical value 6]. If 
%                   var2binby='pxd' then must provide a bin size for pos 
%                   then dir [posBinSz, dirBinSz]
%
% posdata           Position data in the format of the pos branch of the
%                   tint structure i.e. tintStructure(index).data{i}.pos
%
% pos2use           [vector or not speicified] List of samples to be binned
%                   (e.g. the position samples corresponding to spikes
%                   being fired by a given cell, or the entire list of
%                   positions, or those facing North etc etc). Can include
%                   repeats of a given position sample. If not speicified
%                   each pos sample is counted once.
%
%
% RETURNS
% binned_array      Requested data binned as required - ij format (y, x)
%                   for binning by 'position', row vector for 'direction',
%                   and 'speed'. If 'pxd' is specified then a cell array
%                   with four elements is returned. The first being the pos
%                   ratemap (in Hz) and the second being the polar ratemap
%                   (in Hz), the 3rd being the binned posmap (i.e. dwell
%                   time) calculated without using the pxd algorithm
%                   (useful for smoothing), the 4th being the binned dwell
%                   time for each directional bin.
%
% binned_index      [vector or mat] [length(pos2use), nD] For each data
%                   point in pos2use the corresponding index in
%                   binned_array. Can only be returned for 'position'
%                   'direction' NOT 'pxd'
%
%
% EXAMPLE
% binXY             =bin_data('dwell_time', 'position', binSizePix, data.pos, spkPos);
% Will produce the spike count in each spatial bin
%
% [binDir, binInd]   =bin_data('dwell_time', 'direction', vars.rm.binSizeDir, data.pos);
% Will produce the dwell time count in each directional bin i.e. not
% specifiying which pos is the equivalent of allPos. Also returns for all
% pos points which of the directional bins it lies in. A typical value for
% binSizeDir would be 6 (i.e. 6deg indicating a total of 60 bins)
%
% binCellArray      =bin_data('spikes', 'pxd', [posBinSz, dirBinSz], data.pos, spkPos);
% Will return a 2 element cell array after running pxd code, first is pos
% and second is dir.


% STILL TO DO
% 1) Check fully back compataable with what bin_data and cb_bin_data used
% to do
% 2) Check the pxd code works
% 3) Check orientation of ratemap and directional plots match tint

% --- HOUSE KEEPING ---
%Deal with situation when pos2use not passed in - this should resovle to
%the equivalent of allPosBin
if nargin==4
    pos2use             =1:length(posdata.xy);
end

if nargin <4
    error('Not enough vars passed to bin_data.m');
end

%Convert var2binby and var2bin to lowercase
var2binby       =lower(var2binby);
var2bin         =lower(var2bin);

% --- MAIN ---
%First deal with what to bin by - final step is to deal with what to bin
%(spike or dwell time)
switch var2binby
    case 'position'
        %Define tracked area to use for position binning
        poslim          =il_getPosLim(posdata); %Get extent of tracked area
        %Now bin - note that y values are provided first
        [binned_array, nd_bins]=histnd(posdata.xy(pos2use,[2,1]), poslim, [binSize, binSize]);
        
        if nargout==2 %Also calc and return binned_index
            binned_index        =sub2ind(size(binned_array), nd_bins(:,1), nd_bins(:,2));
        end
        
        
    case 'direction'
        posdata.dir             =posdata.dir(:); %Force to col vect
        [binned_array, binned_index]=histnd(posdata.dir(pos2use), 360, binSize);
        
        
    case 'speed'
        max_speed       =max(posdata.speed);
        [binned_array, binned_index]=histnd(posdata.speed(pos2use,:), max_speed, binSize);
        
        
    case {'pxd'}
        % Do pxd analysis - note pxd algorithmn will return both a p and d
        % estimate and both are returned
        % Note also must specify a posBin size and dirBin size
        poslim          =il_getPosLim(posdata); %Get extent of tracked region
        
        if isempty(pos2use) %Deal with situation in which there are no pos specified
            array_size      =ceil([360, poslim] ./ [binSize(2), binSize(1), binSize(1)]);
            binned_array{1,3}=zeros(array_size(2:3));
            binned_array{2,4}=zeros(array_size(1),1);
            
            
        else %And situation where there are actually possamp specified
            %Bin spikes then raw data into the 3D mat needed for pxd (i.e.
            %[dir, posY, posX])
            allPos          =1:length(posdata.xy);
            spkDirPos       =[posdata.dir(pos2use), posdata.xy(pos2use,[2,1])];
            allDirPos       =[posdata.dir(:), posdata.xy(:, [2,1])];
            spkBin          =histnd(spkDirPos, [360, poslim], [binSize(2), binSize(1), binSize(1)]);
            allBin          =histnd(allDirPos, [360, poslim], [binSize(2), binSize(1), binSize(1)])./50; %in seconds
            [binned_array{1}, binned_array{2}]=pxd(spkBin, allBin);
            binned_array{3} =histnd(posdata.xy(allPos,[2,1]), poslim, [binSize(1), binSize(1)]);
            binned_array{4} =histnd(posdata.dir(allPos,:), 360, binSize(2))';
            return
        end
        
        %Make a check to see if the number of bins in dir and pos are
        %roughly equal and return warning if not
        if numel(binned_array{3})>(numel(binned_array{4})*2) || ...
                numel(binned_array{4})>(numel(binned_array{3})*2)
            warning('In pxd no. spatial and directional bins are not roughly equal');
        end
        
        if nargoout==2
            %Binned index requested but don't currently calcuate for pxd so
            %return nan instead.
            binned_index    =nan;
        end
        
    otherwise
        error('var2binby = %s is not recognised\n', var2binby);
end


% Now deal wtih what to bin - if dwell time need to convert to seconds by
% dividing by sample rate
switch var2bin
    case {'dwell', 'dwell_time'}
        pos_sample_rate =key_value('sample_rate', posdata.header, 'num');
        binned_array    =binned_array./pos_sample_rate;
        
    case 'spikes'
        % Don't currently need to do anything special - previously had a
        % test in here to transpose binned_arry if it was empty. This was
        % due to a bug in histnd which transposed the empty array
        
    otherwise
        error(' var2bin = %s unrecognised in bin_data\n', var2bin);
end

%Force output to be a row vector (if it is a vector)
if size(binned_array,2) == 1
    binned_array = binned_array';
end
end



% ---- SUBFUNCTION -----
function poslim  =il_getPosLim(posdata)
% For 2D spatial return the extent of the window that was tracked

win_max_x       =key_value('window_max_x', posdata.header, 'num');
win_min_x       =key_value('window_min_x', posdata.header, 'num');
win_max_y       =key_value('window_max_y', posdata.header, 'num');
win_min_y       =key_value('window_min_y', posdata.header, 'num');


poslim          =[win_max_y - win_min_y, win_max_x - win_min_x];

end