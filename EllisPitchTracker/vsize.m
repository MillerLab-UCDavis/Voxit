function s = vsize(v)
% S = vsize(V)       Find the total number of elements in V i.e. prod(size(V)).
% dpwe 1994may23

s1 =size(v);
s = s1(1)*s1(2);
