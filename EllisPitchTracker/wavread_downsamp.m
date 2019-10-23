function [d,sr] = wavread_downsamp(F,N,M,DS)
% [d,sr] = wavread_downsamp(F,N,M,DS)
%     Read a wavfile like wavread(), but support downsampling by 2
%     or 4 too, to avoid having to load very large, over-detailed
%     files into memory.  Works by reading the file in chunks.
%     N is starting sample, or sample range (if 2 elements) (at
%     output SR)
%     M = 1 means force to be mono.
%     DS is the downsampling factor (1/2/4).
% 2011-09-07 Dan Ellis dpwe@ee.columbia.edu

if nargin < 2; N = []; end
if nargin < 3; M = 0; end
if nargin < 4; DS = 1; end

% Convert N to original sampling rate
N = 1+DS*(N-1);

chunksize = 1000000;
buffer = 48;

[SIZ,sr] = wavread(F,'size');

if length(N) == 0
  % whole file
  N = [1 SIZ(1)];
elseif length(N) == 1
  % just length
  N = [1 N];
end
% clip to file length
N(2) = min(N(2),SIZ(1));

bsamp = N(1) - 1;
nsamp = N(2) - (N(1)-1);

maxnsamp = SIZ(1);

ndsamp = ceil(nsamp/DS);

chans = SIZ(2);
if M; chans = 1; end

d = zeros(ndsamp,chans);

for i = 1:ceil(nsamp/chunksize)
  
  % Load in a chunk
  base = (i-1)*chunksize;
  firstsamp = bsamp + base - buffer;
  lastsamp = min(maxnsamp, bsamp + base + chunksize + buffer);

  if firstsamp < 0
    padz = -firstsamp;
    firstsamp = 0;
  else
    padz = 0;
  end
  
  N = [firstsamp+1 lastsamp];
  
  [dd,sr] = wavread(F,N);

  if M  % force mono
    dd = mean(dd,2);
  end
  
  if padz > 0
    dd = [zeros(padz,chans);dd];
  end
    
  dd = resample(dd,1,DS);
  
  dbase = base/DS;
  dsamps = (dbase+1):min(ndsamp,dbase+chunksize/DS);
  d(dsamps,:) = dd(buffer/DS + dsamps - dbase,:);
end

% return effective SR
sr = sr/DS;


