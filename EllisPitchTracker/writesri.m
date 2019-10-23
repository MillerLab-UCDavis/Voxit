function writesri(features, name, filename)

% Write an SRI feature file containing the given features to
% filename. The 'name' argument is used as the feature_name
% header.
% FEATURES: matrix with rows = data and columns = frames
% NAME: name of the feature to be written in header
% filename: filename of the output feature file
%
% e.g. writesri(features, 'mfcc', 'xyz.sph')
%      where features is an mxn matrix; m = datapoints, n = frame index
%
if nargin ~= 3
    disp('type >> help writesri');
    error('Wrong useage --- should be >> writesri(features, name, filename)');
end
% Write temporary header string
tmp = sprintf('NIST_1A\n   LHED\nfile_type -s11 featurefile\nfeature_names -s%d %s\nsample_coding -s7 feature\nsample_byte_format -s2 10\nsample_count -i %d\nsample_n_bytes -i 2\nchannel_count -i 1\nnum_elements -i %d\nnum_frames -i %d\nend_head\n', length(name), name, numel(features), size(features, 1), size(features, 2));

% handle different case
if(strlen(tmp) < 1024 )

    header = strrep(tmp,'LHED','1024');

    fid = fopen(filename, 'w');
    if fid == -1
       error('Could not write %s.', filename);
    end
    fprintf(fid, '%-1024s',header);
    fseek(fid, 1024, 'bof');
    fwrite(fid, features, 'float32', 0, 'ieee-be');
    fclose(fid);

elseif(strlen(tmp) >= 1024 && strlen(tmp) < 2048 )

    header = strrep(tmp,'LHED','2048');

    fid = fopen(filename, 'w');
    if fid == -1
       error('Could not write %d.', filename);
    end
    fprintf(fid, '%-2048s', header);
    fseek(fid, 2048, 'bof');
    fwrite(fid, features, 'float32', 0, 'ieee-be');
    fclose(fid);

elseif(strlen(tmp) >= 2048 && strlen(tmp) < 3072 )

    header = strrep(tmp,'LHED','3072');

    fid = fopen(filename, 'w');
    if fid == -1
       error('Could not write %d.', filename);
    end
    fprintf(fid, '%-3072s', header);
    fseek(fid, 3072, 'bof');
    fwrite(fid, features, 'float32', 0, 'ieee-be');
    fclose(fid);

else

    disp('ERROR! ***HEADER SIZE ABOVE 3072***');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function len = strlen(str)
%  len = strlen(str)
% compute the # of characters in str (ignoring 0s at the end)
%

len = length(str) ;
for i=length(str):-1:1
        if (str(i) ~= 0)
                break ;
        end

        len = len-1;
end

