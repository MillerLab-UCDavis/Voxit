function [B,A,T,BW,FC] = bpfiltbank(SR, FMIN, BPO, BANDS, Q, N, TYPE, VERBOSE)
% [B,A,T,BW,FC] = bpfiltbank(SR,FMIN,BPO,BANDS,Q,N,TYPE,VERB) Design IIR filtrbank.
%	Returns matrices B and A where each row is the coefficient 
%	definitions for an IIR constant-Q band-pass filter. 
%	Their center frequencies range logarithmically from 
%	FMIN with BPO bands per octave in BANDS steps.  Each filter 
%	is designed by iirbpfilt.m to have a quality factor Q 
%	and an order 2*N.   If TYPE is present and 1, use hand-designed 
%	filters.  If TYPE is 2, use Slaney/Patterson.  If TYPE is 3, use 
%	the 'twoptwoz' filters, else use bilinear designs.
%	TYPE=4 is modified Slaney/Patterson with CQ down to lowest freqs.
%	T is a vector of 'group delay' in samples within each channel.
%	BW is a vector of bandwidths of each channel (not CQ for Sla-Pat).
%	FC is a vector of the actual center frequencies.
%       VERB=1 for messages
% dpwe 1994jun21.  Uses iirbpfilt.m

if nargin < 7; TYPE=0; end
if nargin < 8; VERBOSE=0; end

FMAX = FMIN*exp(log(2)*BANDS/BPO);

if (FMIN <= 0) %( || FMAX <= FMIN)
  error('bpfiltbank: must be 0 < FMIN < FMAX (log scaling)');
end

logfreqfactor = log(FMAX/FMIN)/BANDS;
logminfreq    = log(FMIN);
fmax = exp(logminfreq + BANDS * logfreqfactor);

%%%%%%%%%%%%% If using bilbpf, not iirbpf, must force N to 1 %%%%%%%%%%%
% N=1;
%%% not anymore

MODE = 3;

cf = exp(logminfreq);
if TYPE == 1
%  [b,a,t,bw] = iirbpfilt(SR, cf, Q, N, MODE);
  [b,a,t,bw] = iirbpfilt(SR, cf, Q, N, 0);
  if VERBOSE; disp(['Using all-pole filterbank, frq=' num2str(FMIN) '..' num2str(fmax) ', bpo=' num2str(BPO)]);end
elseif TYPE == 2
  [b,a,t,bw] = MakeERBFilter(SR, cf);
  if VERBOSE; disp(['Using Slaney-Patterson filterbank, frq=' num2str(FMIN) '..' num2str(fmax) ', bpo=' num2str(BPO)]);end
elseif TYPE == 3
  [b,a,t,bw] = twoptwozfilt(SR, cf, Q, N);
  if VERBOSE; disp(['Using 2Npole, 2zero filterbank, frq=' num2str(FMIN) '..' num2str(fmax) ', bpo=' num2str(BPO)]);end
elseif TYPE == 4
  [b,a,t,bw] = MakeERBFilter(SR, cf, 1);
  if VERBOSE; disp(['Using CQ-modified Slaney-Patterson filterbank, frq=' num2str(FMIN) '..' num2str(fmax) ', bpo=' num2str(BPO)]);end
else
  error('Bilinear disabled to work without sigproctb');
%  [b,a,t,bw] = bilbpf(SR, cf, Q, N);
%  disp(['Using Bilinear-transform filterbank, frq=' num2str(FMIN) '..' num2str(fmax) ', bpo=' num2str(BPO)]);
end

A = zeros(BANDS, vsize(a));  % N=1 -> [1 2 1] filter, N=2 -> [1 4 6 4 1]
B = zeros(BANDS, vsize(b));  % was 2 for iirbpfilt
T = zeros(BANDS, 1);
BW = zeros(BANDS, 1);
FC = zeros(1,BANDS);

A(1, :) = a;
B(1, :) = b;
T(1)    = t;
BW(1)   = bw;
FC(1)   = cf;

for filter = 2:BANDS
  cf = exp(logminfreq + (filter - 1)*logfreqfactor);
  if TYPE == 1
%    [b,a,t,bw] = iirbpfilt(SR, cf, Q, N, MODE);
    [b,a,t,bw] = iirbpfilt(SR, cf, Q, N);
  elseif TYPE == 2
    [b,a,t,bw] = MakeERBFilter(SR, cf);
  elseif TYPE == 3
    [b,a,t,bw] = twoptwozfilt(SR, cf, Q, N);
  elseif TYPE == 4
    [b,a,t,bw] = MakeERBFilter(SR, cf, 1);
  else
%    [b,a,t,bw] = bilbpf(SR, cf, Q, N);
    error('bilinear disabled - no SPTB');
  end
  A(filter, :) = a;
  B(filter, :) = b;
  T(filter)    = t;
  BW(filter)   = bw;
  FC(filter)   = cf;
end
