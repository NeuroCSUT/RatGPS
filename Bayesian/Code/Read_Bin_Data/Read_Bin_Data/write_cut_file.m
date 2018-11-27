function [] = write_cut_file( spikeAssignment, filePath, fileStem, tetrodeNo)
%WRITE_CUT_FILE Writes spike assignments back to an Axona cut file
% NB. Based on a version writen by Mike Anderson but adapted for general
% use by CB.

% Takes spikes assignments - one integer per spike provided as a vector - 
% and writes to disk as a .cut file that Tint can read in. If that file
% already exists it is over written, if it doesn't it is created. Note cut
% files have a specific format to be compatable with tint, which is:
% <fileStem>_<tetrodeNo>.cut where fileStem has to match the filename of
% the main data files and tetrodeNo is the tetrode number of the current
% files. e.g. '1500728a_2.cut' would match 1500728a.set and before tetrode
% 2.
%
% NB. Cluster 0 is reserved for junk - this is different to KlustaKwik
% where 1 is used. And the max number of clusters is 20 - though this might
% have changed in later versions.
%
% ARGUMENTS
% spikeAssignment   Vector of integer cluster assignments, one for each
%                   spike. Note cluster 0 is reserved for junk and clusters
%                   can only go up to 20. [nSpike x 1]

% fileStem          Filename of the .set file without the '.set'. As a
%                   char. 
%
% tetrodeNo         Tetrode number this corresponds to [int]

% RETURNS
% nothing but does write to disk

% EXAMPLE
% write_cut_file( [4,1,2,7,4,2,12,4,3,], 'c:/myfile/', '2140612a', 1)

% --- VARIABLES ----
maxCluster      =30;


% --- MAIN ---
% Check if cluster no is within allowed range
if max(spikeAssignment)>maxCluster
    warning('Cluster assignments exceed the max allowed - might not be compatiable with tint.');
end

nSpikes         =length(spikeAssignment);
spikeAssignment =spikeAssignment(:);


%Create filename of the file to write
fullFileName    =[fileStem, '_', num2str(tetrodeNo), '.cut'];

% Open file to write to - in same directory as original spike file
% NB. This will overwrite any existing cut file for this spike set without warning
fid=fopen([filePath, fullFileName], 'w');

% ---
% Now start writing to the file
% Write header
fprintf(fid,'n_clusters: %1.0d%c%c',max(spikeAssignment) + 1,13,10);
fprintf(fid,'n_channels: 4%c%c',13,10);
fprintf(fid,'n_params: 2%c%c',13,10);
fprintf(fid,'times_used_in_Vt:   15   12   12   16%c%c',13,10);

for n=0:max(spikeAssignment)
fprintf(fid,' cluster: %2.1d centre:    0    0    0    0    0    0    0    0%c%c',n,13,10);
fprintf(fid,'                min:    0    0    0    0    0    0    0    0%c%c',13,10);
fprintf(fid,'                max:    256  256  256  256  256  256  256  256%c%c',13,10);
end
fprintf(fid,'%c%c',13,10);

% Write main data
fprintf(fid,'Exact_cut_for: 1500728a spikes: %6.0d%c%c',nSpikes,13,10);
for n           =0:ceil(nSpikes/25)-2
    range       =(1:25)+25*n;
fprintf(fid,'  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d  %1.1d%c%c',spikeAssignment(range),13,10);
end

% Sort out last row
startLastRow    =25*(n+1)+1;
for k           =startLastRow:nSpikes
    fprintf(fid, '  %1.1d',spikeAssignment(k));
end

%Close file
fclose(fid);