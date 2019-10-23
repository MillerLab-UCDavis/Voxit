function train_mkLabFile(ptchlist, labfile, pitches, times, P)
% train_mkLabFile(ptchlist, labfile, pitches, times, P)
%   Take a list of pitch ground truth files and write out a single
%   pfile of labels taken from the ground truth f0s quantized to
%   the list in <pitches>.
%   <times>, if present, is a cell array of times at which to
%   sample each pitch file to generate the frames to output (to
%   match the features).
% 2013-02-05 Dan Ellis dpwe@ee.columbia.edu

%if nargin < 3
%  minf = 60; % lowest freq / Hz
%  nump = 67; % total number of pitch candidates
%  bpo = 24;  % bins per octave
%  % 60 x 2^(66/24) = 403.6 Hz
%  pitches = minf * 2.^([0:(nump-1)]/bpo);
%end
% No default for pitches - you have to provide it
if nargin < 4; times = []; end
% config struct used just for segs_per_utt
if nargin < 5; P = []; end
P = config_default(P);

% Where to find binaries
bindir = '';  % just hope they are on path
% binaries we need
pfile_create = fullfile(bindir, 'pfile_create');

nptch = length(ptchlist);

% Create the ascii input file for pfile_create
ascfile = [tempname(),'.txt'];

for i = 1:nptch

  if length(times) >= i
    ptimes = times{i};
  else
    ptimes = [];
  end
  
  disp(['Processing ', ptchlist{i},' ...']);
  
  [t,f,p] = pt_read(ptchlist{i}, ptimes);

  % quantize the pitches
  q = freq2pitchix(f', pitches);
  % .. but set the reject frames to one beyond the last label
  q(find(q<0)) = length(pitches)+1;

  % Append to the ascii file
  uf = pfile_uttfrmprefix(size(q, 1), i-1, P.segs_per_utt);  
  pfile_ascwriteappend(ascfile, [uf, q], i==1);

end


% post process

% create pfile
cmd = [pfile_create,' -i ',ascfile,' -l ', num2str(1),' -o ',labfile];
disp(cmd);
system(cmd);
%disp('::: Deleting temporary file.')
%delete(ascfile);
