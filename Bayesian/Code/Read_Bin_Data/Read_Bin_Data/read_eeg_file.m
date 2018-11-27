function [eeg_and_time, header] = read_eeg_file(flnm)

% Read eeg data file prefixed 'flnm'.
% [eeg, header]=read_eeg_file(flnm)
% returns:
% eeg : eeg vector
% header : header information as key-value pairs (cell array of strings)

% EEG data file format:
%
% trial_date Tuesday, 2 Jul 1996
% trial_time 15:53:30
% experimenter Kate Jeffery
% comments rotated rat alone 180 deg. CW
% duration 120 s
% sw_version 0.9
% num_chans 1
% EEG_samples_per_position 5
% num_EEG_samples 1170
% sample_rate 234.375 hz
% bytes_per_sample 1
% data_start
%
% EEG data, starting immediately after 'data_start':
%
% 1 byte of sampled EEG signal
% ...
% 1 byte of sampled EEG signal
% ^M^Jdata_end^M^J
%
% Note that 234.375 = 46.875 (the position sample rate)5.
% The EEG signal is sampled every 4.2666 ms; every fifth EEG
% sample, the four light positions are stored (i.e., every
% 21.333 ms).  These numbers are for axsamp-compatibility only,
% and could be changed to rounder numbers eventually.
try
    [header eeg] = read_binary_data(flnm,'eeg');
catch
    %No eeg file found - sometimes happens, return empty variables instead
    [eeg_and_time, header] =deal([]);
    return
end

eeg = double(eeg);
sample_rate = key_value('sample_rate',header,'num');
num_EEG_samples = key_value('num_EEG_samples',header,'num');
times = (1:num_EEG_samples)/sample_rate;
eeg_and_time = [eeg times'];

if num_EEG_samples~=size(eeg,1)
    error('eeg data is wrong size');
end

% ----------------------------------------------------------------------------------------------------------------------