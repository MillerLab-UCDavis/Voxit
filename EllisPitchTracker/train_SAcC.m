function train_SAcC(idlist, audiodir, audioext, gtdir, gtext, name, nhid, pitches)
% train_SAcC(idlist, audiodir, audioext, gtdir, gtext, nhid, pitches)
%    Train an SAcC net using the specified files in <idlist>,
%    (can be a cell array, or the name of a text file)
%    calculating the SBAC features on audio found in audiodir with
%    audioext, and using targets derived from the label files in
%    gtdir.
%    <name> is the stem used to tag output files (default 'train')
%    <nhid> is the number of hidden units (100).
%    <pitches> is a vector of pitch quantization values (default
%    67 bins from 60 Hz to 400 Hz (24 bins/octave))
% 2013-02-05 Dan Ellis dpwe@ee.columbia.edu

if nargin < 6; name = 'train'; end
if nargin < 7; nhid = 100; end
if nargin < 8
  minf = 60; % lowest freq / Hz
  nump = 67; % total number of pitch candidates
  bpo = 24;  % bins per octave
  % 60 x 2^(66/24) = 403.6 Hz
  pitches = minf * 2.^([0:(nump-1)]/bpo);
end

VERSION = 1.74;
DATE = 20140123;

disp(['*** train_SAcC v',num2str(VERSION),' of ',num2str(DATE),' ***']);

% Is idlist actually a file to read?
if ischar(idlist)
  idlist = textread(idlist, '%s', 'commentstyle', 'shell');
end

% if nhid is passed on command line (and is a string), convert to num
if ischar(nhid);      nhid = sscanf(nhid,'%f'); end

feanam = 'sbac';
labnam = ['ptch', num2str(length(pitches))];

feafilename = [name,'-',feanam,'.pf'];
nrmfilename = [name,'-',feanam,'.norms'];
labfilename = [name,'-',labnam,'.pf'];
wgtfilename = [name,'-',feanam,'-',labnam,'-h',num2str(nhid),'.wgt'];

SAcCparams.SBF_sr = 8000; % subband sampling rate
SAcCparams.SBF_bpo = 6; % subbands per octave
SAcCparams.nchs = 24; % number of subbands
SAcCparams.kdim = 10; % number of PCA coefficients
SAcCparams.pca_file = 'aux/PCA_sr8000_bpo6_nchs24_k10.mat';

if length(audiodir) > 0
  if audiodir(end) ~= '/'; audiodir = [audiodir, '/']; end
  times = train_mkFtrFile(addprefixsuffix(idlist, audiodir, audioext), ...
                          feafilename, nrmfilename, SAcCparams);
else
  % assume using existing feafile, fake times
  if ~exist(feafilename, 'file')
    error(['No audio dir, but existing feature file ',feafilename, ...
           ' not found']);
  end
  dt = 0.01;
  [R,U] = pfinfo(feafilename);
  for i = 1:U
    times{i} = dt*[0:pfinfo(feafilename,i-1)-1];
  end
end

if length(gtdir) > 0
  if gtdir(end) ~= '/'; gtdir = [gtdir, '/']; end
  train_mkLabFile(addprefixsuffix(idlist, gtdir, gtext), ...
                  labfilename, pitches, times);
else
  % if no gtdir, assume lab pf already written
  if ~exist(labfilename, 'file')
    error(['No gtruth dir, but existing lab file ',labfilename, ...
           ' not found']);
  end
end

MLPparams.mlp_hid_size = nhid;
MLPparams.mlp_out_size = length(pitches)+1;

train_mkMLP(feafilename, nrmfilename, labfilename, wgtfilename, ...
            MLPparams, name);

% construct the pitch value list file
pcffilename = [name, '-pitches.txt'];
fp = fopen(pcffilename, 'w');
fprintf(fp, '%f\n', pitches);
fclose(fp);

% Write out the final SAcC config file
% Fill in defaults
SAcCparams = config_default(SAcCparams);
% overwrite defaults
SAcCparams.wgt_file = wgtfilename;
SAcCparams.norms_file = nrmfilename;
SAcCparams.pcf_file = pcffilename;
SAcCparams.nmlp = MLPparams.mlp_out_size;
SAcCparams.hid = MLPparams.mlp_hid_size;

% write out config file
configfname = [name, '-config.txt'];
config_write(configfname, SAcCparams);
