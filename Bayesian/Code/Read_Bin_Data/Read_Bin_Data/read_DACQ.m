function [ data, cut ] = read_DACQ( pathFlnm, vars )
%READDACQ Master function to read in raw DACQ data
%  Writen by CB. Calls functions that belong to mTint toolbox (must be in
%  path) to load raw DACQ data and present it as a strucutre in matlab.
%
% ARGS - can provide 0, 1, 2
% pathFlnm - conjoined path & filname to load or leave as empty to use guiChoose
% vars - variable structure that must contain (see below) or empty for defaults
%       vars.pos.maxSpeed - speeds above this are considered to be jumpy(cm/s)
%       vars.pos.boxCar - position smoothing boxcar width (s)
%       vars.dataDir - directory containing users data
%       vars.eeg.eeg2load - which eeg channels to load [0=none, 'all']
%
% NB call 'defaultVars' to load a copy of vars with default values
%
% Returns
% data - standard tint strucutre (no longer compatable with tint gui)
% cut - cell array of cut files where they exist


% TODO
% 1) change so that only certain elements can be read in eg. spikes and not
% eeg etc, also just one or two tetrodes etc
% 2) allow different eegs to be read i.e. 1&2 just 1, all etc
% 3) read in variables from a text file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% HOUSE KEEPING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ~exist('vars')
    vars=default_vars; %Load default_vars if not specified
end

if ~exist('pathFlnm')
    currentDir=cd;
    [flnm path]=uigetfile({'*.set' 'Axona data files (*.set)'; '*.*' 'All Files (*.*)'},'Choose Data File');
    [~, flnm, ~]=fileparts(flnm); %Strip extension
    cd(currentDir);
    clear currentDir temp
else
    [path, flnm, ~]=fileparts(pathFlnm); %Strip extension
    clear temp
end

data.flnm=flnm;
data.path=[ path , filesep]; %Add directory separator for platform
clear path flnm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% START MAIN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% 1. read set file, and determine tracked colours (LEDs) and tetrodes used
[data.settings, ~] = read_binary_data([data.path, data.flnm, '.set'],'set');

ncolours_tracked=0;
ntetrodes_used=0;
for t=1:16
    if t<=4
        ncolours_tracked=ncolours_tracked+1;
    end
    tmp         =key_value(['collectMask_' num2str(t)],data.settings,'num','exact');
    if isempty(tmp) tmp=0;end
    tetrode_used(t)=tmp;
    
    ntetrodes_used=ntetrodes_used+1;
end

%%% 2. read tetrode data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%data from each tetrode is stored in
%cell arrays where the index i
%NB currently don't load the junk tetrode 0
tetrode_list=[find(tetrode_used)];
for t=1:length(tetrode_list)
    data.tetrode(t).id=tetrode_list(t);
    if exist([data.path data.flnm '.' num2str(tetrode_list(t))],'file')
        %NB. read_tetrode_file will not return spike waveforms and thus be quicker if
        %varout doesn't require it. If waveforms are required change the
        %order of commented out lines below
        %         [data.tetrode(t).header,data.tetrode(t).timestamp]=...
        %             read_tetrode_file([data.path data.flnm '.' num2str(tetrode_list(t))]);
        [data.tetrode(t).header,data.tetrode(t).timestamp, data.tetrode(t).spike]=...
            read_tetrode_file([data.path data.flnm '.' num2str(tetrode_list(t))]);
        
    else
        data.tetrode(t).timestamp='data unavailable';
        data.tetrode(t).spike='data unavailable';
        data.tetrode(t).header='data unavailable';
    end
end

%%% 3. read position data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[data.pos.led_pos data.pos.led_pix data.pos.header]=read_pos_file([data.path  data.flnm '.pos']);

