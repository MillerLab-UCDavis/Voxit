function [pfreq,lobs,pvx,times] = SAcC_main(filename,P,out_file,pem_file)
% function [pitch,lobs,pvx,times] = SAcC_main(filename,P,out_file,pem_file)
%          [pitch,lobs,pvx,times] = SAcC_main(d,sr);
%
%  Perform Subband Autocorrelation Classification (SAcC) pitch tracking
%
%  Parameters are passed in P.
%  Second calling form passes in a waveform.
%
% Reference: B. S. Lee and D. P. W. Ellis, "Noise Robust Pitch Tracking by
% Subband Autocorrelation Classification," Proc. Interspeech, September 2012
% 
% [2012-04-11] Byung Suk Lee bsl@ee.columbia.edu

if nargin < 2; P = []; end
if nargin < 3; out_file = ''; end
if nargin < 4; pem_file = ''; end

%twin = 0.025;
%thop = 0.010;

if ischar(filename)
  % Read input audio
  %[x,sr] = audioread(filename, P.SBF_sr, P.force_mono); 
  [x,srin] = audioread(filename); %LMM 2/12/2017 this audioread was an Ellis function; now using matlab audioread
  if P.force_mono  %LMM 2/12/2017  thus we have to do the mono check and resample by hand
      x = x(:,1);
  end
  if srin~=P.SBF_sr %LMM 2/12/2017
      x = resample(x,P.SBF_sr,srin);
  end
  sr = P.SBF_sr;
else
  % assume passed waveform and sampling rate
  x = filename;
  sr = P;
  P = out_file;
  out_file = pem_file;
  filename = '<passed_in_data>';
end

x_dur = length(x)/sr;

% Did we manage to get parameters?
%if length(P) == 0; 
% Sets any unset parameters
%P = config_default(P); %LMM commented out and put in wrapper so none of the updated SAcC parameters get overwritten
%end

%% Load the PCA mapping (of keele dataset)
%load(P.pca_file,'mapping')
load([P.dirSAcC P.pca_file],'mapping') %LMM 2/17

% design the filterbank
[fbank.b,fbank.a,fbank.delay,w2,cf] = bpfiltbank(P.SBF_sr,P.SBF_fmin,P.SBF_bpo,P.nchs,P.SBF_q,P.SBF_order,P.SBF_ftype);

insize = P.kdim * P.nchs;

% Read MLP weights and norms
[net.IH, net.HO, net.HB, net.OB] = readmlpwts([P.dirSAcC P.wgt_file],insize,P.hid,P.nmlp);
[net.ofs, net.sca] = readmlpnorms([P.dirSAcC P.norms_file],insize);

% Set up the segments
if length(pem_file)
  pem_segs = pem_read(pem_file);
else
  pem_segs = [0 x_dur+(P.twin-P.thop)];
end

% Convert pem times to 10ms frames
pem_segs = round(pem_segs/P.thop);

pfreq = zeros(0, 1); 
pvx = zeros(0, 1); 
lobs = zeros(0, P.nmlp);
D = zeros(0, insize);

nhop = round(P.thop*sr);

for seg = 1:size(pem_segs,1)
  pem_start = pem_segs(seg,1);
  pem_end = pem_segs(seg,2);
  % Apply NaN padding
  pad = NaN*ones(pem_start - size(pfreq,1), 1);
  pfreq = [pfreq; pad];
  pvx = [pvx; pad];
  lobs = [lobs; repmat(pad, 1, P.nmlp)];
  D = [D; repmat(pad, 1, insize)];
  % Run SAcC on new block
  [spfreq, spvx, slobs, sD] = ...
      SAcC_pitchtrack(x(((pem_start*nhop)+1):min(length(x),pem_end*nhop)), ...
                      sr, mapping, fbank, net, P);
  % Accumulate outputs
  pfreq = [pfreq; spfreq];
  pvx = [pvx; spvx];
  lobs = [lobs; slobs];
  D = [D; sD];
end

% Final NaN padding
pad = NaN*ones(1+floor((x_dur-P.twin)/P.thop) - size(pfreq,1), 1);
pfreq = [pfreq; pad];
pvx = [pvx; pad];
lobs = [lobs; repmat(pad, 1, P.nmlp)];
D = [D; repmat(pad, 1, insize)];

% explicit vector of sample times
npitch = size(pfreq,1);
times = [0:npitch-1]*P.thop;

% ftrs has rows = times, cols = features (various)
if length(out_file) > 0
  % Save to out_file
  ftrs = zeros(npitch,0);
  if P.write_rownum
    ftrs = [ftrs, [P.start_utt*ones(npitch,1),[0:(npitch-1)]']];
  end
  if P.write_time
    ftrs = [ftrs, times'];
  end
  if P.write_sbpca
    ftrs = [ftrs, D];
  end
  if P.write_posteriors
    ftrs = [ftrs, lobs];
  end
  if P.write_pitch
    ftrs = [ftrs, pfreq];
  end
  if P.write_pvx
    ftrs = [ftrs, pvx];
  end
  if P.sph_out == 1
    writesri(ftrs' ,'saccpitch',out_file);
    disp(['Wrote SRI-format ',out_file]);
  elseif P.mat_out == 1
    save(out_file,'ftrs');
  else
    dlmwrite(out_file, ...
             ftrs, ...
             'delimiter',' ');
%    fp = fopen(out_file, 'w');
%    for j = 1:size(ftrs,1);
%      fprintf(fp, '%d %d ', ftrs(j,1), ftrs(j,2));
%      fprintf(fp, '%.5g ', ftrs(j,3:end));
%      fprintf(fp, '\n');
%    end
%    fclose(fp);
    disp(['Wrote ASCII-format ',out_file]);
  end
end
