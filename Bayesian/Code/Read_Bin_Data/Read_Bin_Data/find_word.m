function [offstart, offend, lines] = find_word(varargin)

bin = varargin{1};
word = varargin{2};
clear varargin

bin = reshape(bin,1,size(bin,1)*size(bin,2));
offstart = [];
if length(bin)<1000
    switch word
        case 'data_start'
            offstart = findstr(bin, word);
            if ~isempty(offstart)
                offend = offstart+length(word)-1;
            end
        case 'data_end'
            offstart = findstr(bin,word);
            if ~isempty(offstart)
                offend = offstart+length(word)-1;
            end
    end
else
    for i = 1:floor(length(bin)/1000)
        switch word
            case 'data_start'
                offstart = findstr(bin((i*1000-999):(i*1000)), word);
                if ~isempty(offstart)
                    offstart = i*1000-1000+offstart;
                    offend = offstart+length(word)-1;
                    break
                end
            case 'data_end'
                offstart = findstr(bin((end-i*1000+1):(end-i*1000+1000)),word);
                if ~isempty(offstart)
                    offstart = length(bin)-i*1000+offstart;
                    offend = offstart+length(word)-1;
                    break
                end
        end
    end
end

if nargin == 3 %Only return lines if necessary as this is slow!
    good = bin(1:offstart-2); % This seems much faster than the old line: bin(offstart-1:end) = [];
    lines = length(find(good == 13));
end