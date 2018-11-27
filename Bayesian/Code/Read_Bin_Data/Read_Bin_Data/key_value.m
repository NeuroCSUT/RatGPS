function [values, keys] = key_value(varargin)
% Cast or echo values from key value cell string array.
%
% The headers in the Axona file format contain lists of key-value pairs.
% The tint toolbox stores these as cell arrays containing 2 columns of strings,
% the first column being the keys (e.g., "experimenter") the second being the values (e.g., "Kate Jeffery").
% This function is a convenient way of casting the values into a particular datatype (e.g., number, string).

% key_value('mode_ch_1',keyvalue,'echo')
% display all values for keys matching 'mode_ch_1*'.
%
% key_value('mode_ch_1',keyvalue,'echo','exact')
% display all values for the key (or keys) which exactly matches 'mode_ch_1*'.
%
% values=key_value('mode_ch_1',keyvalue)
% all values for keys matching 'mode_ch_1*', returned as a cell array of strings.
%
% [values keys]=key_value('mode_ch_1',keyvalue)
% all values for keys matching 'mode_ch_1*', returned as a cell array of strings, together with the matching keys (returned as a cell array of strings).
%
% [values keys]=key_value('mode_ch_1',keyvalue,'string')
% all n values for keys matching 'mode_ch_1*', returned as a space padded character array with each value on one of n rows.
%
% [values keys]=key_value('mode_ch_1',keyvalue,'num')
% all values for keys matching 'mode_ch_1*', returned as a column vector (converted using str2num).
%
% [values keys]=key_value('mode_ch_1',keyvalue,'uint8')
% all values for keys matching 'mode_ch_1*', returned as a column vector of uint8 (converted using str2num and cast to the relevant type).
% possible types: uint8, uint16, uint32, int8, int16, int32, single, double.
%
% [values keys]=key_value('mode_ch_1',keyvalue,'default','exact')
% the value(s) for the key (or keys) matching 'mode_ch_1' exactly, returned as a cell array of strings.
%
% This original version of this function can be found at this end of this
% file inside a comment block.  The current version is faster and simpler,
% but has not been extensively tested.
%
if length(varargin)>=2
    key=varargin{1};
    keyvalue=varargin{2};
    cast_to='default';
end
if length(varargin)>=3
    cast_to=varargin{3};
end

match_exact = false;
if length(varargin)>=4
    matchmode=varargin{4};
    if strcmp(matchmode,'exact') 
        match_exact = true;
    elseif strcmp(matchmode,'all') 
        match_exact = false;
    else
        warning('Unknown matchmode: ''%s''.  Using matchmode=''all'' instead.',matchmode);
        match_exact = false;
    end
end


%-----Parameters parsed, lets get going.-----------------------------

key_names = char(keyvalue{:,1}); %This line is surprisingly slow...why not do it once when we load the data and then pass the char array to this function?
target = char(key);
key_names_width = size(key_names,2);
target_width = size(target,2);

if target_width > key_names_width
    values={};
    keys={};
    return;
end

if match_exact &&  target_width < key_names_width
    target(end+1) = ' '; %char pads with spaces.  We assume that keys do not themselves contain spaces.
    key_names = key_names(:,1:target_width+1);
else  
    key_names = key_names(:,1:target_width);
end

%--This is the important part..find the key name in the list-----
d = bsxfun(@eq,key_names,target);
d = all(d,2);
i = find(d);

if isempty(i)
    %MA: I switched this warning off; always appears even in normal operation
    %warning('specified key not found');
    values={};
    keys={};
    return;
