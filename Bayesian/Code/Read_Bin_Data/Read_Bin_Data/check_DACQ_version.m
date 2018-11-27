function [ systemV, maxEEGch ] = check_DACQ_version( header )
%CHECK_DACQ_VERSION Takes system header (tint.header) and returns info about DACQ version
%and max EEG ch.
%
%NB on older DACQ system two eeg files could be saved *.eeg and *.eg2 on
%the new USB system upto 16 files can be saved *.eeg, *.eeg1 etc.
%In addition upto four 48kHz eeg files can be recorded - this code does not
%read them but their extensions are *.egf, *.egf2 etc.
%
% Note used to use value of 'sw_version' header which was either 1.x, 2.x, 3.x, 4.x but
% jim changed this so latter USB versions became 1.x whereas they had been 4.x. See old
% code below.


% TAKES
% header - tint.header [x by 2 cell array]
%
% RETURNS
% systemV - 'usb', 'old', or 'vold'
% maxEEGch - max allowed number of eeg channels
%


softwareV = key_value('ADC_fullscale_mv', header);
softwareV = str2double(softwareV{1});

switch softwareV
    case 1500,
        systemV='usb';
        maxEEGch=16;
        
    case 3680,
        systemV='old';
        maxEEGch=2;
        
    case 3000,
        systemV='vold';
        maxEEGch=0; %More were possible but have set 0 so they are not read
        
    otherwise,
        error('System type is not matched in header');
end
end



