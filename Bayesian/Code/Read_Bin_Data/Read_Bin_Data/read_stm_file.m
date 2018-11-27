function [stimTime, header] = read_stm_file(datafile)
% Read STM file - currently just for reading time stamps from the internal
% stimulator in DACQ.
% DACQ saves time stamps for stimulator events transmitted via the DIO
% port. These are logged in the .stm file and can be read in by this
% function. 
%
% Note this function is based on an original from Jim Donnet but adapted as
% as it was not working correctly.
%
% Usage: [stimts, header] = getstm(datafile); %specify without the trailing '.stm'
%
%
% This script makes hard-coded assumptions about the .stm file format:
% the timebase is on header line 8,
% and the number of samples on line 11, 
% followed by data_start on line 12.

%Open the .stm file - stm always start with an 11 line text header, data
%starts on line 12. This code assumes that it will be uint32 (i.e. 4 bytes
%per value). Note also that .stm is writen as big endian - this is not the
%default on modern PCs or Macs.
fid         =fopen([datafile '.stm'],'r','ieee-be'); %specifying bigendian
if (fid == -1)
   error('Could not open stm file %s',filename);
end


%Next read in all 11 lines of the header (i.e. not including the finale
%'data start' line but all the useful ones. Put these in a cell array. Note
%reading in moves the file pointer to the start of line 12.
header      =cell(11,1); %Preallocate
for i       =1:11
   header{i}    =fgetl(fid);
end

%From our cell array determine what the time base was - usuall 1,000Hz
timeBase    =sscanf(header{8},'%*s %f');


%Note on line 11 of the header the number of stim samples is specified but
%we don't use this as it's quite unreliable and sometimes isn't writen by 
%DACQ. This appears to be especially the case if a more complex stim 
%protocol is used (i.e. with different periods of bursts and trains etc)
% nosamples = sscanf(header{11},'%*s %u'); %Commented as not used


%Finally move the file pointer forwards a further 10bytes which moves past
%the text phrase 'data start' to the point imediatly after (no space) where
%the binary data actually starts and read to the end of the file in 4 byte
%chunks then close the file
fseek(fid,10,0);
stimTime    =fread(fid,'uint32'); 
fclose(fid);

%But note the .stm file ends with the text string 'data_end' which takes
%exactly 12 bytes. Hence the last 3 vaules read in by fread will actually
%be numeric translation of ASCII text - delete these. If we could reliably
%use the header value 'num_stm_samples' then we could just read for this
%number x 4 bytes. Instead read to the end then delete the last 3 values.
stimTime    =stimTime(1:end-3);

%Finally convert to seconds (divide by the timebase)
stimTime    =stimTime/timeBase;
