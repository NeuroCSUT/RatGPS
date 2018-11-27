function data = read_KwikRPi(folder_path,varargin)
%READ_KWIKRPI Loads OpenEphys Kwik format recorded with RPi cameras

%   folder_path - full path of data folder
%                 [] or '' if you wish to use dialog box to select folder
%   'nopos'     - no position data is loaded and spikes are not clipped
%   'waveforms' - loads waveform shapes
%   'eeg'       - loads eeg for each tetrode

% Get target folder path if no input
if nargin == 0 || isempty(folder_path)
    folder_path = uigetdir;
end

% Find files in folder
RawDataFile = dir(fullfile(folder_path,'*.raw.kwd'));
if length(RawDataFile) == 1
    RawDataFile = fullfile(RawDataFile(1).folder,RawDataFile(1).name);
else
    error('No Raw Data File')
end
SpikeDataFile = dir(fullfile(folder_path,'*.kwx'));
if length(SpikeDataFile) == 1
    SpikeDataFile = fullfile(SpikeDataFile(1).folder,SpikeDataFile(1).name);
else
    error('No Spike Data File')
end
EventDataFile = dir(fullfile(folder_path,'*.kwe'));
if length(EventDataFile) == 1
    EventDataFile = fullfile(EventDataFile(1).folder,EventDataFile(1).name);
else
    error('No Event Data File')
end
PosDataFile = fullfile(folder_path,'PosLogComb.csv');
if length(dir(PosDataFile)) ~= 1
    error('No position data file')
end

% Create data structure
data.flnm = SpikeDataFile;
data.path = SpikeDataFile;
data.settings = cell(0);
data.tetrode = struct;
data.pos = struct;
data.eeg = struct;
data.settings = [data.settings; {'lightBearing_1','180'}];
data.settings = [data.settings; {'lightBearing_2','0'}];

% Get variables for adjusting data
badChans = load(fullfile(folder_path,'BadChan'));
sampling_rate_RawData = 30000; % Hz
session_start_sample = h5read(EventDataFile,['/event_types/Messages/events/time_samples']);
session_start_sample = session_start_sample(1);
if ~exist('vars')
    vars=default_vars; %Load default_vars if not specified
end

% Get position data
if isempty(varargin) || ~strcmp('nopos',varargin)
    posData = csvread(PosDataFile);
    % Resample position data to exactly 30 Hz
    posSamplingRate = 30;
    originalPosTimes = posData(:,1);
    newPosTimes = originalPosTimes(1):(1/posSamplingRate):originalPosTimes(end);
    newPosData(:,1) = newPosTimes;
    for ii = 2:5
        newPosData(:,ii) = interp1(originalPosTimes,posData(:,ii),newPosTimes,'linear');
    end
    posData = newPosData;
    % Fill the pos data structure
    data.pos.led_pos = zeros(size(posData,1),2,2);
    data.pos.led_pos(:,1,:) = round(4 * posData(:,[2,3]));
    data.pos.led_pos(:,2,:) = round(4 * posData(:,[4,5]));
    data.pos.led_pix = zeros(size(posData,1),2);
    data.pos.led_pix(:,1) = 20;
    data.pos.led_pix(:,2) = 5;
    data.pos.header = cell(0);
    data.pos.header = [data.pos.header; {'pixels_per_metre','400'}];
    data.pos.header = [data.pos.header; {'sample_rate',num2str(posSamplingRate)}];
    data.pos.header = [data.pos.header; {'window_max_x',num2str(max(data.pos.led_pos(:,1,1)))}];
    data.pos.header = [data.pos.header; {'window_min_x',num2str(min(data.pos.led_pos(:,1,1)))}];
    data.pos.header = [data.pos.header; {'window_max_y',num2str(max(data.pos.led_pos(:,1,2)))}];
    data.pos.header = [data.pos.header; {'window_min_y',num2str(min(data.pos.led_pos(:,1,2)))}];
    % Post-process position data
    [data.pos.xy data.pos.dir data.pos.speed, ~, ~, data.pos.n_leds, data.pos.dir_disp] = ...
        postprocess_pos_data(data.pos, vars.pos.maxSpeed, vars.pos.boxCar, data.settings);
end

