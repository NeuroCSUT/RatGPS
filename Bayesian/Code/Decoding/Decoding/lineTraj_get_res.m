function [ res ] = lineTraj_get_res( pMat, bstTstLnBnd )
%LINETRAJ_GET_RESID Use a masked line & matching pMat to get residual
% lineTrajDecode finds the best linear trajectory through a pMat using a
% line and mask. This function just allows that line mask (output by
% lineTrajDecode) to be applied to an arbitary pMat (or the same pMat) to
% get the residual (i.e. amount of actiivty in the pMat accounted for by
% the mask). So if the bstTstLnBnd is applied to the pMat it was generated
% for it should give the same residual
%
% ARGS
% pMat              Posterior prob matrix with dim1 being spatial bins and
%                   dim2 being time. This is output of decoder indicating
%                   for each time bin the prob animal is at given point.
%                   Columns should sum to 1. [nPosBin x nTimeBin].
%                   Except note that columns with no data can be set to all
%                   0 (col with no data is one without spikes)
%
%
% bstTstLnBnd       The line mask for pMat (must have same dim & size as 
%                   pMat). Is a mask of zeros outside of the band and one
%                   in the band.
%
% RETURNS
% res               Single value between 0 and 1 being the proportion of
%                   of activity in the pMat 'covered' by the band

pMat(isnan(pMat))=0; 
res         =pMat.*bstTstLnBnd;
res         =sum(res(:)) / sum(pMat(:));


end

