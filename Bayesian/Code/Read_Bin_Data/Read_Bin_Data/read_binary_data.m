function [header, RawBinaryData] = read_binary_data(filename,type)

% Read header text and binary data from tint data files.

% Function [header, RawBinaryData] = read_binary_data(filename,type)
% returns header as key-value pairs, and data as uint8 array ready
% which can be read with u8read (avoiding multiple freads -
% which SLOWs access for big files).

switch type
    case {'pos' 'tet'}
        f = fopen(filename,'r', 'ieee-be'); %Note endianess makes no differnece as file is read uint8 but good practise to specify
        if f == -1
            warning('No such file!');
            header = []; data = [];
            return;
        end
        RawBinaryData = fread(f,inf,'*uint8'); % Read the entire file into a uint8 array, for efficiency
        fclose(f);

    case 'eeg'
        f = fopen(filename,'r');
        if f == -1
            warning('No such file!');
            header = []; data = [];
            return;
        end
        RawBinaryData = fread(f,inf,'int8'); % Need signed integers for EEG
        fclose(f);
end

switch type
    case 'set'
        % This has no binary segment
        [key value] = textread(filename,'%s %[^\n]');
        header = [cat(1,key) cat(1,value)];
        RawBinaryData = [];
        return;
    case {'pos' 'tet' 'eeg'}
        % Find data_start marker
        [dummy dsmarker headerlines] = find_word(RawBinaryData,'data_start','return_lines');
        demarker = find_word(RawBinaryData,'data_end');

        if isnan(dsmarker)
            error('could not find data_start marker');
        end
        if isnan(demarker)
            error('could not find data_start marker');
        end

        % Read header
        [key value] = textread(filename,'%s %[^\n]',headerlines);
        header = [cat(1,key) cat(1,value)];

        RawBinaryData = RawBinaryData(dsmarker+1:demarker-3); % This is the data segment of the file - demarker is preceded by 13 10 (CR/LF)
    
    otherwise
        warning('unrecognized filetype');
        return;
end

% ----------------------------------------------------------------------------------------------------------------------