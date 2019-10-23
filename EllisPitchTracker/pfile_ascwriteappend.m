function pfile_ascwriteappend(file, data, isnew)
% pfile_ascwriteappend(ascfile, data, isnew)
%    Like dlmwrite, but treats first two columns a ints
%    suitable for pfile_create etc.
%    if isnew == 0, data is appended not overwritten.
% 2013-06-21 Dan Ellis dpwe@ee.columbia.edu


if isnew
  mode = 'w';
else
  mode = 'a';
end

fp = fopen(file, mode);

[nr, nc] = size(data);

for i = 1:nr
  fprintf(fp, '%d %d', data(i,1), data(i,2));
  fprintf(fp, ' %0.5g', data(i, 3:end));
  fprintf(fp, '\n');
end

fclose(fp);
