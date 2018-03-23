function [c, s] = autocorrSAcC(xx,frmL,nfrms,maxlags,winL)
%AUTOCORR SACC is a hacked matlab version of the missing but presumably
%c-code version of Dan Ellis' autocorr in his SAcC pitch tracking package
%  INPUTS
%   xx  the subbanded audio matrix
%   frmL  frame length (samples)
%   nfrms number of frames
%   maxlags max number of lags in autocorr
%   winL  window length (samples)
%
% OUTPUTS
%  c     subbanded autocorrelation functions
%  s     energy in autocorrelation
%   Detailed explanation goes here. Yah right.



c = zeros(maxlags,nfrms);
s = zeros(maxlags,nfrms);

maxlag = floor(maxlags/2-1); % LMM 2/2017 kludge for simplicity. dunno why they were two variables winL and maxlags

for i = 1:nfrms 
    xfrm = xx((i-1)*frmL+1:i*frmL);
    %c(i,:) = xcov(xfrm,xfrm,maxlag); %normalize? see below
    c(:,1) = xcov(xfrm,xfrm,maxlag); 
    s(:,1) = repmat(std(c(i,:)),1,maxlags); % is this what it's supposed to be?
end


end

% From Ellis' autocorr.c
%  * ac[frame*lagL+eta] = \sum_{n=0}^{winL-1} xp[frame*frmL+n]xp[frame*frmL+n+eta]
%  * and to normalize this into a true cosine similarity, 
%  * sc[frame*lagL+eta] = sqrt( (\sum_{n=0}^{winL-1} xp[frame*frmL+n]^2) * (\sum_{n=0}^{winL-1} xp[frame*frmL+n+eta]^2) )