function C = config_read_sri(F,L,C)
% function C = config_read_sri(F,L,C)
%   Probe an SRI-format config file named by F
%   for all the keys named in cell array L.
%   Resulting values are stored as fields in output structure C,
%   e.g. C.param = 'value';
%   Optional C input is a structure with existing, preset fields 
%   which will be copied to output and will not be modified by
%   values read from config. 
% 2012-05-30 Dan Ellis dpwe@ee.columbia.edu

if nargin < 3; C = struct(); end

nl = length(L);

if length(F) > 0
  configfile = ['-config ',F,' '];
else
  configfile = '';
end
  
for i = 1:nl
  
  tok = L{i};
  
  cmd = ['metadb ',configfile,tok];
  [status, result] = system(cmd);
  result = result(find(result ~= char(10)));
  
  if status ~= 0
    disp(['problem running ',cmd,': ',result]);
  else
    if length(result) > 0
      % We only set this field if it's not already in C
      if ~isfield(C,tok)
        %disp(['*',tok,'* <= *',result,'*'])
        % can we convert it legally to a numeric?  (BUG RISK!)
        dval = str2double(result);
        if ~isnan(dval); result = dval; end
        C = setfield(C,tok,result);
      end
    end
  end

end

