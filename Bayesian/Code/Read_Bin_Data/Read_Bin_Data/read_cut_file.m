function [exact, n_clusters, vt1] = read_cut_file(flnm)

% vt2 & thresholds are specific to mtint, however this function will still work on old cut files

fid = fopen(flnm);

if fid == -1
    return
    
end

exact = [];
n_clusters = [];
vt1 = [];


while feof(fid) < 1
    lne = fgetl(fid);
    
    if strfind(lne,'n_clusters:')
        n_clusters = strread(lne,'n_clusters: %d');
        
    elseif strfind(lne,'n_channels:')
        n_channels = strread(lne,'n_channels: %d');
        
    elseif strfind(lne,'n_params:')
        n_params = strread(lne,'n_params: %d');
        
    elseif strfind(lne,'times_used_in_Vt:')
        [vta vtb vtc vtd] = strread(lne,'times_used_in_Vt: %d %d %d %d');
        vt1 = [vta vtb vtc vtd];
        
    elseif strfind(lne,'times_used_in_Vt2:')
        [vta vtb vtc vtd] = strread(lne,'times_used_in_Vt2: %d %d %d %d');
        vt2 = [vta vtb vtc vtd];
        
    elseif strfind(lne,'thresholds:')
        [ta tb tc td] = strread(lne,'thresholds: %d %d %d %d');
        thresholds = [ta tb tc td];
        
    elseif strfind(lne,'Exact_cut_for:')
        [setfilename n_spikes] = strread(lne,'Exact_cut_for: %s spikes: %d');
        exact = fscanf(fid,'%d',n_spikes);
        
    else % If none of the others is probably a clu file which just has the 
         % exact cut and nothing else. So read the whole file.
        exact   =fscanf(fid, '%d', inf); 
    end
    
end

fclose(fid);