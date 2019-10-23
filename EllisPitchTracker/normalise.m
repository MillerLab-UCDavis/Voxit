function N = normalise(A)
% NORMALISE Make each column of a (multidimensional) array 
% have a zero mean and one std
% [N] = normalise(A)
%
% kslee@ee.columbia.edu
%


[ndim, nfrm] = size(A);

m = mean(A);

s = std(A,0,1);  % same as std(A)

% Set any zeros to one before dividing
% This is valid, since c=0 => all i. A(i)=0 => the answer should be 0/1=0
s = s + (s == 0);

% normalize each column
N = (A - repmat(m,ndim,1))./repmat(s,ndim,1);
