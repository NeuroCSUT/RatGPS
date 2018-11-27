function image_rm( rm, color2use)
% IMAGE_RM Visualise a ratemap using standard parameters
% Draws a ratemap (which is passed in as 2d mat) using the standard tint 5
% colour levels as default (each being 20% of the peak value). If specified
% a different matlab colormap can be passed in. 
%
% Adds a title specifying the peak rate and marks unvisted bins as white.
% NB this function requires the tint color map (contained in
% tintColorMap.m) to be in the path.
%
%
% ARGS
% rm        [2d mat] firing rate in each bin with unvisted set to nan
% 
% color2use ['string'] Default is 'tintColorMap' specifies the colormap to 
%           use for drawing the ratemap. e.g 'parular(10)' for a ten level 
%           default map.
%
% EXAMPLES
% image_rm(rm) %Will draw a default five level tint ratemap
%
% image_rm(rm, 'parula(10)') %Will draw with 10 levle matalb default

% Prep
% NL. Not previously had to switch to opengl to stop text getting flipped
% but this is not supported on mac - might also not be a problem on PC now.
% opengl      software %need to do this to avoid text getting flipped

% --- HOUSE KEEPING ---
%Deal with situation when color2use not passed in - this should resovle to
%'tintColorMap'
if nargin==1
    color2use             ='tintColorMap';
end



% --- DRAW THE MAP ---
unvisted    =isnan(rm);
h           =imagesc(rm); %Use imagesc to do the hard work
axis        equal off; %Axis should have same scale but hide them
colormap(eval(color2use));
set(h,'AlphaData', ~unvisted); %Set univisted bins to white

%Now get the peak rate and add to the title
maxRate     =num2str(max(rm(:)), '%2.1f');
title([maxRate 'Hz']);

end

