function [tstLn, tstLnBnd]   =lineTraj_define_line(szPM2, spd2Test, yRange)
% Function primarily called by lineTrajDecode used to define the line
% (tstLn) and mask around that line (tstLnBnd) that are tested against each
% posterior. 
%
% This was an inline function but now need to access it with other
% functions - basically to get a copy of the line mask that best fits the
% pcPosterior to check against the grid posterior.
%
% Define line and band - y extent of line is equivalent to gradient *
% size(pMat,2) + the  band width. Define that line as a set of 1s in
% a mat of zeros. Then expand to include the band by il_filter2 with a
% kernel of the band width. Note always build the line as a +vs gradient
% and flip if gradient is -ve
%
% ARGS
% szPM2         size of the j dim of pMat (i.e. size(pMat,2))
%
% spd2Test      gradient of line to build defined in terms of sBins per
%               tBin (dim1 of the pMat being spatial and dim2 time)
%
% yRange        Define size of 'band' around line that is used to 
%               calculated it's goodness of fit. This value should be an 
%               integer and indicates the number of bins above and below 
%               (in the y-axis) that are counted. Must be >0 and should be 
%               an an number

if ceil(abs(spd2Test)) == 0 %If gradient is 0 hard code tstLn
    tstLn           =ones(1, szPM2);
    
else %Otherwise do the normal thing
    tstLn           =zeros(round( (szPM2-1) * abs(spd2Test) )+1, szPM2);
    %NL for each x bin determin the y bin of the line based on gradient -
    %note I'm treating the first xbin as 0.
    tstLnY          =round([0:(szPM2-1)] .* abs(spd2Test))+1;
    tstLn(sub2ind(size(tstLn), tstLnY', (1:szPM2)'))        =1;
end

% Create the kernel that is used to define the ROI around the line - this
% might be a hard cut off or a graded area. Comment following lines to
% control this.
% line - this is convolved with the line to get the graded matrix.
% COMMENT ONE OF THE NEXT TWO BLOCKS
% 1) [uncomment for graded line]
% kern            =[1:yRange, fliplr(1:yRange-1)]'; %Graded
% kern                =kern./max(kern); %Peak of kern is set to 1
% 2) [uncomment for cut off line]
kern            =ones(2*yRange +1, 1);             %Hard cut off all 1


tstLn           =padarray(tstLn, [yRange,0]);
%NL is meant to be filter2 - don't need to use il_filter2 here
tstLnBnd        =filter2(kern, tstLn); %Now line with boundary
if sign(spd2Test) == -1;
    tstLn=flipud(tstLn);
    tstLnBnd=flipud(tstLnBnd);
end
end

