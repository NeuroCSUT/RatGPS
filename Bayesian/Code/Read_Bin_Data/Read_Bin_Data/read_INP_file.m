function [ time, type, chan ] = read_INP_file( pathflnm )
%READ_INP_FILE Read INP file produced by DACQ for digital timestamps
% Timestamps made in DACQ during recording are saved to an INP file. So for
% things like button presses etc. This function reads in the file specified
% and returns details (see below).

% INP file consists of a header which ends with the phrase 'data_start' and
% specifies various values such as date, bytes per sample, bytes per time
% stamp etc. Main data is then stored as a binary series where typically 7
% bytes specify each event (though this may vary). 7 bytes are 4 for the
% time, 1 for the type of event and 2 for the channel that it came in on.
% [note I am currently assuming these values are correct for all INP files
% so am hard coding but they are listed in the header and might vary so
% could read from header]

% TAKES
% pathflnm - fully qualified path and filename including extension

% RETURNS
% where n is the number of events
% time - [nx1] time in seconds of each event (see below)
% type - [nx1] event type using DACQ code (see below)
% chan - [nx1] channel event came in on [should only be specified for
%           digital events - 0 otherwise] Generally 0 shoudl be ignored
%           (see below)
%
% Time: first two times will be at 0s - these are respepsectivly a digital
% input and digital output and can probably be ignored
%
% Each event can be one of three types 'I', 'O' or 'K' being digital input,
% keypress and digital output respectivly.
%
% Channel can take different values depending on the type of event - for
% digital events (type 'I' or 'O') is a number between 1:16 and for a 
% keypress (type 'K') is a two number code (see DACQ file formats pdf for
% translation). The three buttons on the remote control (which are counted)
% as digital input are channels 14,15, and 16. The INP LOGS BOTH THE ONSET 
% AND OFFSET OF EVENTS so typically each digital input event with a
% positive channel is followed by one with a channel 0 - this is the
% off signal and can generally be ignored. This code currently does not
% read the channel for kepresses which are left logged as 0.

% ------------------------------------------------------------------------
%Open the file, read then parse the header
f = fopen(pathflnm,'r', 'ieee-be'); %Note time [4 bytes] is big endian [most sig first]
if f ==-1
    fprintf('Could not load INP file %s: invalid file', pathflnm);
    time = 'invalid INP file';
    type= 'invalid INP file';
    chan= 'invalid INP file';
    return
end

%File is valid so start reading
% Read all of file (the header) into a uint8 array - data_start should be
% at around 331 but also need data_end 
header = fread(f,inf,'*uint8'); 
header=char(header(:))';

%Parse header and find values we need: timebase, postion of data_start
startTB=strfind(header, 'timebase')+9; %Finds 't' so add 9 to get to value
endTB=strfind(header, 'hz')-2; %Words as long as 'hz' doesn't appear in filename or comments
startDS=strfind(header, 'data_start')+10; %Finds 'd' so add 10
endDS=strfind(header, 'data_end')-2; %Had to minus 2 not -1 as there seems to be extra spare byte

nBytes=endDS-startDS;
nEvents=nBytes/7; %Assume 7 bytes per event
timebase=str2double( header(startTB:endTB)); %In hz
fseek(f, startDS-1, 'bof'); %Move pointer to start of binary section
clear start* end*

%Now read bulk of file
raw=fread(f, [7,nEvents], '*int8')'; %Read as int8 into a [nEvents x 7] mat

%Now parse into the values we want#
%First get time from bytes 1:4
time=flipud(raw(:,1:4)'); %First four columns of the raw mat - flipud because pc is littleendian
time=typecast(time(:), 'int32'); 
time=double(time)/timebase;

%Second get type of event from byte 5
type=char(raw(:,5));

%Third get channel - see notes above as to what value this takes
%Channel is coded in odd way even for digital input - I'm not decoding key
%presses 'k' but for digital inputs the 2 bytes (16bits) specify state of
%each of 16channels. I'm assuming only one is going to be on so return the
%number of that channel.
chan=raw(:,6:7); %Last 2 columns of the raw mat - byte 6 ch 16:9, byte 7 8:1
chan=typecast(chan(:), 'uint8');
chan=reshape(chan, nEvents,2); %Get back into two columns (i.e. byte 6 &7)
%Next have to get channel that is active. Channels are coded in odd way-
%for each bit in a byte indicates whether a given channel 8:1 for example
%was active. If I assume only one channel was active then when this number
%is experssed as uint8 the result should be a power of 2 and taking the
%log2 will indicate which power and hence which bit.
%NL. Assume only single channel is active so value expressed as 
chan=log2(double(chan)); %But this runs from 0 to 7 not 1 to 8 so add 1 later
chan(chan==inf | chan==-inf)=nan; %Remove infs from log of 0
chan=chan+repmat([9,1], nEvents,1); %byte 6 is chan 16 to 9 so add 8 +1 from earlier
chan=nansum(chan,2); %Works if single channle active

%Since chan calculation doesn't work for a keypress set these to nan for
%the moment
chan(type=='K')=nan;

end

