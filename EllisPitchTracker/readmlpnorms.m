function [ofs,sca] = readmlpnorms(NAME,I)
% [ofs,sca] = readmlpwts(NAME,I)   Read a text-format norms file
%    NAME is the name of a ascii norms file, of the kind written and read by
%    qnstrn.  Its geometry is I input nodes.  Return 2 matrices:
%    ofs are the input offsets, sca are the input scales.
% [2012-04-11] Byung Suk Lee bsl@ee.columbia.edu

% nfn = 'trKr_sb48k10.norms';
% fp = fopen(nfn);
% tline = fgetl(fp)
% ofs = fscanf(fp,'%f\n',480);
% tline = fgetl(fp)
% sca = fscanf(fp,'%f\n',480);

fid = fopen(NAME, 'r');
if (fid == -1)  
  fprintf(1, 'readnorms: unable to read %s\n', NAME);
else
  % Now read ofs
  s = fscanf(fid, '%4s', 1);
  if ~strcmp(s,'vec')
    fprintf(1, 'readnorms: header of "%s" is not "vec" - invalid format\n', s);
    fclose(fid);
    return;
  end
  ihsize = fscanf(fid, '%d\n', 1);
  if ihsize ~= I
    fprintf(1, 'readnorms: ofs input size of %d is not I(%d)\n', ihsize, I);
    fclose(fid);
  end
  ofs = fscanf(fid, '%f\n', I);
  % Now read sca
  s = fscanf(fid, '%4s', 1);
  if ~strcmp(s,'vec') 
    fprintf(1, 'readnorms: 2nd header of "%s" is not "vec" - invalid format\n', s);
    fclose(fid);
    return;
  end
  hosize = fscanf(fid, '%d\n', 1);
  if hosize ~= I
    fprintf(1, 'readnorms: sca input size of %d is not I(%d)\n', hosize, I);
    fclose(fid);
  end
  sca = fscanf(fid, '%f\n', I);
  fclose(fid);
end