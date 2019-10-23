function ac = cal_ac(x,sr,mapping,fbank,twin,thop,n_s,VERBOSE)
% ac = cal_ac(x,sr,mapping,fbank,n_s,VERBOSE)
%
% Calculate normalized subband autocorrelation. If 'mapping' exists, do
% post-processing using k-dim PCA dimensionality reduction.
%
% INPUT:
%         x - the input signal
%         sr - the sampling rate
%         mapping - (nchs x 1) cell containing subband PCAs (maxlags x kdim)
%         fbank - structure definining the filterbank with fields
%                 fbank.a, fbank.b, fbank.delay
%         n_s - the number of seconds to process in each step
%
% OUTPUT:
%         ac - normalized subband autocorrelation
%                  (nchs X maxlags X nfrms)
%              if 'mapping' exists, do k-dim PCA dimensionality reduction
%                  (nchs X kdim X nfrms)
%         x - the input signal (one channel)
%         acf - subband autocorrelation (not used for longer audio)
%         acf_engy - energy of subband autocorrelation (not used for longer audio)
%
% [2012-04-11] Byung Suk Lee bsl@ee.columbia.edu

%disp(['len x=',num2str(length(x)),' twin=',num2str(twin),' n_s=',num2str(n_s)]);

if nargin < 3; mapping = []; end
if nargin < 4; fbank = []; end
if nargin < 5; twin = 0.025; end
if nargin < 6; thop = 0.010; end
if nargin < 7; n_s = 5; end
if nargin < 8; VERBOSE = 0; end

% Stabilize the random number generator at the start of each
% utterance (for dither())
versiondate = [10000 100 1 0 0 0]*datevec(version('-date'))';
if versiondate > 20120100
  rng('default'); % R2012a
else
  reset(RandStream.getDefaultStream); % R2010b
end

flag_mapping =  ~isempty(mapping);
if flag_mapping
  nchs = size(mapping,1); 
  maxlags = size(mapping{1},1); 
  kdim = size(mapping{1},2);
else
  nchs = size(fbank.b,1);
  maxlags = sr*twin;
  kdim = maxlags;
end

if isempty(fbank)
  % Design Lyon-Slaney filters
  fmin = 100;
  bpo = 16;
  q = 8;
  order = 2;
  ftype = 2;
  [fbank.b,fbank.a,fbank.delay,w2,cf] = bpfiltbank(sr,fmin,bpo,nchs,q,order,ftype);  % type 2 is LySla
end

% Use only mono channel
if size(x,2) > 1, x = x(:,1); end;

%%
nfrms = 1 + max(floor((size(x,1) - twin*sr)/(thop*sr)),0);

%% Dithering
x = dithering(x);
xlen = length(x);
fps = 1/thop;

%% calculate sbpca features for the audio at least the length of the analysis window, 25 ms
if VERBOSE
  disp(['Autocorrelogram (maxlags:',num2str(maxlags),', nchs:', ...
        num2str(nchs),', kdim:',num2str(kdim),')'])
end

if xlen >= twin*sr

    buf_len = round(0.1*sr); % buffer length of front and end of slice
    nslice = max(ceil(length(x) / (n_s * sr))-1, 1);
    ac = zeros(nfrms,nchs*kdim);
    %% feature calculation on slices of length n_s sec
    for islice = 1:nslice
        ids = n_s*sr*(islice-1) - buf_len * (islice > 1) + 1; % front buffer, except the first slice
    %     ide = min( n_s*sr*islice + buf_len, xlen); % end buffer, always
        tide = min( n_s*sr*islice + buf_len, xlen);
        if islice == nslice
            ide = xlen;
        else
            ide = tide; % end buffer, always
        end
        if VERBOSE
          disp(['(',num2str(islice),'/',num2str(nslice),') Start: ', ...
                num2str(ids),' End: ',num2str(ide)]);
        end
        xx = x(ids:ide);
        [tmpac] = sub_cal_ac(xx, sr, fbank.b, fbank.a, fbank.delay, ...
                             twin, thop, mapping);

        % cut frount and end buffer results
        tmpac = tmpac(:,:,(1+10*(islice > 1)):(end-8*(islice < nslice)));
        if islice == nslice
            lac = nfrms - fps*n_s * (nslice - 1);
        else
            lac = size(tmpac,3);
        end
        if VERBOSE
          disp(['islice: ',num2str(islice),' len_tmpac: ',num2str(size(tmpac,3)),' lac: ',num2str(lac)]);
        end
        tmpac = reshape(tmpac,[nchs*kdim lac]);
        ac((1:lac) + n_s*fps*(islice - 1),:) = tmpac';
    end


else
    err_txt = 'Not calculating features: ';
    err_msg = 'Input audio is shorter than the analysis window.';
    disp([err_txt,err_msg]);
    disp(['Zero features of ',num2str(nfrms),' frames are saved.']);
    ac = zeros(nfrms,nchs*kdim);
end


function [ac, x, acf, acf_engy] = sub_cal_ac(x,sr,b2,a2,t2,twin,thop,mapping)
% function [ac, x, acf, acf_engy] = sub_cal_ac(x,sr,b2,a2,t2,twin,thop,mapping)
%
% Calculate normalized subband autocorrelation. If 'mapping' exists, do
% post-processing using k-dim PCA dimensionality reduction.
%
% INPUT:
%         x - The input signal
%         sr - The sampling rate
%         b2 - B coefficients to IIR filterbank
%         a2 - A coefficients to IIR filterbank
%         t2 - Delay coefficients to IIR filterbank
%         mapping - (nchs x 1) cell containing subband PCA mapping (maxlags x kdim)
%
% OUTPUT:
%         ac - normalized subband autocorrelation
%                  (nchs X maxlags X nfrms)
%              if 'mapping' exists, do k-dim PCA dimensionality reduction
%                  (nchs X kdim X nfrms)
%              nfrms = 1 + max(floor((size(x,1) - twin*sr)/(thop*sr)),0)
%         x - the input signal (one channel)
%         acf - subband autocorrelation (not used for longer audio)
%         acf_engy - energy of subband autocorrelation (not used for longer audio)
%

if nargin < 8; mapping = []; end

flag_mapping =  ~isempty(mapping);

if flag_mapping, maxlags = size(mapping{1},1); else maxlags = sr*twin; end;
if flag_mapping, kdim = size(mapping{1},2); else kdim = maxlags; end;
nchs = length(t2);

margin = floor(0.04*sr);
nfrms = 1 + max(floor((size(x,1) - twin*sr)/(thop*sr)),0);

if size(x,1) < twin*sr
    
    acf = zeros(nchs,maxlags,1);
    acf_engy = ones(nchs,maxlags,1);

else
    x = [x;zeros(margin,1)];

    % cochlear filtering
    x = x(:)';
    e = filterbank(b2,a2,x,1,0,t2);

    [c1, s1, lags] = autocorrelogram(e, sr, maxlags, thop, twin); % multichannel autocorrelation

    acf = c1(:,:,1:nfrms);
    acf_engy = s1(:,:,1:nfrms);
end

ac = acf ./ (acf_engy + (acf_engy == 0));

if flag_mapping
    kac = zeros(nchs,kdim,nfrms);
    for c = 1:nchs
        tmpac = shiftdim(ac(c,:,:),1);
        %% To ignore frames that contain NaN elements
        sumtmpac = sum(tmpac);
        tmpac(:,isnan(sumtmpac)) = 0;
        kac(c,:,:) = mapping{c}' * tmpac;
    end
    ac = kac;
end