else
    if match_exact
        i = i(1); %if there are duplicates we only return the first (apparently).
    end

    keys=keyvalue(i,1);
    switch cast_to
        case 'num'
            % Ignore anything after the first space
            if length(i)==1
                values = str2double(regexprep(keyvalue{i,2},'\s.*$',''));
            else
                values = cellfun(@(v) str2double(regexprep(v,'\s.*$','')),keyvalue(i,2));
            end
        case 'string'
            if length(i)>1
                warning('more than one answer returned: strings may be padded with spaces');
            end
            values=char(keyvalue(i,2));
        case {'uint8','uint16','uint32','int8','int16','int32','single','double'}
            if length(i)==1
                values = str2double(regexprep(keyvalue{i,2},'\s.*$',''));
            else
                values = cellfun(@(v) str2double(regexprep(v,'\s.*$','')),keyvalue(i,2));
            end
            values = cast(values,cast_to);
        case 'echo'
            disp(char(keyvalue(i,2)));
            values=keyvalue(i,2);
        case 'default'
            values=keyvalue(i,2);
        otherwise
            error('unrecognized cast');
    end
end

% ------------------ The original version of the function follows ---------------------------

%{

function [values, keys] = key_value(varargin)

% Cast or echo values from key value cell string array.
%
% The headers in the Axona file format contain lists of key-value pairs.
% The tint toolbox stores these as cell arrays containing 2 columns of strings,
% the first column being the keys (e.g., "experimenter") the second being the values (e.g., "Kate Jeffery").
% This function is a convenient way of casting the values into a particular datatype (e.g., number, string).

% key_value('mode_ch_1',keyvalue,'echo')
% display all values for keys matching 'mode_ch_1*'.
%
% key_value('mode_ch_1',keyvalue,'echo','exact')
% display all values for the key (or keys) which exactly matches 'mode_ch_1*'.
%
% values=key_value('mode_ch_1',keyvalue)
% all values for keys matching 'mode_ch_1*', returned as a cell array of strings.
%
% [values keys]=key_value('mode_ch_1',keyvalue)
% all values for keys matching 'mode_ch_1*', returned as a cell array of strings, together with the matching keys (returned as a cell array of strings).
%
% [values keys]=key_value('mode_ch_1',keyvalue,'string')
% all n values for keys matching 'mode_ch_1*', returned as a space padded character array with each value on one of n rows.
%
% [values keys]=key_value('mode_ch_1',keyvalue,'num')
% all values for keys matching 'mode_ch_1*', returned as a column vector (converted using str2num).
%
% [values keys]=key_value('mode_ch_1',keyvalue,'uint8')
% all values for keys matching 'mode_ch_1*', returned as a column vector of uint8 (converted using str2num and cast to the relevant type).
% possible types: uint8, uint16, uint32, int8, int16, int32, single, double.
%
% [values keys]=key_value('mode_ch_1',keyvalue,'default','exact')
% the value(s) for the key (or keys) matching 'mode_ch_1' exactly, returned as a cell array of strings.

matchmode='all';
if length(varargin)>=2
    key=varargin{1};
    keyvalue=varargin{2};
    cast='default';
end
if length(varargin)>=3
    cast=varargin{3};
end
if length(varargin)>=4
    matchmode=varargin{4};
end

if strcmp(matchmode,'exact')
    i=strmatch(key,keyvalue(:,1),'exact');
    if size(i,1)>1 % Remove duplicated key values
        i=i(1,:);
    end
elseif strcmp(matchmode,'all')
    i=strmatch(key,keyvalue(:,1));
end

if isempty(i)
    %MA: I switched this warning off; always appears even in normal operation
    %warning('specified key not found');
    values={};
    keys={};
    return;
else
    keys=keyvalue(i,1);
    switch cast
        case 'num'
            for t=1:length(i)
                values(t)=str2num(strtok(keyvalue{i(t),2},' ')); % Ignore anything after the first space
            end
        case 'string'
            if length(i)>1
                warning('more than one answer returned: strings may be padded with spaces');
            end
            values=strvcat(keyvalue{i,2});
        case {'uint8','uint16','uint32','int8','int16','int32','single','double'}
            values=str2num(strvcat(keyvalue{i,2}));
            eval(['values=' cast '(values)']);
        case 'echo'
            disp(strvcat(keyvalue{i,2}));
            values=keyvalue(i,2);
        case 'default'
            values=keyvalue(i,2);
        otherwise
            error('unrecognized cast');
    end
end

% ----------------------------------------------------------------------------------------------------------------------

%}