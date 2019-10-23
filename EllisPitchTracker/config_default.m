function [P,D] = config_default(P,D)
% [P,D] = config_default(P,D)
%   Read the default params for SAcC, respecting any already-set vals
%   passed in.
% 2012-06-18 Dan Ellis dpwe@ee.columbia.edu

%if nargin < 1; P = struct(); end
%if nargin < 2; D = containers.Map(); end

if nargin < 1; [P,D] = config_init(); end
if nargin < 2; [C,D] = config_init(); end % but keep passed-in P

% Make sure default values are set
% (first time a value is set takes precedence, so these are defaults)
[P,D] = config_set('funcname	run_SAcC',P,D); % not used, but anyway
%[P,D] = config_set('pca_file	$srcdir/aux/PCA_sr8000_bpo6_nchs24_k10.mat',P,D); %
%[P,D] = config_set('wgt_file	$srcdir/aux/sub_qtr_rats_keele_sr8k_bpo6_sb24_k10_ep5_h100.wgt',P,D); %
%[P,D] = config_set('norms_file	$srcdir/aux/tr_keele_rbf_pinknoise_sr8000_bpo6_nchs24_k10.norms',P,D); %
%[P,D] = config_set('pcf_file	$srcdir/aux/pitch_candidates_freqz.txt',P,D); %
[P,D] = config_set('pca_file	aux/PCA_sr8000_bpo6_nchs24_k10.mat',P,D); %
[P,D] = config_set('wgt_file	aux/sub_qtr_rats_keele_sr8k_bpo6_sb24_k10_ep5_h100.wgt',P,D); %
[P,D] = config_set('norms_file	aux/tr_keele_rbf_pinknoise_sr8000_bpo6_nchs24_k10.norms',P,D); %
[P,D] = config_set('pcf_file	aux/pitch_candidates_freqz.txt',P,D); %
[P,D] = config_set('kdim	10',P,D); %
[P,D] = config_set('nchs	24',P,D); %
[P,D] = config_set('n_s 	5',P,D); %
[P,D] = config_set('SBF_sr	8000',P,D); %
[P,D] = config_set('SBF_fmin	100',P,D); %
[P,D] = config_set('SBF_bpo	6',P,D); %
[P,D] = config_set('SBF_q	8',P,D); %
[P,D] = config_set('SBF_order	2',P,D); %
[P,D] = config_set('SBF_ftype	2',P,D); %
%[P,D] = config_set('tmp_path	./tmp/',P,D); % not used
%[P,D] = config_set('out_path	./out/',P,D); % no longer used
[P,D] = config_set('force_mono	1',P,D); %
[P,D] = config_set('twin	0.025',P,D); %
[P,D] = config_set('thop	0.010',P,D); % 
%[P,D] = config_set('thop	0.005',P,D);%   LMM 170214 try 5ms sampling. NOPE this leads to a cumulative time drift, maybe because the MLP is trained on 10ms?
[P,D] = config_set('hid		100',P,D); %
%[P,D] = config_set('npcf	67',P,D); % not used
[P,D] = config_set('nmlp	68',P,D); %
[P,D] = config_set('hmm_vp	0.1',P,D); %
% dpwe addition
[P,D] = config_set('disp	0',P,D);
[P,D] = config_set('verbose	0',P,D);
[P,D] = config_set('sph_out	0',P,D);
[P,D] = config_set('mat_out	0',P,D);
[P,D] = config_set('write_pitch	1',P,D);
[P,D] = config_set('write_pvx	1',P,D);
% raw subband ac/pca output
[P,D] = config_set('write_posteriors	0',P,D);
[P,D] = config_set('write_sbac	0',P,D);
[P,D] = config_set('write_sbpca	0',P,D);
% headers for different pitch track files
[P,D] = config_set('write_rownum	1',P,D);
[P,D] = config_set('write_time	0',P,D);
% start utterance for column-numbered text output (for pfile_create input)
[P,D] = config_set('start_utt	0',P,D);
[P,D] = config_set('incr_utt	0',P,D);
% Used to break pfile/label utterances into multiple segments in train_
[P,D] = config_set('segs_per_utt	1', P,D);


