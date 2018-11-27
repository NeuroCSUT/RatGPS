function [ vars ] = default_vars( )

%DEFAULT_VARS Fucntion that contains default varaibles - called in other
%functions
 
%%% DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vars.dataDir ='d:\data'; %Directory containing users DACQ data
% vars.dataDir='/Users/caswellbarry/Dropbox/';
% vars.dataDir='E:\data';


%%%POSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vars.pos.maxSpeed = 2; %Speeds above this are considered to be jumpy (m/s) NOTE UNITS - used by postprocess_pos_data
vars.pos.minSpeed = 2; %Speeds below this are consider to be stationary (cm/s) NOTE UNITS - not sure where this is used
vars.pos.boxCar =0.4; %Position smoothing boxcar width (s)


%%% RATEMAPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vars.rm.binSizePos=8; %Size of bin - 8 is equal to old Tint
vars.rm.binSizePosCm=2; %Size of bins in cm - used with reference to pix/m
vars.rm.smthKernPos=5; %Size of box car kernel used to produce smooth rm/ bins
vars.rm.binSizeDir=360/60; %Size of polar bins in deg
vars.rm.smthKernDir=5; %Size of box car kernel used to smooth polar plot/ bins
vars.rm.dirGausSigma=10; %Sigma in deg for creating a gaussian kern for smoothing dir
vars.rm.dirGausXRange=(-5:5).*vars.rm.binSizeDir; %Range for which dir gaus defined

%Analysis of ratemap size, regularity etc
vars.rm.minFieldSize=35; %Min size of valid fields in bins
vars.rm.adaptiveSmoothAlpha=200; %Alpha for adapative smoothing to go with Skaggs info


%%% SACS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vars.sac.gausSigma=3.5; %Width of Gaussian in bins - for smoothing SAC


%%% DACS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vars.dac.binSize=1; %Size of dac bins in cm
vars.dac.props.smthKern=[20,4]; %Smth  with gaus this wide and with this sigma both vals in cm. Set to 0 for no smoothing
vars.dac.props.entropyRange=100; %Range of dac to calculate entropy over


%%% EEG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Controls which eeg channels to load options are as follows
%0 - load no eeg
%1 to maxCh - load eeg channel 1,2,3 etc - multiple
%   channels can be specified i.e. [1,3] would load ch1 and 3
%'all' - load all valid channels
vars.eeg.eeg2load='all';

%Instantaneous analytic analysis
vars.eeg.inst.thetaFilt=[7,11]; %Range to filter EEG in to get theta
vars.eeg.inst.badCycleThresh=0; % [1.5*10^9]Theta cycles with power below this are ignored (used for eeg and intrinsic analysis) - not sure of units
vars.eeg.inst.speedBins=[2.5:2.5:30]; %Edge of speed bins in which instant freq is binned - 
vars.eeg.inst.fit2bins=[2,11]; %Range of bins used to fit linear - bins relate to speedBins - Ali fits to bins 5 to 30 (2.5 width bins)

%Basic power spectra analysis
%Smth eeg power spec with gaus this wide and with this sigma (std not variance - sigma^2 is variance) both vals in Hz
vars.eeg.powerSpec.smthKern= [2, 0.1875];  %Note my sigma is set to match Ali's - previously used 0.5
vars.eeg.powerSpec.minSpeed=5; %in cm/s eeg below this speed not analyses
vars.eeg.powerSpec.medianSpeed=15; %in cm/s speed to downsample median to - could use over all median
vars.eeg.powerSpec.minRunLength=0.4; %min continous run length in seconds
vars.eeg.powerSpec.thetaRange=[7 11]; %Range in Hz to look for peak in
vars.eeg.powerSpec.maxFreq=25; %Top limit to truncate powerspec at - not SN is calcluated against this range
vars.eeg.powerSpec.s2nWdth=1; %Width of band around theta peak to calc signal to noise for 1hz is normal
vars.eeg.powerSpec.s2nThresh=5; %S2N must be above this to be reliable

%Sliding window EEG freq analysis
vars.eeg.slideWin.thetaRange=[7 11]; %Range in Hz to look for peak in
vars.eeg.slideWin.acWindow2Use=0.5; %Portion of autocorr to use for power spec
vars.eeg.slideWin.winSize=5; %Size of window to move along spike train in s
vars.eeg.slideWin.winOverlap=4; %Amount of overlap between adjacent windows in s
vars.eeg.slideWin.nSpeedBins=0; %Number of speed bins to combine data into

%%% Inter-spike Interval %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vars.isi.binWidth=0.01; % in s, width of isi bins 10ms [0.01] would be normal

%%% INTRINSIC FREQS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Auto corr method
vars.int.ac.minSpeed=5; % in cm/s spikes emited below this not used (prev used 2 but still got 98% data)
vars.int.ac.maxSpeed=50; %in cm/s speeds above this might be spurious so truncate
vars.int.ac.resampSpeed=15; % in cm/s, speed to resample to to control speed effects.
vars.int.ac.resampSpeedTolerance=0.5; % cm/s how close to resample speed (above) need to get to be valid
vars.int.ac.thetaRange=[7 11]; %Range in Hz to look for peak in
vars.int.ac.binSize = 0.002; %Size of bin in seconds used in autocorr - should always divide exactly into pos rate of 50hz
%NL Min contiguous chunk of pos in s NB if this exactly matches acWindowSize can get a
%situation where the pos chunk is exactly this length in which case the ac will be this
%length minus a bin. Therefor minChunkSize must always exceed acWindow by at least one
%position bins worth of time i.e. 1/50s i.e. 0.02
%NB2 Note good for minChunkSize to be larger than acWindow2Use so that some points are not
%calcuate with v.few overlap points
vars.int.ac.minChunkSize=0.42; 
vars.int.ac.acWindow2Use=0.4; %Portion of autocorr window to use for power spec
vars.int.ac.smthKern= [2, 0.5]; %Smth eeg power spec with gaus this wide and with this sigma both vals in Hz
vars.int.ac.maxFreq=125;%Top limit to truncate powerspec at - not SN is calcluated against this range
vars.int.ac.s2nWdth=1; %Width of band around theta peak to calc signal to noise for 1hz is normal

%Instant Hilbert method - doesn't work that well
vars.int.inst.maxElapsedCycles=2; %Max cycles with no spikes in which theta can be calculated across. 1=only adjacent cycles allowed
vars.int.inst.speedBins=0:5:30; %Edge of speed bins in which intrinsic freq is binned
vars.int.inst.fit2bins=[2,5]; %Range of bins defined above in speedBins in which to fit linear to
vars.int.inst.minSpeed=2.5; %Only used when looking at phase of individual spikes - spikes emited at speed less than this are not used

%Sliding window int freq analysis (comparable to approach used on EEG
vars.int.slideWin.thetaRange=[7 11]; %Range in Hz to look for peak in
vars.int.slideWin.acWin2Use=0.5; %Portion of autocorr to use for power spec
vars.int.slideWin.winSize=10; %Size of window to move along spike train in s
vars.int.slideWin.winOverlap=9; %Amount of overlap between adjacent windows in s
vars.int.slideWin.minSpkInWin=6; %Min no of spikes for a window to be valid
vars.int.slideWin.nSpeedBins=0; %Number of speed bins to combine data into - 0 is unbinned otherwise use 3 or 4
