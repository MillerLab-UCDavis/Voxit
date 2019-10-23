function [C,D] = config_set(S,C,D)
% function [C,D] = config_set(S,C,D)
%   Accept a single statement of config-setting
%   e.g. 'corpus_audio_dir /u/drspeech/audio' 
%   and return a structure C with all the config values as fields
%   e.g. C.corpus_audio_dir = '/u/drspeech/audio' .
%   Implements spec by Adam Janin at
%   https://sites.google.com/site/babelswordfish/system-for-running-systems-srs/srs-config-tutorial
%   Optional C input is a structure with existing fields to add to and not
%   to overwrite. 
%   Optional D input is a set of variable bindings, i.e. a containers.Map
%   D('name') = 'value';  D output is the definitions established
%   in the config file.  Called by read_srs_config
% 2012-05-30 Dan Ellis dpwe@ee.columbia.edu

%disp(['Set srs config ',S]);

if nargin < 2; [C,D] = config_init(); end
if nargin < 3; [P,D] = config_init(); end  % but keep passed-in C

% S can consist of multiple NL-separated lines
spos = 0;
done = 0;
while done == 0
  nextcr = min(find(S(spos+1:end)==char(10)));
  if length(nextcr)
    l = S( (spos+1):(nextcr-1) );
    spos = nextcr;
  else
    % no (more) CRs found
    l = S( (spos+1):end );
    done = 1;
  end
  l = trimws(l);
  % is it empty or a comment?
  if length(l) > 0 && l(1) ~= '#'
    [tok, rest] = firsttok(l);
%    if strcmp(tok, 'DEFINE')
%      % New binding, if we don't have it
%      [name,val] = firsttok(rest);
%      if isKey(D, name) == 0
%        D(name) = val;
%      end
%    else
    if strcmp(tok, 'INCLUDE')
      % recurse down to included file
      [C,D] = read_srs_config(substvars(rest,D,l),C,D);
    else
      % this is a variable definition
      % but only keep the first one
      if isfield(C,tok) == 0
        val = substvars(rest,D,l);
        %disp(['*',tok,'* <= *',val,'*'])
        % defining a field also adds it to the bindings
        % (per Adam email, 2012-08-02)
        D(tok) = val;
        % can we convert it legally to a numeric?  (BUG RISK!)
        dval = str2double(val);
        if ~isnan(dval); val = dval; end
        C = setfield(C,tok,val);
      end
    end
  end  
end

%%%%%%%%%%%%%%%%%%%%%%%%%
function y = iswhitesp(x)
% Return boolean mask of whether characters in a string are whitespace
y = (x == ' ') | (x == char(9)) | (x == char(10)) | (x == char(13));

%%%%%%%%%%%%%%%%%%%%%%%%%
function y = isalphanum(x)
% Return boolean mask of whether characters in a string are [A-z0-9_]
y = (x >= 'A' & x <= 'Z') | (x >= 'a' & x <= 'z') ...
    | (x >= '0' & x <= '9') | (x == '_');

%%%%%%%%%%%%%%%%%%%%%%%%%
function y = trimws(x)
% Trim whitespace from start and end of a string

isws = iswhitesp(x);

firstnonws = min(find(isws==0));
lastnonws = max(find(isws==0));

y = x(firstnonws:lastnonws);


%%%%%%%%%%%%%%%%%%%%%%%%%
function [f,r] = firsttok(l)
% Break a line into a first token and a remainder

isws = iswhitesp(l);

firstws = min([find(isws),length(l)+1]);
f = l(1:firstws-1);
r = trimws(l(firstws:end));


%%%%%%%%%%%%%%%%%%%%%%%%%
function y = substvars(x,D,line)
% Replace any $name constructs in x with bindings from
% containers.Map D.  line is passed in just for error reporting

% divide string x on dollar signs
dollarsigns = find(x == '$');
pos = 1;
y = '';
for i = 1:length(dollarsigns)
  dspos = dollarsigns(i);
  % copy up to the dollar sign
  y = [y, x(pos:(dspos-1))];
  % find the variable name
  if x(dspos+1) == '{'
    restpos = dspos + min(find(x((dspos+1):end)=='}')) + 1;
    varname = x((dspos+2):(restpos-2));
  else 
    restpos = dspos+min(find([isalphanum(x((dspos+1):end))==0,1]));
    varname = x((dspos+1):(restpos-1));
  end
  if isKey(D,varname) == 0
    error(['No binding for $',varname,' in ',line]);
  end
  % copy the variable name
  y = [y,D(varname)];
  pos = restpos;
end
% copy anything beyond the end
y = [y,x(pos:end)];
