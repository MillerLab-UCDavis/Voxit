function times = train_mkFtrFile(wavlist, pfilename, normsfilename, P, starts, durs)
% times = train_mkFtrFile(wavlist, pfilename, normsfilename, P, starts, durs)
%    Take a list of audio files, convert them into SBAC features,
%    and write them out to a pfile.  Also calculate the normsfile.
%    P is the SAcC params structure (defines filterbank, mapping
%    file, etc.)
%    <times> returns a cell array of the actual feature frame times
%    within each segment, to use with makePitchTargetFile.
%    starts, durs are vectors for modifying the samples used in
%    each file.
% 2013-02-05 Dan Ellis dpwe@ee.columbia.edu

if nargin < 3; normsfilename = ''; end
if nargin < 4; P = []; end
if nargin < 5; starts = 0; end
if nargin < 6; durs = 0; end

P = config_default(P);

% Where to find binaries
bindir = '';  % just hope they are on path
% binaries we need
qnnorm = fullfile(bindir, 'qnnorm');
pfile_create = fullfile(bindir, 'pfile_create');

% from SAcC_main.m

%% Load the PCA mapping (of keele dataset)
load(P.pca_file,'mapping')

% design the filterbank
[fbank.b,fbank.a,fbank.delay,w2,cf] = bpfiltbank(P.SBF_sr,P.SBF_fmin,P.SBF_bpo,P.nchs,P.SBF_q,P.SBF_order,P.SBF_ftype);

insize = P.kdim * P.nchs;

nwav = length(wavlist);

% Create the ascii input file for pfile_create
ascfile = [tempname(),'.txt'];
%fp = fopen(ascfile, 'w');

times = cell(nwav);

for i = 1:nwav

  disp(['Processing ', wavlist{i},' ...']);
  
  % from preprocessing_sbac/sub_pre_sbac
  % Maybe retrieve per-track start & dur; cycle them around
  start = starts(1+mod(i-1, length(starts)));
  dur = durs(1+mod(i-1, length(durs)));
  x = audioread(wavlist{i}, P.SBF_sr, P.force_mono, start, dur);
  
  % from SAcC_pitchtrack
  % Calculate subband PCA feature
  ac = cal_ac(x, P.SBF_sr, mapping, fbank, P.twin, P.thop, P.n_s, P.verbose);
  
  times{i} = P.thop*[0:(size(ac,1)-1)];
  
  % Append to the ascii file
%  for j = 1:size(ac,1)
%    % header columns
%    fprintf(fp, '%d %d ', i-1, j-1);
%    % data columns
%    fprintf(fp, '%.5g ', ac(j,:));
%    % EOL
%    fprintf(fp, '\n');
%  end

  uf = pfile_uttfrmprefix(size(ac,1), i-1, P.segs_per_utt);  
  pfile_ascwriteappend(ascfile, [uf, ac], i==1);

end

% post process
%fclose(fp);

% create pfile
cmd = [pfile_create,' -i ',ascfile,' -f ', num2str(insize),' -o ',pfilename];
disp(cmd);
system(cmd);
%disp('::: Deleting temporary file.')
%delete(ascfile);
disp(['Did not delete ',ascfile]);

% create norms file
% Create name if none specified
if length(normsfilename)==0
  [p,n,e] = fileparts(pfilename);
  normsfilename = fullfile(p, [n,'.norms']);
end
cmd = [qnnorm, ' norm_ftrfile=',pfilename, ...
       ' output_normfile=', normsfilename];
disp(cmd); 
system(cmd);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mydlmwrite(file, data, varargin)
% my version controls formatting

if strcmp(varargin{1}, '-append')
  mode = 'a';
else
  mode = 'w';
end

fp = fopen(file, mode);

[nr, nc] = size(data);

for i = 1:nr
  fprintf(fp, '%d %d', data(i,1), data(i,2));
  fprintf(fp, ' %0.5g', data(i, 3:end));
  fprintf(fp, '\n');
end

fclose(fp);
