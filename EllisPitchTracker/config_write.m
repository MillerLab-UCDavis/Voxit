function config_write(name, P)
% config_write(name, P)
%   Write a config file recording the fields in P.
%   (for SAcC).
% 2013-02-07 Dan Ellis dpwe@ee.columbia.edu

fp = fopen(name,'w');
if fp == 0
  error(['config_write: could not write to ',name]);
end

fields = fieldnames(P);

for i = 1:length(fields)
  
  val = getfield(P, fields{i});
  
  fprintf(fp, '%s\t%', fields{i});
  if ischar(val)
    fprintf(fp, '%s\n', val);
  elseif val == round(val)
    fprintf(fp, '%d\n', val);
  else
    fprintf(fp, '%.3f\n', val);
  end
  
end

fclose(fp);

disp(['Config params file written to ',name]);