%Check if pos data is present, if not continue without processing
if ~isempty(data.pos.led_pos) %if pos is present process as normal
    [data.pos.xy data.pos.dir data.pos.speed, ~, ~, data.pos.n_leds, data.pos.dir_disp] = ...
        postprocess_pos_data(data.pos, vars.pos.maxSpeed, vars.pos.boxCar, data.settings);
    
    
    %3a. fill in .pos_sample field of the tetrode structure - the position (and eeg) sample co-occuring
    % with a given spike. .timestamp is in seconds.
    pos_sample_rate = key_value('sample_rate', data.pos.header, 'num');
    for t=1:length(tetrode_list)
        if exist([data.path data.flnm '.' num2str(tetrode_list(t))],'file')
            data.tetrode(t).pos_sample = ceil(mean(data.tetrode(t).timestamp,2).*pos_sample_rate);
            %Next few lines to deal with a slight time slipage between spikes and position
            %previously could find that although there was only x position points some spikes were paired with
            %position point x+1 (i.e. pos_sample might be 60001 when there was only 60000 position points)
            %Now just remove these spikes from the tint structure
            inRangeSpikes= data.tetrode(t).pos_sample <= size(data.pos(1).led_pos, 1);
            data.tetrode(t).pos_sample=data.tetrode(t).pos_sample(inRangeSpikes,:);
        else
            data.tetrode(t).pos_sample='data unavailable';
        end
    end
else
    fprintf('Pos data not present, proceeding without it.\n');
end

% 4. read eeg data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NB on older DACQ system two eeg files could be saved *.eeg and *.eg2 on
% the new USB system upto 16 files can be saved *.eeg, *.eeg1 etc.
% In addition upto four 48kHz eeg files can be recorded - this code does not
% read them but their extensions are *.egf, *.egf2 etc.
%
% First check what version of system we're using
[ systemV, maxEEGch ] = check_DACQ_version( data.settings );


%Deterimine which of the possible eeg channels are acutally loaded
eegChUsed=zeros(maxEEGch,1);
for n=1:maxEEGch
    tmp=key_value(['saveEEG_ch_' num2str(n)], data.settings, 'num', 'exact');
    if isempty(tmp) || ~tmp %Deal with situation where it's empty is not used
        eegChUsed(n)=0;
    else eegChUsed(n)=1;
    end
end
eegChUsed=find(eegChUsed);

switch vars.eeg.eeg2load
    case '0' %Load no eeg
        loadList=[];
        data.eeg.eegCh=[];
        data.eeg.actualCh=[];
        data.eeg.timeseries=[];
        data.eeg.header=[];
        
    case 'all' %Load all used eeg channels
        loadList=eegChUsed;
        
    otherwise %Just load the channels specified - have not put any error checking in
        loadList=vars.eeg.eeg2load;
end

for n=1:length(loadList) %Go through and load all eeg specified
    
    data.eeg(n).eegCh=loadList(n); %Of the possible eeg channels which is this
    data.eeg(n).actualCh=key_value(['EEG_ch_' num2str(loadList(n))], data.settings, 'num', 'exact');
    
    %Now deal with fact that file suffix varies with ch no and system
    if loadList(n)==1
        [data.eeg(n).timeseries data.eeg(n).header]=read_eeg_file([data.path  data.flnm '.eeg']);
    else
        switch systemV
            case 'old' %Old system and channl >1
                [data.eeg(n).timeseries data.eeg(n).header]=read_eeg_file([data.path  data.flnm '.eg' num2str(loadList(n))]);
            case 'usb' %New system and channl >1
                try %Sometimes new system has old naming scheme for EEG files i.e. .eg2 - so try that
                    [data.eeg(n).timeseries data.eeg(n).header]=read_eeg_file([data.path  data.flnm '.eeg' num2str(loadList(n))]);
                catch %Try old naming scheme
                    [data.eeg(n).timeseries data.eeg(n).header]=read_eeg_file([data.path  data.flnm '.eg' num2str(loadList(n))]);
                end
        end
    end
    
end

%%% 5.Finally try to load cutfiles with standard names %%%%%%%%%%%%%%%%%%
if isfield(data, 'tetrode')
    nTet        =length(data.tetrode);
    cutStem     =[data.path, data.flnm '_'];
    for n       =1:nTet
        cutName     =[cutStem num2str(n) '.cut'];
        if exist(cutName)
            cut{n}=read_cut_file(cutName);
        end
    end
end
