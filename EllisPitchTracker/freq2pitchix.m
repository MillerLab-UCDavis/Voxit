function pix = freq2pitchix(f, freqs)
% pix = freq2pitchix(f, freqs)
%   Take a matrix of frequencies in Hz and quantize to the nearest
%   values in <freqs>, returning the indexes.
%   Zeros in f become zeros in pix; negative values in f become -1
%   in pix.
% 2013-02-06 Dan Ellis dpwe@ee.columbia.edu

% f may contain zeros (unvoiced, map to zero) or negative values
% (don't care, map to -1).

if nargin < 2;
  minf = 60; % lowest freq / Hz
  nump = 67; % total number of pitch candidates
  bpo = 24;  % bins per octave
  % 60 x 2^(66/24) = 403.6 Hz
  freqs = minf * 2.^([0:(nump-1)]/bpo);
end

% Initialize pix to same size as f
pix = 0*f;
lf = length(f(:));

% Find nearest
dds = abs(repmat(f(:)', length(freqs), 1) ...
          - repmat(freqs(:),1, lf));
[vv,pix(:)] = min(dds);

pix(find(f(:) == 0)) = 0;
pix(find(f(:) < 0)) = -1;
