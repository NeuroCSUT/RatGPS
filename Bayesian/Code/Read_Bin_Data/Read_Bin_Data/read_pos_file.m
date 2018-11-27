function [led_pos, led_pix, header] = read_pos_file(flnm)

% Read in positions from a .pos file

% MA: Replaced u8read with typecast a la Caswell's work with read_tetrode_file

[header data] = read_binary_data(flnm,'pos');
num_pos_samples = key_value('num_pos_samples',header,'num');
num_data_pairs = key_value('num_colours',header,'num');

% Determine if computer is big or little endian (most windows machines are latter)
test = typecast(uint8([0,0,0,1]), 'int32'); % If bigendian will equal 1 if little will equal 256^3
switch test
    case 1
        bigEnd = 1;
    case 256^3
        bigEnd = 0;
    otherwise
        error('Unrecognised byte order');
end
clear test;

% Most data is written for 2 'colours', even if only one is used (in this case always the first one):
% i.e: pos_format: t,x1,y1,x2,y2,numpix1,numpix2,dum,dum
% Some data (old systems - rare) is written for 4 colours (in this case the fourth one is always used)
% i.e.: pos_format: t,x1,y1,x2,y2,x3,y3,x4,y4

% MA 18/11/08: 4 colour system I believe is virtually obsolete. All mtint fcns therefore now expect either
% 1 or 2 LEDs. 4 LED data will still load (I think), but this function reads from a max of 2 LEDs (and presumes them
% to be 180 deg apart). So array becomes [t,x4,y4,x2,y2,dum,dum]. LED 4 comes first because it's the one 
% used in 1-spot mode.

% MA 18/11/08: this version of read_pos_file doesn't rely on the dacq header's record of how many
% LEDs were used. I believe this is user-defined and hence open to conflict with the actual data. 
% Better to read all the possible tracked LEDs then count the number of populated array columns to 
% work out how many LEDs were in fact used.

% MA Use typecast not u8read, we can now get rid of u8read forever

% % Read timestamp, 4 bytes  - DON'T NEED THIS BUT KEEP IT JUST IN CASE
% data1 = zeros(1,4*num_pos_samples,'uint8');
% for byte = 1:4
%     data1(byte:4:end) = data(byte:20:end);
% end

% Ignore timestamp (not required), read rest, 2 bytes * num_data_pairs * 2
data2 = zeros(1,num_data_pairs*2*2*num_pos_samples,'uint8');

for byte = 1:num_data_pairs*2*2
    data2(byte:num_data_pairs*2*2:end) = data(byte+4:(num_data_pairs*2*2)+4:end);
end

% Change to correct datatype
data2 = typecast(data2, 'uint16');

% If computer is littleendian swap byte order to be bigendian
if ~bigEnd
    data2 = swapbytes(data2);
end

led_pos = zeros(num_pos_samples, 4, 2);
led_pix = zeros(num_pos_samples, 2);

pos_format = key_value('pos_format', header, 'string');

switch pos_format
                
    case 't,x1,y1,x2,y2,numpix1,numpix2' % The current format
        
        % MA This format appears to repeat numpix1 & numpix2 so that it is actually
        % 't,x1,y1,x2,y2,numpix1,numpix2,numpix1,numpix2'
        
        led_pos(1:end,1,1) = data2(1:8:end);
        led_pos(1:end,1,2) = data2(2:8:end);
        
        led_pos(1:end,2,1) = data2(3:8:end);
        led_pos(1:end,2,2) = data2(4:8:end);
        
        led_pix(1:end, 1) = data2(5:8:end);
        led_pix(1:end, 2) = data2(6:8:end);
        
     case 't,x1,y1,x2,y2,x3,y3,x4,y4' % Old format, does anyone still use this?
        
         led_pos(1:end,1,1) = data2(1:8:end);
         led_pos(1:end,1,2) = data2(2:8:end);
         
         led_pos(1:end,2,1) = data2(3:8:end);
         led_pos(1:end,2,2) = data2(4:8:end);
         
         led_pos(1:end,3,1) = data2(5:8:end);
         led_pos(1:end,3,2) = data2(6:8:end);
         
         led_pos(1:end,4,1) = data2(7:8:end);
         led_pos(1:end,4,2) = data2(8:8:end);

%% AJ: I have no idea why you need these lines but they cause errors with
%% this pos_format. They have incorrect indexing. I think we can just
%% comment them out.
%         x2_y2 = led_pos(:, 2, :);
%         x4_y4 = led_pos(:, 4, :);
%         led_pos(:, [2 3], :) = x4_y4;
%         led_pos(:, [4 5], :) = x2_y2;
%         led_pos(:, [6:9], :) = [];
%         
%         warning(sprintf('Old pos data format: %s. I will use only LED 4 for 1-spot mode (and the LED 2 for 2-spot mode if it exists). In 2-spot mode, I assume LEDs 4 and 2 were 180 deg apart.\n', pos_format));
end

% Remove empty (0) / bad (1023) led_pos columns (both x and y cols need to be empty)
% unused_x = [find(sum(led_pos(:,:,1)) == 0) find(mean(led_pos(:,:,1)) == 1023)];
% unused_y = [find(sum(led_pos(:,:,2)) == 0) find(mean(led_pos(:,:,2)) == 1023)];

%% AJ: I've replaced the above 2 lines with the following two because they
%% were causing errors on some trials, by accepting some columns which
%% clearly had no data and should not be included according to the
%% setfile_header. The following lines are unlikely to cause false
%% positive exclusion of columns, though it is theoretically possible.
%% Sometimes DACQ records an extra second of data beyond the trial length.
%% The values for this second are 0 and not 1023 for unrecorded colours -
%% this throws off the above lines. Similar changes have been made to the
%% analogous filter for led_pix below.
unused_x = find(sum(led_pos(:,:,1) == 0 | led_pos(:,:,1) == 1023) == size(led_pos,1));
unused_y = find(sum(led_pos(:,:,2) == 0 | led_pos(:,:,2) == 1023) == size(led_pos,1));
unused_xy = intersect(unused_x, unused_y);
led_pos(:,unused_xy,:) = [];
led_pos(led_pos == 1023) = NaN; % Flag any stray bad points

% Remove empty/bad led_pix columns
% unused_pix = [find(sum(led_pix) == 0) find(mean(led_pix) == 1023)];
unused_pix = sum(led_pix == 0 | led_pix == 1023) == size(led_pix,1);
led_pix(:,unused_pix) = [];
led_pix(led_pix == 1023) = NaN; % Flag any stray bad points