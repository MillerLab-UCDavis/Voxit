function [IH,HO,HB,OB] = readmlpwts(NAME,I,H,O)
% [IH,HO,HB,OB] = readmlpwts(NAME,I,H,O)   Read a text-format MLP3 file
%    NAME is the name of a 3-layer perceptron ascii weights file, of the
%    kind written and read by qnstrn, qnsfwd etc.  Its geometry is 
%    I input nodes, H hidden nodes and O output nodes.  Return 4 matrices:
%    IH are the input-to-hidden weights, with one column per hidden unit.
%    HO are the hidden-to-output weights, with one *row* per hidden unit.
%    HB and OB are the bias vectors for the hidden and output layers
%    respectively.
% 1998apr29 dpwe@icsi.berkeley.edu

fid = fopen(NAME, 'r');
if (fid == -1)  
  error(['unable to read ', NAME]);
end

%% close the file when we exit (however we exit)
%onCleanup(@()fclose(fid));

% read the file
s = fscanf(fid, '%8s', 1);
if(s~='weigvec') 
  error(['header of "',s,'" is not "weigvec" - invalid format']);
end
ihsize = fscanf(fid, '%d', 1);
if ihsize ~= I*H
  error(['input-hidden size of ',num2str(ihsize),' is not I(',num2str(I),')xH(',num2str(H),')']);
end
IH = zeros(I,H);
IH = fscanf(fid, '%f', [I,H]);
% Now read 2nd weigvec
s = fscanf(fid, '%8s', 1);
%fprintf(1, 's2 = "%s"\n', s);
if(s~='weigvec') 
  error(['2nd header of "',s,'" is not "weigvec" - invalid format']);
end
hosize = fscanf(fid, '%d', 1);
if hosize ~= H*O
  error(['hidden-output size of ',num2str(hosize),' is not H(',num2str(H),')xO(',num2str(O),')']);
end
HO = zeros(H,O);
HO = fscanf(fid, '%f', [H,O]);
% Now read biasvecs
s = fscanf(fid, '%8s', 1);
if(s~='biasvec') 
  error(['1st bias header of "',s,'" is not "biasvec" - invalid format']);
end
hbsize = fscanf(fid, '%d', 1);
if hbsize ~= H
  error(['hidden bias size of ',num2str(hbsize),' is not H(',num2str(H),')']);
end
HB = fscanf(fid, '%f', hbsize);
% Finally, second biasvec
s = fscanf(fid, '%8s', 1);
if(s~='biasvec') 
  error(['2nd bias header of "',s,'" is not "biasvec" - invalid format']);
end
obsize = fscanf(fid, '%d', 1);
if obsize ~= O
  error(['output bias size of ',num2str(obsize),' is not O(',num2str(O),')']);
end
OB = fscanf(fid, '%f', obsize);

fclose(fid);
%% now achieved by onCleanup