% Load tetrode data
tetrodeFileInfo = hdf5info(SpikeDataFile);
n_tetrodes = length(tetrodeFileInfo.GroupHierarchy.Groups.Groups);
for n_tet = 1:n_tetrodes
    data.tetrode(n_tet).id = n_tet;
    data.tetrode(n_tet).header = cell(0);
    data.tetrode(n_tet).timestamp = h5read(SpikeDataFile,['/channel_groups/' num2str(n_tet-1) '/time_samples']);
    data.tetrode(n_tet).timestamp = data.tetrode(n_tet).timestamp - session_start_sample;
    data.tetrode(n_tet).timestamp = double(data.tetrode(n_tet).timestamp) / sampling_rate_RawData;
    if ~isempty(varargin) && strcmp('waveforms',varargin)
        data.tetrode(n_tet).header = [data.tetrode(n_tet).header; {'sample_rate',[num2str(sampling_rate_RawData) ' hz']}];
        data.tetrode(n_tet).spike = h5read(SpikeDataFile,['/channel_groups/' num2str(n_tet-1) '/waveforms_filtered']);
        data.tetrode(n_tet).spike = permute(data.tetrode(n_tet).spike,[3,2,1]); % Fix the order of dimensions
    end
    % Load cut file if available
    CluFile = dir(fullfile(folder_path,['Tet_' num2str(n_tet) '_*.clu.0']));
    if length(CluFile) == 1
        CluFile = fullfile(CluFile(1).folder,CluFile(1).name);
        tmp = load(CluFile);
        data.tetrode(n_tet).clusterIDs = tmp(2:end);
        SpikesUsedFile = dir(fullfile(folder_path,['Tet_' num2str(n_tet) '_*.SpikesUsed']));
        SpikesUsedFile = fullfile(SpikesUsedFile(1).folder,SpikesUsedFile(1).name);
        idx_spikes_keep = logical(load(SpikesUsedFile));
        data.tetrode(n_tet).timestamp = data.tetrode(n_tet).timestamp(idx_spikes_keep);
        if ~isempty(varargin) && strcmp('waveforms',varargin)
            data.tetrode(n_tet).spike = data.tetrode(n_tet).spike(idx_spikes_keep,:,:);
        end
    end
    % Assign position value to each spike
    if isempty(varargin) || ~strcmp('nopos',varargin)
        data.tetrode(n_tet).pos_sample = ceil(mean(data.tetrode(n_tet).timestamp,2).*posSamplingRate);
%         inRangeSpikes= data.tetrode(n_tet).pos_sample <= size(data.pos(1).led_pos, 1);
%         data.tetrode(n_tet).pos_sample=data.tetrode(n_tet).pos_sample(inRangeSpikes,:);
    end
end

if ~isempty(varargin) && strcmp('eeg',varargin)
    % Load eeg of first channel on each tetrode. 
    % If first channel on tetrode is a bad channel, take next channel.
    eegSamplingRate = 250; % Hz to downsample the raw recording to
    rawFileInfo = h5info(RawDataFile,'/recordings/0/data');
    rawFileSize = rawFileInfo.Dataspace.Size(2);
    for n_tet = 1:n_tetrodes
        n_tet_successful = 1;
        n_tet_chan = 1;
        while true
            n_chan = n_tet_chan + (n_tet - 1) * 4;
            if ismember(n_chan,badChans)
                n_tet_chan = n_tet_chan + 1;
            end
            if n_tet_chan > 4
                break
            end
        end
        if n_tet_chan > 4
            disp(['Tetrode ' num2str(n_tet) ' has no viable channels'])
        else
            eeg = h5read(RawDataFile,'/recordings/0/data',[n_chan,1],[1,rawFileSize]);
            eeg = downsample(eeg,sampling_rate_RawData/eegSamplingRate);
            timestamps = 0:(1/eegSamplingRate):(rawFileSize/sampling_rate_RawData);
            data.eeg(n_tet_successful).eegCh = n_tet_successful;
            data.eeg(n_tet_successful).actualCh = n_chan;
            data.eeg(n_tet_successful).timeseries = [eeg(:),timestamps(:)];
            data.eeg(n_tet_successful).header = {'sample_rate',[num2str(sampling_rate_RawData) ' hz']};
            n_tet_successful = n_tet_successful + 1;
        end
    end
end

end

