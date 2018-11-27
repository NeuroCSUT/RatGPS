function [varargout] = read_tetrode_file(flnm)

% CB function based on read_tetrode_file
% CB ammended function. Key change is that it will return just header and timebase without
% reading spikes from disk (10x speed up and much less memory intensive). Changes also
% mean that u8read is not required and even for waveform reading is faster and more memory
% efficient.
% Key difference
% 1. Reads only seciton of file necessary
% 2. U8read not used, matlab build in typecast instead
% 3a HAVE CHANNGED TO RETURN INT8 WAVEFORM FOR SPEED AND SPACE
% 3. NOTE. For back compatability convert wavform and timestamp to double when they could
% be int8 and int32 respectivly. This massivly increases memory use *x8) in first case and
% slows code down.
% To just read spike times is ~10 faster than original code 0.1s vs 1.3s for wavform take
% 0.9s vs 1.9s.
%
% OLD NOTES
% Read Axona tetrode files
%
%
% Two forms:
% [header, timestamp, waveforms] = read_tetrode_file(flnm) does read waveforms
% [header, timestamp] = read_tetrode_file(flnm) does not read waveforms
%
% TAKES
% flnm : fully qualified filename including path plus extension e.g. '.1', '.2' 
%
% RETURNS: varargout of either 2 [header, timestamps] or 3 [header, timestamps, spike_waveforms]
% vars
% header : header information as key-value pairs (cell array of strings)
% timestamp : timings for each spike. [num_spikes x num_chans]
% spike : spike waveforms for each channel [num_spikes x samples_per_spike x num_chans ]



%--------------------------------------------------------------------------
%Deterimine if spike waveforms are required if only two arguments out then
%they are not, if three they are
if nargout==3,    waveforms=1;
else    waveforms=0;
end

%Also determine if computer is bigendian or little endian (most windows machines are the
%latter). Note this does not affect the byte order of the tetrode file which is always
%writen as a bigendian
test=typecast(uint8([0,0,0,1]), 'int32'); %If bigendian will equal 1 if little will equal 256^3
switch test
    case 1
        bigEnd=1;
    case 256^3
        bigEnd=0;
    otherwise
        error('Unrecognised byte order')
end
clear test


% ------------------------------------------------------------------------
%In either case open the file, read then parse the header
f = fopen(flnm,'r', 'ieee-be'); %Note endianess makes no differnece as file is read uint8 but good practise to specify
if f ==-1
    fprintf('\nCould not load tetrode %s: invalid data file', flnm(end));
    varargout{1} = 'invalid tetrode file';
    varargout{2} = 'invalid tetrode file';
    varargout{3} = 'invalid tetrode file';
    return
end

header = fread(f,400,'*uint8'); % Read start of file (the header) into a uint8 array

% Find data_start marker
dsmarker = strfind(char(header(:))','data_start')+10; %Finds the position of the 'd' so add 10 to be the single space after
%         demarker = find_word(RawBinaryData,'data_end'); NOT NEEDED NOW

if isempty(dsmarker)
    error('could not find data_start marker');
end


% Parse header
[key value] = textread(flnm,'%s %[^\n]',14); %Read 14 text based header lines - hard coded number of lines
header = [cat(1,key) cat(1,value)];

%More error checkinig
check(1) = isempty(header{strmatch('num_chans', header(:,1)),2});
check(2) = isempty(header{strmatch('timebase', header(:,1)),2});
check(3) = isempty(header{strmatch('samples_per_spike', header(:,1)),2});
check(4) = isempty(header{strmatch('num_spikes', header(:,1)),2});

if any(check)
    fprintf('Could not load tetrode %s data: header invalid', flnm(end));
    varargout{1} = 'invalid tetrode header';
    varargout{2} = 'invalid tetrode header';
    varargout{3} = 'invalid tetrode header';
    return
end
clear check key value

%Not using some of these variables now - have hard coded fact that there
%are four channels to each tetrode and there are 50 samples at 8bit per
%spike
% num_chans = key_value('num_chans',header,'num');
timebase = key_value('timebase',header,'num');
% samples_per_spike = key_value('samples_per_spike',header,'num');
num_spikes = key_value('num_spikes',header,'num');

% ------------------------------------------------------------------------
%Now read bulk of data either just timestamps or timestamps and waveforms.
%Note structure of data is such that for every spikes on each channel a 4
%byte timestamp is logged followed by the 50 waveform points each being 1
%byte. So 54bytes per channel, 216 per spikes. Key point is that timestamps
%are always the same for each channel, so fully redundant (i.e. just read
%first ch). The timestamp is in bigendian ordering so each of the 4 bytes
%correspond to 256^3, 256^2, 256^1, 256^0 in that order. Waveform points
%are int8 so single byte and aren't affect by byte ordering.

%NL. Set current read point in file - Moves forwards from beging of file by amount
%specified by 2nd var (so a value of 1 would move to 2nd byte in file)
fseek(f, dsmarker-1, 'bof'); %
clear dsmarker

switch waveforms
    case 1 %Read timestamp and waveforms
        %warning('read_tetrode_file now returns waveforms as int8 not double mat');
        %Note read file as int8 (waveforms are int8 anyway)
        raw=fread(f, 216*num_spikes, '*int8'); %Read as int8 all data - waveforms at int8
        raw=reshape(raw, 216, num_spikes); %Now a int8 mat [nSpikes x 216]
        
        %Pull out for each spikes the 4 byte timestamp and convert to a
        %single int32 value.
        %NL. typecast will use native byte ordering of computer
        timestamp=typecast(  reshape(raw(1:4,:), [num_spikes*4,1]), 'int32'); %typecast only works on vector
        %NL. if computer is littleendian swap byte order to be bigendian
        if ~bigEnd,  timestamp=swapbytes(timestamp);   end
        timestamp=double(timestamp); %Make double as we need non int values & back compatability
        
        %         timestamp=sum(int32(raw(:,1:4)) .* repmat(int32([256^3, 256^2, 256^1, 1]),
        %         [num_spikes,1]) ,2);  %Old way of doing it - hardcoded bigendian only works with
        %         uint8
        
        
        %For back compatability timestamp neeeds to be replicated for each ch
        timestamp=repmat(timestamp(:),[1,4]);
        
        %Now convert spikes data to a nSpikes x 50 x 4 mat
        %NL. Just select spike samples and transpose to [nSpike x 200] int8
        raw=raw([5:54, 59:108, 113:162, 167:216],:)';
        raw=reshape(raw,[num_spikes, 50,4]); %still int8 [nSpike x 50 x 4]
        
        varargout{1} = header;
        varargout{2} = timestamp./timebase; % Convert timestamps to seconds using timebase.
        varargout{3} = raw;
        
    case 0 %Just time stamp
        %NL. Can read the 4 byte timestamp directly as an int32 then skip
        %next 212 bytes which is waveform and timestamp on other channels.
        % NB is affected by bigendian specified in fopen
        timestamp=fread(f, num_spikes, '*int32',212);
        timestamp=double(timestamp); %Make double as we need non int values & back compatability
        %For back compatability timestamp neeeds to be replicated for each ch
        timestamp=repmat(timestamp,[1,4]);
        
        varargout{1} = header;
        varargout{2} = timestamp./timebase; % Convert timestamps to seconds using timebase.
end


fclose(f);



% ----------------------------------------------------------------------------------------------------------------------