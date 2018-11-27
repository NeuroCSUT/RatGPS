function [smthRm, smthPos, smthSpk]= make_smooth_ratemap(binPos, binSpk, kernSize, kernType, smthType)
% MAKE_SMOOTH_RATEMAPS Gets rate from spike & dwell  with smoothing
% Takes binned pos and spikes to produce ratemap - works with either 2D
% spatial data or 1D head direction data (in which case smoothing is done
% in circular space with ends wrapping). Smoothing kernel can with either a
% boxcar or gaussian (specified with 'boxcar' or 'guas').
%
% NOTE SPECIAL CASE TO DEAL WTIH RATE. e.g. pxd code returns rate, it's not
% possible to smooth dwell and spikes before dividing. To just apply the
% standard smoothing to rate but still mark out unvisted bins with nans
% supply the first variables (binPos) as a logical array of 1s for visited
% bins and 0s for unvisted bins. e.g. if using bin_data with the 'pxd'
% switch then the 3rd cell of the returned array is the binned pos map and
% this can be used after doing logical on it. Then supply binSpk as the 
% binned but unsmoothed ratemap. NB if using rate then only the first 
% returned variable (smthRm) is meaningful. NB2 when smoothing rate the
% unvisted bins (specified in binPos) are ignored.
%
% Note smoothing ignores unvisited bins and is applied to dwell and spikes
% indepedently before they are combined.
%
%
% TAKES
% binPos        [nx1 or nxn] binned dwell time data or if dealing with rate
%               data specify as a logical array (with 1 for visited bins
%               and 0 for unvisted)
%
% binSpk        [same as binPos] binned spike number or if dealing with
%               rate an unsmoothed ratemap
%
% kernSize      [scalar] size of smth kern in bins (interpretation depends
%               on kernType if 'boxcar' is the width if 'gaus' is the
%               sigma). Typically 5 for 2D and 3 for 1D
%
% kernType      ['boxcar' or 'gaus'] where 'boxcar' smooths with a typical
%               square kernel of size kernSize and 'gaus' smooths with a
%               gaussian with sigma=kernSize. If not specified default to
%               'boxcar'
%
% smthType      ['norm' or 'circ'] 'norm' specifies no wrapping and is used
%               for a typical 2D ratemap or other non-circular variables
%               and 'circ' assumes circular variable hence edges wrap. If
%               not specified defaults to 'norm'



%RETURNS
% smthRm        Ratemap [nxn] or [nx1] smoothed ratemap
%
% smthPos       Smoothed dwell time map used to make smthRm
%
% smthSpk       Smoothed spike count map used to make rmthRm



% EXAMPLE
% smthRM=make_smooth_ratemap(binPos, binSpk, 3 );
%       Will defualt to boxcar normal smoothing
%
% smthDir=make_smooth_ratemap(binPos, binSpk, 5, 'gaus', 'circ');
%       Will smooth using a gaussian kernel in circular space i.e. wraps
%       ends of ratemap when smoothing


% --- HOUSEKEEPING --------------------------------------------------------
if nargin==4; %smthType not specified default to 'norm'
    smthType    ='norm';
end

if nargin==3; %smthType defaults to 'norm' and kernType to 'boxcar'
    smthType   ='norm';
    kernType   ='boxcar';
end

%Test to see if we're working with spikes & dwell or rate
binSpk          =lower(binSpk);
if islogical(binPos)
    rate        =true;
elseif isnumeric(binPos);
    rate        =false;
else
    error('binPos must me numeric or logical')
end


% --- MAIN ----------------------------------------------------------------


% --- CREATE KERN TYPE

switch kernType
    case 'boxcar'
        kern=ones(kernSize);
    case 'gaus'
        kern=fspecial('gaussian', size(binPos), kernSize); %Creats normalised gaus kern
end


% --- SET TYPE OF SMOOTHING
% Type of smoothing is passed as a switch into imfilter - set these options

%Standard options in all cases
%NB must have conv otherwise default in imfilter is corr which introduces own
%normalisation
options     ='''same'', ''conv''';

switch smthType
    case 'norm'
        %no additional options required
    case 'circ'
        options     =[options, ', ''circular''']; %periodic signal used for direction
end


% --- NOW DO SMOOTHING
%First make mask of unvisted positions used to normalise filter
%Have to be very careful with imfilter as it treats a logical mat differently to a normal
%number mat.

visPos          =double(binPos~=0); %1 in visted bins 0 otherwise

if rate %If dealing with rate set unvisted bins to 0
    binSpk(binPos==0)   =0;
end

% Smooth pos and spike before dividing and normalise each
eval(['denom=imfilter(visPos, kern, ', options,');']);
eval(['smthPos=imfilter(binPos, kern, ', options, ')./denom;']);
eval(['smthSpk=imfilter(binSpk, kern, ', options, ')./denom;']);

if rate
    smthRm      =smthSpk;
else
    smthRm      =smthSpk./smthPos; %Divide to get rate
end


% --- FINALLY PLACE NAN IN UNOCCUPIED LOCATIONS
smthSpk(~visPos)    =nan;
smthRm(~visPos)     =nan;
smthPos(~visPos)    =nan;