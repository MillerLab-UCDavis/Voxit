function [tt,f0,pvx] = pt_read(filename, times)
% [tt,f0,pvx] = pt_read(filename, times)
%    Read a pitch track file.  Files consist of 3 columns:
%    time_sec  pitch_Hz  prob_vx
%    .. which are returned as equal-length rows in <tt>, <f0>, and
%    <pvx>.  Unvoiced frames are labaled with f0 = 0 and pvx < 0.5.
%    Frames missing ground truth are labeled with f0 < 0 and pvx <
%    0. 
%    If <times> is specified, pitches are resampled onto those time
%    instants using nearest neighbor.
% 2013-02-05 Dan Ellis dpwe@ee.columbia.edu

if nargin < 2; times = []; end

if exist(filename, 'file') == 0
  error(['pt file ',filename,' not found']);
end

dat = textread(filename);
tt = dat(:,1)';
f0 = dat(:,2)';
pvx = dat(:,3)';

if length(times)
  % perform resampling onto specified times
  f0 = interp1(tt,f0,times,'nearest');
  pvx = interp1(tt,pvx,times,'nearest');
  tt = times;
end
