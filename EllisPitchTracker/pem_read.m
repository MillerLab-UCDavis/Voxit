function T = pem_read(file)
% T = pem_read(file)
%
%   Read a PEM file, which consists of lines of form:
%      <ID> <CHANNEL> <SPEAKER> <START_TIME> <END_TIME>
%   Return T as rows of start_time end_time in seconds
%   corresponding to each region.
%   2012-11-01 Dan Ellis dpwe@ee.columbia.edu

[fn,ch,sid,ss,ee] = textread(file, ...
                             '%s\t%s\t%s\t%f\t%f', ...
                             'delimiter', '\t ', ...
                             'commentstyle', 'shell');

T = [ss,ee];
