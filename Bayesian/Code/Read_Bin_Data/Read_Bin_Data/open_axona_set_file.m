function tint = open_axona_set_file(data_path, flnm, flnmroot, tetrode)

tint.file_type = 'axona_set_file';
settings = read_binary_data([data_path flnm], 'set');

% Read tetrode data
tint.tetrode.id = tetrode;
[tint.tetrode.header, tint.tetrode.timestamp, tint.tetrode.spike] = read_tetrode_file([data_path flnmroot '.' num2str(tint.tetrode.id)]);

tint.spike_times = mean(tint.tetrode(1).timestamp,2);

% Read position data
if exist([data_path flnmroot '.pos'],'file')
    tint.pos.exists = 1;
    [tint.pos.led_pos tint.pos.led_pix tint.pos.header] = read_pos_file([data_path flnmroot '.pos']);
    max_speed = 5;
    box_car = 0.2;
    [tint.pos.xy tint.pos.dir tint.pos.speed tint.pos.times] = postprocess_pos_data(tint.pos, max_speed, box_car, settings);
    tint.trial_start_time = tint.pos.times(1) - (1 / key_value('sample_rate', tint.pos.header, 'num'));
    tint.trial_end_time = key_value('duration', tint.pos.header, 'num');
    
    % Fill in .pos_sample field of the tetrode structure - the position (and eeg) sample co-occuring
    % with a given spike. Timestamp is in seconds.
    pos_sample_rate = key_value('sample_rate', tint.pos.header, 'num');

    if exist([data_path flnmroot '.' num2str(tint.tetrode.id)],'file')
        tint.tetrode.pos_sample = ceil(mean(tint.tetrode.timestamp,2) .* pos_sample_rate);
    else
        tint.tetrode.pos_sample = 'data unavailable';
    end

else
    uiwait(msgbox('NOTE: There is no positional data for this file; positional plotting will be disabled.','No pos file...','modal'));
    tint.pos.exists = 0;
    tint.pos.xy = [];
    tint.pos.dir = [];
    tint.pos.speed = [];
    tint.pos.times = [];
    tint.pos.led_pos = [];
    tint.pos.led_pix = [];
    tint.pos.header = [];
end

% Read eeg data
tint.eeg.exists = 0;
tint.eeg.exists2 = 0;
tint.trial_start_time = [];
tint.trial_end_time = [];
tint.trial_start_time2 = [];
tint.trial_end_time2 = [];

if exist([data_path flnmroot '.eeg'],'file')
    tint.eeg.exists = 1;
    [tint.eeg_and_time tint.eeg.header] = read_eeg_file([data_path flnmroot '.eeg']);
    tint.eeg.sample_rate = key_value('sample_rate', tint.eeg.header, 'num');
    if isempty(tint.trial_start_time)
        tint.trial_start_time = tint.eeg_and_time(1,2) - (1 / tint.eeg.sample_rate);
        tint.trial_end_time = tint.eeg_and_time(end,2);
    end
end

if exist([data_path flnmroot '.eeg2'],'file')
    tint.eeg.exists2 = 1;
    [tint.eeg_and_time2 tint.eeg.header2] = read_eeg_file([data_path flnmroot '.eeg2']);
    tint.eeg.sample_rate2 = key_value('sample_rate', tint.eeg.header2, 'num');
    if isempty(tint.trial_start_time)
        tint.trial_start_time2 = tint.eeg_and_time2(1,2) - (1 / tint.eeg.sample_rate2);
        tint.trial_end_time2 = tint.eeg_and_time2(end,2);
    end
end

tint.trial_start_time = max([tint.trial_start_time tint.trial_start_time2]);
tint.trial_end_time = max([tint.trial_end_time tint.trial_end_time2]);

if tint.eeg.exists == 0 & tint.eeg.exists2 == 0
    uiwait(msgbox('NOTE: There is no eeg data for this file.','No eeg file...','modal'));
    tint.eeg_and_time = [];
    tint.eeg.header = [];
    tint.eeg.sample_rate = [];
    tint.eeg_and_time2 = [];
    tint.eeg.header2 = [];
    tint.eeg.sample_rate2 = [];
end

if isempty(tint.trial_start_time)
    tint.trial_start_time = 0;
    tint.trial_end_time = key_value('duration', tint.tetrode.header, 'num');
end