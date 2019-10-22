function [pfreq,times]=SAcCWrapper(filename);
% FUNCTION SAcC WRAPPER
%  Wrapper for Dan Ellis' subband autocorrelation pitch tracker 
% https://github.com/dpwe/SAcC

%klunky way to find SAaC path. Maybe a problem: make Matlab window wide before running, or the directory listings will be truncated?
strToFind = 'EllisPitchTracker'; % Return all search path directories containing this string
if ispc %LMM190214 added annoying check to work across OS
    dirs = regexp(path,['[^;]*'],'match'); % List all paths in search path and break them into a cell array 
else
    dirs = regexp(path,['[^:]*'],'match'); % List all paths in search path and break them into a cell array 
end
whichCellEntry = find(cellfun(@(dirs) ~isempty( strfind(dirs, strToFind) ), dirs) == 1);% Index to cell entries containing the desired string
if length(whichCellEntry)>1
    warning('More than one EllisPitchTracker directory on your path. Taking the first, presumed top level.')
    whichCellEntry = whichCellEntry(1);
end
SAaCpath = [dirs{whichCellEntry}  filesep];
%addpath(SAaCpath);

[fpath,fn,fext] = fileparts(filename);
out_file = [fpath filesep fn 'SAcC.mat'];

config_file = [SAaCpath filesep 'conf' filesep 'rats_sr8k_bpo6_sb24_k10.config'];
[P,D] = config_read_srs(config_file);
P = config_default(P); % note this is just getting remaining defaults for 2012 code not 2013 SAcC update. See end of script for all the new defaults

%disp('RUNNING SAcC. May correspond better with Drift using weights and other params from UPDATED https://github.com/maxhawkins/drift/blob/master/ellis/SAcC.py#L33') 
%disp('take out any parameters NOT set in python?')

% P.pca_file = 'aux/updated_pca_sr8k_bpo6_sb24_k10.mat';
% P.wgt_file = 'aux/updated_sub_qtr_rats_keele_sr8k_bpo6_sb24_k10_ep5_h100.wgt';
% P.norms_file='aux/updated_sub_qtr_rats_keele_sr8k_bpo6_sb24_k10_ep5_h100.norms';
% P.pcf_file=  'aux/pitch_candidates_freqz.txt';

%P.pca_file = 'aux/py_mapping-pca_sr8k_bpo6_sb24_k10.mat';
P.pca_file = ['aux' filesep 'pca_sr8k_bpo6_sb24_k10.mat']; % py mapping is not a cell. looks to be same info
P.wgt_file = ['aux' filesep 'py_sub_qtr_rats_keele_sr8k_bpo6_sb24_k10_ep5_h100.wgt'];
P.norms_file=['aux' filesep 'py_tr_keele_rbf_pinknoise_sr8000_bpo6_nchs24_k10.norms'];
P.pcf_file=  ['aux' filesep 'py_pitch_candidates_freqz.txt'];

P.nchs = 24;
P.n_s = 5.0;  % secs per process block, controls blockframes. HEY this is different from original 10!
P.SBF_sr =8000;
PSBF_fmin = 100.0;
P.SBF_bpo = 6.0;
P.SBF_q = 8.0;  % not actually used for SlanPat ERB filters
P.SBF_order = 2;  % not actually used for SlanPat ERB filters
P.SBF_ftype = 2;  % ignored in python, which is is always SlanPat ERB
%disp('check if matlab and python filters are the same')
P.twin = 0.025;  %autoco window len
P.thop = 0.010;
P.hmm_vp = 0.1; % interpretation changed python is 0.9
P.dither_level = 1e-3;
P.mat_out = 1;
P.write_rownum = 1;
P.write_time = 1;
P.write_pitch = 1;
Pwrite_pvx = 1;


P.dirSAcC = SAaCpath;
% fix slashes and add underscore for windows paths (better yet, make it platform-independent!)
P.pca_file(findstr(P.pca_file,'/'))= filesep;
P.pca_file   = ['w' P.pca_file];
P.wgt_file(findstr(P.wgt_file,'/'))= filesep;
P.wgt_file   = ['w' P.wgt_file];
P.norms_file(findstr(P.norms_file,'/'))= filesep;
P.norms_file = ['w' P.norms_file];
P.pcf_file(findstr(P.pcf_file,'/'))= filesep;
P.pcf_file   = [SAaCpath 'w' P.pcf_file]; % this one is called without the full path, in SAaC_pitchtrack.m, so add path here


