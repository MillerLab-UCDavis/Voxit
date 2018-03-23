function [signal] = filterb(signal,filterBands,Fs,filterorder)
% filterbank, default butterworth


typef= 0; %% IIR butterworth
%for filterBand = 1:length(filterBands)
for filterBand = 1:size(filterBands,1)
    hicutoff = filterBands(filterBand,1);
    locutoff = filterBands(filterBand,2);
    [b, a, labelf, v] = filter_tf(typef, filterorder, hicutoff, locutoff, Fs);  % design the filter 
    if hicutoff~=0 && locutoff~=0        
        datalowpass   = filtfilt(b(1,:),a(1,:),signal);
        datahighpass  = filtfilt(b(2,:),a(2,:),signal);
        signal = datalowpass + datahighpass;
    else
        signal = filtfilt(b,a, signal);
    end
end