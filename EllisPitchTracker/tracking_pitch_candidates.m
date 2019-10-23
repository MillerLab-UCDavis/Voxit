function [path,posterior,zobslik,obslik,newtransmat] = tracking_pitch_candidates(obslik, vp,transfloor, wdyn, wobs, maxplags, prior, uvtrp, vutrp, transmat)
% VITERBI Find the most-probable (Viterbi) path through the HMM state trellis.
%
% [path,posterior,zobslik] = tracking_pitch_candidates(obslik, transfloor,
%                      wdyn, wobs, maxplags, prior, uvtrp, vutrp, transmat)
%
% Inputs:
% prior(i) = Pr(Q(1) = i)
% transmat(i,j) = Pr(Q(t+1)=j | Q(t)=i)
% obslik(i,t) = Pr(y(t) | Q(t)=i)
%
% Outputs:
% path(t) = q(t), where q1 ... qT is the argmax of the above expression.
% delta(j,t) = prob. of the best sequence of length t-1 and then going to state j, and O(1:t)
% psi(j,t) = the best predecessor state, given that we ended up in state j at t
%
%% [2011-12-05] Byung Suk Lee bsl@ee.columbia.edu
%% Modified: recovered the probability considering no-pitch state
%% Modified: to accomodate pitch candidate domain and the transition floor
%% Modified: to work with QuickNet output [2012-02-28]

%%
scaled = 1;

%%
zobslik = obslik(1,:);

%%
[Q, T] = size(obslik);

if ~exist('transfloor','var')
    transfloor = -10; %% the floor of pitch transition matrix in dB
end

if ~exist('wdyn','var')
    wdyn = 3;
end

%% observation weight
if ~exist('wobs','var')
    wobs = 1;
end
obslik = wobs * obslik;

if ~exist('prior','var')
%     prior = zeros(Q,1);
    prior = log([vp;ones(Q-1,1)]);
%     prior = log([0.1;ones(Q-3,1);0.01;0.01]);
end

%plot(std(obslik)) % yes, the log-probs passed in have unit var
obslik = obslik + repmat(prior,1,size(obslik,2));

if ~exist('maxplags','var')
    maxplags = Q-1; % number of pitch candidates = Q - 1 (for no-pitch)
end

%%
if ~exist('uvtrp','var')
    uvtrp = 0.1;
end

%%
if ~exist('vutrp','var')
    vutrp = 0.1*uvtrp;
end

%%
if ~exist('sadtrp','var')
    sadtrp = 0.1;
    uvtrp = sadtrp;
    vutrp = 0.1*sadtrp;
end

%%
if ~exist('transmat','var')
    %% sad transition probabity for pitch candidates
    transmat = log([(1-uvtrp), uvtrp; vutrp, (1-vutrp)]);
end

plags = [1:maxplags];
delta = zeros(Q,T); % max sum of log-probability for each time frame
psi = zeros(Q,T); % argmax{state} with max probability for each time frame
path = zeros(1,T);
scale = ones(1,T);

have_viterbi_helper = (exist('viterbi_path_LOG_helper') == 3);

if ~have_viterbi_helper && exist('viterbi_path_LOG_helper.c','file')
  % Attempt to compile mex
  disp('Attempting to compile viterbi_path_LOG_helper...');
  try
    mypwd = pwd();
    cd(fileparts(which('pitch_tracking')));
    mex('viterbi_path_LOG_helper.c');
    cd(mypwd);
  catch me
    disp('...failed');
    % ignore
  end
  have_viterbi_helper = (exist('viterbi_path_LOG_helper') == 3);
end

%%
pdo = repmat(plags,Q-1,1) - repmat((1:Q-1)',1,length(plags));
pdo = exp(-abs(pdo)/wdyn) + exp(transfloor);
pdo = pdo./repmat(sum(pdo,2),1,Q-1);
pdo = log(pdo);

%%
newtransmat = [ [transmat(1,1),transmat(2,1)*ones(1,Q-1)]', ...
                [transmat(1,2)*ones(length(plags),1),transmat(2,2)/(Q-1) + pdo]'];

% Actually, assuming rows are from, cols are to, this transition
% matrix is not normalized, but the "from UV" row is 
% log(0.9 0.1*ones(67)), i.e. the self-loop mass is 0.9/(0.9+6.7)
% or around 0.12 (not the apparent 0.9)

if have_viterbi_helper
  [delta, psi, scale] = viterbi_path_LOG_helper(obslik, prior, newtransmat, scaled);
else

  disp('Using plain MAT...');
  %%
  t=1;
  delta(:,t) = prior + obslik(:,t);
  if scaled
      delta(:,t) = (delta(:,t) - mean(delta(:,t)));
  end
  psi(:,t) = 0; % arbitrary value, since there is no predecessor to t=1
  %%
  for t=2:T   
      for j=1:Q
        [delta(j,t), psi(j,t)] = max(delta(:,t-1) + newtransmat(:,j));
        delta(j,t) = delta(j,t) + obslik(j,t);
      end
      if scaled
        delta(:,t) = (delta(:,t) - mean(delta(:,t)));
      end
  end

end

%%
[posterior(T), path(T)] = max(delta(:,T));
for t=T-1:-1:1
    path(t) = psi(path(t+1),t+1);
    posterior(t) = delta(path(t),t);
end
path = path - 1;
