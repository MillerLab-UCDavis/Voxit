function P = pfile_uttfrmprefix(nframes, utt, segsperutt)

if nargin < 2;  utt = 0; end
if nargin < 3;  segsperutt = 1; end

% Break up utterance into segsperutt segments
%nframes = size(ac,1);
framesperseg = floor(nframes / segsperutt);
utts = utt*segsperutt ...
       + reshape(repmat([0:segsperutt-1],framesperseg,1), ...
                 segsperutt*framesperseg, 1);
frms = reshape(repmat([0:framesperseg-1]',1,segsperutt), ...
               segsperutt*framesperseg, 1);
xtraframes = nframes - framesperseg*segsperutt;
utts = [utts; utts(end)*ones(xtraframes,1)];
frms = [frms; frms(end)+[1:xtraframes]'];

P = [utts, frms];
