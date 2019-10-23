function [] = SAcC(files_list, config_file, IS_SRI, more)
% Perform pitch tracking using Subband Autocorrelation Classification
% (SAcC) pitch tracker
%
% USAGE:   SAcC(files_list, config_file, IS_SRI, more_config)
%
% ARGS:    files_list = mandatory, list (one per line) of audio file in any
%                   format and the output file in ascii, separated by a comma
%
%          config_file = optional
%
%          IS_SRI = optional flag to use metadb to access config
%                   file instead of built-in config_read_srs
%      
%
% OUTPUT:  output is saved in ./out/ folder (with corresponding input filenames)
%
% OPTION:    -h = usage instructions will be displayed with all config items explanation
%
%% [2012-05-30] Byung Suk Lee bsl@ee.columbia.edu

if nargin < 1; files_list = '-h'; end
if nargin < 2; config_file = ''; end
if nargin < 3; IS_SRI = 0; end
% Allow 3rd arg to be passed from unix command line
if isstr(IS_SRI) IS_SRI = str2num(IS_SRI); end
if nargin < 4; more = ''; end

VERSION = 1.74;
DATE = 20140123;

%% Help
if strcmp(files_list,'-h') == 1 || nargin > 4
  disp(['run_SAcC v',num2str(VERSION),' of ',num2str(DATE)]);
  disp(['usage: run_SAcC <fileslist> [<configfile> [is_sri [more_config]]]']);
  disp([' Byung Suk Lee bsl@ee.columbia.edu, Dan Ellis dpwe@ee.columbia.edu']);
  return
end

if IS_SRI
  % Use metadb to read config files
  %  - you have to probe for particular fields
  P = config_read_sri(config_file, {'pca_file','wgt_file', ...
                      'norms_file','pcf_file','kdim','nchs','n_s', ...
                      'SBF_sr', 'SBF_fmin', 'SBF_bpo', 'SBF_q', ...
                      'SBF_order', 'SBF_ftype', ...
                      'force_mono', ...
                      'twin', 'thop', ...
                      'hid', 'nmlp', ...
                      'hmm_vp', ...
                      'mat_out', ...
                      'write_pitch', 'write_pvx', ...
                      'write_posteriors', 'write_sbac', 'write_sbpca',...
                      'write_rownum', 'write_time', ...
                      'start_utt', 'incr_utt', ...
                      'disp', 'verbose'});
  [C,D] = config_init();
  % Set the sphere output flag
  [P,D] = config_set('sph_out	1',P,D);
else
  % Implement Adam Janin's version of config file specification
  [P,D] = config_read_srs(config_file);
end

if length(more) > 0
  % optionally accept config params from command line
  [P,D] = config_set(more, P,D);
end

% Set default values for any parameters not yet specified
[P,D] = config_default(P,D);

%% calculate train list features (SBPCA defined by sr,bpo,fmin,nchs,q,order,ftype)
fid = fopen(files_list,'r');
while 1
    line = fgetl(fid);
    if ~ischar(line), break, end
    files = regexp(line,',','split');
    for i = 1:length(files)
      files{i} = stripwsstartend(files{i});
    end
    if length(files) == 2; files{3} = ''; end
    if P.verbose; 
      disp(['Processing Input: ',files{1},' Output: ', files{2}, ...
            ' PEM: ', files{3}]); 
    end
    [out_path] = fileparts(files{2});
    if length(out_path) > 0
      if ~exist(out_path,'dir'), mkdir(out_path); end;
    end
    SAcC_main(files{1},P,files{2},files{3});
    % increment utterance counter
    if P.incr_utt; P.start_utt = P.start_utt+1; end
end
fclose(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function t = stripwsstartend(s)
% Strip white space from start and end of a string
ws= (s==' ' | s==char(9) | s==char(10) | s==char(13));
firstnonws = min(find(ws==0));
lastnonws = max(find(ws==0));
t = s(firstnonws:lastnonws);
