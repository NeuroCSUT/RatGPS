function [ binned_array ] = cb_bin_data(var2bin, var2binby, binsize, posdata, pos2use )
%CB_BIN_DATA Now replaced by bin_data - this function  passes through
%the variables specified to bin_data for backwards compatability but to
%avoid seeing the error message suggest replacing all calls to cb_bin_data
%with bin_data

fprintf('cb_bin_data is now replaced by bin_data -  use that instead');
[binned_array] = bin_data(var2bin, var2binby, binsize, posdata, pos2use);
end