%% main function
[pfreq,lobs,pvx,times] = SAcC_main(filename,P,out_file);


%%
pfreqnan = pfreq;  % make pitch 0's to nan's for plotting
pfreqnan(find(pfreq==0)) = nan;
figure, hold on
plot(times,pfreqnan,'LineWidth',2);
if strfind(filename,'\')
    if1 = strfind(filename,'\'); % get rid of path
    if2 = max(strfind(filename,'.'));
    if1 = if1(max(find(if1<if2)));
    ftitle= filename(if1+1:if2-1);
else
    ftitle= filename;
end
title(['SacC ' ftitle])
xlabel('time (s)')
ylabel('F0 (Hz)')
% 
% % to compare with Drift csv output, add
% [num,txt,raw]=xlsread(fileDrift);
% plot(num(:,1),num(:,2),'r');
% plot(num(:,1),num(:,2),'ro');
% legend('SAcC','drift')




%% new defaults as per SAcC python code, which is what Drift uses https://github.com/maxhawkins/drift/blob/master/ellis/SAcC.py#L333
%     """ Provide a set of default configuration parameters."""
%     # Setup config
%     config = {}
%     # sbpca params
%     # diff file for py
%     config['pca_file']    = os.path.join(
%         AUX_DIRECTORY, 'mapping-pca_sr8k_bpo6_sb24_k10.mat')
%     #config['kdim'] = 10 # inferred from mapping file
%     config['nchs']        = 24
%     config['n_s']         = 5.0  # secs per process block, controls blockframes
%     config['SBF_sr']      = 8000.0
%     config['SBF_fmin']    = 100.0
%     config['SBF_bpo']     = 6.0
%     config['SBF_q']       = 8.0  # not actually used for SlanPat ERB filters
%     config['SBF_order']   = 2  # not actually used for SlanPat ERB filters
%     config['SBF_ftype']   = 2  # ignored - python is always SlanPat ERB
%     config['twin']        = 0.025  # autoco window len
%     thop = 0.010
%     config['thop']        = thop  # autoco hop
%     # mlp params
%     #config['wgt_file']    = os.path.join(
%     #    AUX_DIRECTORY, 'rats_sr8k_bpo6_sb24_k10_aCH_h100.wgt')
%     #config['norms_file']  = os.path.join(
%     #    AUX_DIRECTORY, 'tr_rats_sr8k_bpo6_sb24_k10.norms')
%     config['wgt_file']    = os.path.join(
%         AUX_DIRECTORY, 'sub_qtr_rats_keele_sr8k_bpo6_sb24_k10_ep5_h100.wgt')
%     config['norms_file']  = os.path.join(
%         AUX_DIRECTORY, 'tr_keele_rbf_pinknoise_sr8000_bpo6_nchs24_k10.norms')
%     #config['nhid'] = 100 # inferred from wgt file, + input size from norms file
%     #config['nmlp'] = 68  # output layer size, inferred from wgt file
%     config['pcf_file']    = os.path.join(
%         AUX_DIRECTORY, 'pitch_candidates_freqz.txt')
%     # viterbi decode params
%     config['hmm_vp']      = 0.9 # interpretation changed c/w Matlab
%     # output options
%     config['write_rownum'] = 0 # prepend row number
%     config['write_time']  = 1  # prepend time in seconds to output
%     config['write_sbac'] = 0   # output raw autocorrelations (big - 24 x 200)
%     config['write_sbpca'] = 0  # output subband pcas (24 x 10)
%     config['write_posteriors'] = 0 # output raw pitch posteriors (68)
%     config['write_pitch'] = 1  # output the actual pitch value in Hz (1)
%     config['write_pvx'] = 1    # output just 1-posterior(unvoiced) (1)
%     # Tricks with segmenting utterances not implemented in Python
%     config['start_utt'] = 0    # what utterance number to start at
%     #config['incr_utt'] = 0     # increment the utterance each seg (?)
%     #config['segs_per_utt'] = 1 # break each utterance into this many segs
%     config['verbose'] = 0
%     #config['disp'] = 0         # no display code in Python
%     # Output file format is the concern of the calling layer
%     #config['sph_out'] = 0
%     #config['mat_out'] = 0
%     #config['txt_out'] = 1
% config['dither_level'] = 1e-3