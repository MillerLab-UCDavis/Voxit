function [e, cf] = cochlearfilt(x, sr, nchs)
%
% [e, cf] = cochlearfilt(x, sr, nchs)
% x is input waveform and sr is sampling rate.
% The x is filtered into channles by a cochlear filtering and 
% the envelopes e in each channle are extracted with different 
% methods according to cf that is a vector of the actual center frequencies.
% 
% kslee@ee.columbia.edu, 6/16/2005
% bsl@ee.columbia.edu, 4/19/2011

% To make sure that the input is always a row vector.
x = x(:)';

% First, filter into subbands from 80 Hz to 800Hz , 55 channels
if ~exist('nchs','var'), nchs = 48; end;
fmin = 100;bpo=16; q=8; n=2; ftype =2;

% Design Lyon-Slaney filters
[b2,a2,t2,w2,cf] = bpfiltbank(sr,fmin,bpo,nchs,q,n,ftype);  % type 2 is LySla

% Filter the signal by the slaney fbank, and then half-wave rectify it.
e = filterbank(b2,a2,x,1,0,t2);









