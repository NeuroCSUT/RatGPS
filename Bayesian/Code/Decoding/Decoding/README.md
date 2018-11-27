# Decoding
Functions and test data used to decode variables (mainly position) from 
spike trains given knowledge of what the time averaged activity of each 
unit looks like.


## decode_*
Functions that deal with spikes & ratemaps in order to acctually a 
posterior probability matrix, then finally read out of that matrix to 
actually decode to a location.

decode_calcPost.m Given spikes & ratemap get posterior probability

decode_getSpkCnt.m Given spike times and decoding window size returns the 
spike count per window. Can implement overlapping windows and smoothed 
firing rates (i.e. spike rate is smoothed in time before binning)

decode_processPost.m Takes a posterior probability returned by decode_calcPost
and returns the decoded location (assuming ML decoding) as well as other 
useful values.

decode_crunchData.m The master function that calls these other decode 
functions to actually do the decoding on real data.


## lineTraj*
Code used for fitting linear trajectories to posterior probability matrices 
obtained for linear track running and typically used for decoding replay 
i.e. animal is assumed to move a fixed velocity during replay trajectory.

