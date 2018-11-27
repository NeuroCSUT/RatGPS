%Check everything is working by looping through master pMat (3D has lots of
%pMats). Find the best fit line and the residual, recreate that line and
%recalucate the residual then check this is the same.

load pMat_data; %Loads a 3D mat t2POS_popVect_pMat

for nn      =1:size(t2POS_popVect_pMat,3)
    
   pMat         =t2POS_popVect_pMat(:,:,nn);
   
   %Get line fit
   [ bstRes, bstSpd, bstYInterc, bstTstLnBnd] =   lineTraj_decode( pMat, 0.005, 2, 14 );
   
   %Recreate the line
   lnBnd = ...
    lineTraj_reget_lnBnd( size(pMat), bstSpd(1), bstYInterc, 14);
    
    %Recalc residual
    resTest     =lineTraj_get_res(pMat, lnBnd);
    
    fprintf(['Loop=' num2str(nn) ' Res=' num2str(bstRes) ' Recreated=' num2str(resTest)]);

    if bstRes == resTest
        fprintf('\nMATCH');
    else
        fprintf('\nNO MATCH');
    end
    
    fprintf('\nHit a key ...\n');
    pause
    
end