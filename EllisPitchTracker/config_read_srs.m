function [C,D] = config_read_srs(F,C,D)
% function [C,D] = config_read_srs(F,C,D)
%   Read the System-for-Running-Systems Config file named by F
%   and return a structure C with all the config values as fields
%   e.g. C.corpus_audio_dir .
%   Implements spec by Adam Janin at
%   https://sites.google.com/site/babelswordfish/system-for-running-systems-srs/srs-config-tutorial
%   Optional C input is a structure with existing fields to add to and not
%   to overwrite. 
%   Optional D input is a set of variable bindings, i.e. a containers.Map
%   D('name') = 'value';  D output is the definitions established
%   in the config file.
%   Real work is done by config_set.
% 2012-05-30 Dan Ellis dpwe@ee.columbia.edu

if nargin < 2; [C,D] = config_init(); end
if nargin < 3; [P,D] = config_init(); end % but keep passed-in C

% empty F just initializes data structures
if length(F) > 0

  if exist(F,'file') == 0
    error(['config_read_srs: ',F,' not found']);
  end

  fid = fopen(F);

  while ~feof(fid)
    [C,D] = config_set(fgetl(fid),C,D);
  end

  fclose(fid);

end
