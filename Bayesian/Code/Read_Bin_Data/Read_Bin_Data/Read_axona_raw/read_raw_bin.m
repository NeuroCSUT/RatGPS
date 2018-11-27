function [wavData,posData] = read_raw_bin(filename,channels)

% reads the waveform for selected channels from Dacq raw recording BIN
% files recorded at 48kHz sample rate.
% see DacqUSBFileFormats document form Axona downloads page for file structure
% eg. [wavData,posData] = read_raw_bin_wav('C:\BIN processing\110714fra1.bin',1:16)
% written by M Rutledge 2/9/2011

f=fopen(filename,'r');
fseek(f,216*2,'bof'); %skip first 432 byte packet (it is odd.. maybe header information?)

% In the BIN file, each 48kbits/second sample is spread accross two 8byte packets of
% 2's complement binary format. This captures them as single integers
RawBinaryData = fread(f,inf,'2*int16=>int16'); 
RBDLen=length(RawBinaryData); 

% number of packets: BIN file 432 byte 2's complement packets are 216 elements in RawBinaryData.%% -1 from removing 1st packet. 
numPacks=(RBDLen/216);  

% recording duration in samples: 3 samples (each 1/48000 seconds) per packet. 
recDurSamps=3*numPacks;

%if a large chMat not saved
[chMat,recDurSamps,RBDLen] = binfile_refmatrix(channels,RBDLen,recDurSamps);
% else
% load chMat

j=1;wavData(length(channels),recDurSamps)=0;
for i=channels
    wavData(j,1:recDurSamps) = RawBinaryData(chMat(i,1:recDurSamps));  j=j+1;
end

 
%  [userview, systemview] = memory;  

% for positions        %I haven't tested this as my packet ID is ADU1 
f=fopen(filename,'r');
a = textscan(f, '%[ADU2]',4);
if strcmp(a{1,1},'ADU2')    
    for i=7:16  %pos data locations within each 432 byte (216 RBD elements) packet according to DacqUSBFileFormats doc.
        posMat(i-6:10:10*numPacks)=(i:216:RBDLen);
    end
    posData=RawBinaryData(posMat);
else
    posData=[];
end