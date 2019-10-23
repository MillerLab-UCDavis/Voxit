function train_mkMLP(feafile, normfile, labfile, wgtfile, P, stem)
% train_mkMLP(feafile, normfile, labfile, wgtfile, P, stem)
%    Train a pitch MLP with the specified feature file, norms file,
%    and labelfile, to create an output network in wgtfile.
%    Training parameters are provided in structure P.
%    <stem> is a text tag for the log files (default 'train_mkMLP').
% 2013-02-06 Dan Ellis dpwe@ee.columbia.edu

% from SAcC_train/qnstrn_wrap.m

if nargin < 5; P = []; end
if nargin < 6; [~,stem,~] = fileparts(wgtfile); end

P = params_fill_in(P);

% Where to find binaries
bindir = '';  % just hope they are on path
% binaries we need
qnstrn = fullfile(bindir, 'qnstrn');

% Check pfiles
[R,U,F,L,T] = pfinfo(feafile);
ntrainutts = round(P.train_proportion * U);
trainsentrange = ['0:', num2str(ntrainutts-1)];
cvsentrange = [num2str(ntrainutts),':',num2str(U-1)];

if P.ftr_count == 0
  P.ftr_count = F - P.ftr_start;
end
P.mlp_in_size = P.window_len * P.ftr_count;

% log files
w_log = [stem,'.log'];
w_chklog = [stem,'.chklog'];
w_chk = [stem,'.chk'];

%% run QuickNet
args = [' ftr1_file=',feafile,' hardtarget_file=',labfile];
args = [args, ' hardtarget_format=',P.hardtarget_format];
args = [args, ' ftr1_norm_file=',normfile];
args = [args, ' ftr1_ftr_start=',num2str(P.ftr_start)];
args = [args, ' ftr1_ftr_count=',num2str(P.ftr_count)];
args = [args, ' window_extent=',num2str(P.window_len)];
args = [args, ' mlp3_input_size=',num2str(P.mlp_in_size)];
args = [args, ' mlp3_hidden_size=',num2str(P.mlp_hid_size)];
args = [args, ' mlp3_output_size=',num2str(P.mlp_out_size)];
args = [args, ' train_sent_range=',trainsentrange];
args = [args, ' train_cache_frames=','100000'];
args = [args, ' cv_sent_range=',cvsentrange];
args = [args, ' learnrate_vals=',num2str(P.learn_rate)];
args = [args, ' ftr1_window_len=',num2str(P.window_len)];
args = [args, ' ftr1_window_offset=',num2str(P.window_offset)];
args = [args, ' ftr1_delta_order=','0'];
args = [args, ' ftr1_delta_win=','1',' out_weight_file=',wgtfile];
args = [args, ' hardtarget_window_offset=','0'];
args = [args, ' log_file=',w_log,' log_weight_file=',w_chklog,' ckpt_weight_file=',w_chk];
args = [args, ' hardtarget_lastlab_reject=true'];

cmd = [qnstrn,args];
disp(['train_mkMLP: ',cmd])
%%
system(cmd);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = params_fill_in(Q)
% Set up all default params
if isstruct(Q)
  P = Q; 
else
  P = [];
end

defaults = {'ftr_start', 0, 'ftr_count', 0, ...
            'hardtarget_format', 'pfile', ...
            'window_len', 1, 'window_offset', 0, ...
            'mlp_in_size', 240, 'mlp_hid_size', 100, ...
            'mlp_out_size', 68, ...
            'learn_rate', 0.008, ...
            'train_proportion', 0.8};

for i = 1:2:length(defaults)
  key = defaults{i};
  val = defaults{i+1};
  if ~isfield(P, key)
    P = setfield(P, key, val);
  end
end
