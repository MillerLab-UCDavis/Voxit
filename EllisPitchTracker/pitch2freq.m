function [pathfreq] = pitch2freq(path,freqs)
% convert pitch candidates to freq (Hz)
%
%% [2012-02-07] Byung Suk Lee bsl@ee.columbia.edu
%% [2012-03-26] Byung Suk Lee bsl@ee.columbia.edu
%% modified for quicknet labels

nfrq = length(freqs); % pitch frequency in Hz

path = round(path);
if size(path,1) > size(path,2)
    path = path';
end
pathfreq = zeros(size(path));
for ip = 1:nfrq
    pathfreq(path == (ip)) = freqs(ip);
end
