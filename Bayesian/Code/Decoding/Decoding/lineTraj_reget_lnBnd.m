function lnBnd = ...
    lineTraj_reget_lnBnd( pMatSz, spd, yInterc, yRange)
%LINETRAJ_REGET_LNBND Regenerate line band to compare with other pMat
% As part of control process for grid-pc replay project want to compare
% best line mask from one pMat with others to measure 'chance'. Other pMats
% from the same experiment will have the same number of spatial bins (dim1)
% but can have different temporal lengths (dim2) so can't just use the line
% mask returned by lineTraj_decode.
%
% ARGS
% pMatSz        [1x2] Size of target pMat
%
% spd           gradient of line to build defined in terms of sBins per
%               tBin (dim1 of the pMat being spatial and dim2 time)
%
% yInterc       yIntercept of best fit line (returned by lineTraj_decode)
%               basically is posBin of intercept
%
% yRange        Define size of 'band' around line that is used to 
%               calculated it's goodness of fit. This value should be an 
%               integer and indicates the number of bins above and below 
%               (in the y-axis). Should match the value used in
%               lineTraj_decode
%
% RETURNS
% lnBnd      The logical mask of the pMat defined by the args
%

%Create zeros the size of the target pMat but expanded on top & bottom
lnBnd           =zeros(pMatSz(1)*3, pMatSz(2)); 

%Put line through it 
lnBndX          =(1:pMatSz(2))-1;
lnBndY          =round(lnBndX .* spd) +yInterc +1 + pMatSz(1);
outOfRng        =(lnBndY<1) | (lnBndY>(pMatSz(1)*3));   %Find too big y ...
lnBndX          =lnBndX(~outOfRng);                 %... and remove from ..
lnBndY          =lnBndY(~outOfRng);                 %... both x & y

lnBnd(sub2ind([pMatSz(1)*3, pMatSz(2)], lnBndY, lnBndX+1))=1; 

%Convolve with kernel to get the appropriate width
kern            =ones(2*yRange +1, 1);             %Hard cut off all 1
lnBnd           =filter2(kern, lnBnd); 

%Finally remove extra padding from top and bottom to get back to the
%required pMatSz
lnBnd           =lnBnd(pMatSz(1)+1: pMatSz(1)*2, :);

end

