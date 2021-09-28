function [S] = voxitAnalysis(filein,overwrite)
% Analyze vocal parameters using a Voxit  file
% INPUTS
%    filein:  Voxit (based on WORLD) object mat file
%    overwrite: overwrite existing Voxit object file with additional field for analysis results (Default: 0)
%
% OUTPUTS
%   S:      Voxit (based on WORLD) object structure with additional analysis field
%
%
% copyright Lee M. Miller, latest mods 10/2019

if ~exist('overwrite','var')
    overwrite = 0;
end

[pathstr,fileinname,ext] = fileparts(filein);
load(filein)
if ~exist('S','var')
    S=WORLDobject; clear WORLDobject;
end
if isfield(S,'analysis')
    disp('overwriting previous analysis field');
    S=rmfield(S,'analysis');
end
S.analysis.README = {['voxitAnalysis.m ' date]};

% DEFINE ANALYSIS PARAMETERS
fs = S.samplingFrequency;
fsSAcC = 200; %SAcC output is 5ms period or 200Hz
ts = S.f0_parameter.temporal_positions(2)-S.f0_parameter.temporal_positions(1);
vuv = S.SAcC.vuv;
fileseconds = S.f0_parameter.temporal_positions(end);

dminvoice = .100; % miminum voiced duration, in sec
dminpause = .100; %minimum pause duration (so we don't count stops esp initial voiceless ones)
dmaxpause = 3.000; %maximum pause duration (to avoid long periods, e.g. before a poem)
pausethresh = 10;  % thresh to detemin4e pause, e.g. 10dB down from the 90% intensity percentile.
                   % notice this will be overridden by SAcC voicing decision: even low power will be speech if it's voiced
S.analysis.dminvoice = dminvoice;
S.analysis.dminpause = dminpause;
S.analysis.dmaxpause = dmaxpause;
S.analysis.pausethresh = pausethresh;

%% PITCH STATS
% Find contiguous SAcC voiced periods longer than a certain duration, see http://www.mathworks.com/matlabcentral/fileexchange/5658-contiguous-start-and-stop-indices-for-contiguous-runs
% Careful not to measure time-dependent values (velocity or accel) across voiced boudaries!

ivuv = find(vuv>0); %only work with voiced portions
vdurthresh = round(dminvoice/ts); 
ixtmp = contiguous(vuv,1); % find start and end indices
ixallvoicebounds = ixtmp{2};
ixdiff = ixallvoicebounds(:,2)-ixallvoicebounds(:,1);
ixvoicedbounds = ixallvoicebounds(find(ixdiff>vdurthresh),:); % start and end indices for voicing > vdurthresh in duration

f0log = log2(S.SAcC.f0);
f0mean = 2.^(mean(f0log(ivuv))); % log, as opposed to the linear % f0mean = mean(f0_original(ivuv));
diffoctf0 = log2(S.SAcC.f0)-log2(f0mean);
f0hist = histcounts(diffoctf0,25,'BinLimits',[-1 +1]); % 1/12 octave bins
f0prob = f0hist./sum(f0hist);
f0log2prob = log2(f0prob);
f0log2prob(find(f0prob == 0)) = 0;
f0entropy = -sum(f0prob.*f0log2prob);

f0velocity = [];
f0accel = [];
for i = 1:size(ixvoicedbounds,1)  %the loop makes sure we're not calculating across segments
    diffocttmp = diffoctf0(ixvoicedbounds(i,1):ixvoicedbounds(i,2));
    diffocttmp = sgolayfilt(diffocttmp,2,7); %smooth f0 to avoid step artifacts, esp in acceleration: span = 7, degree = 2 as per Drift3
                                        
    f0velocity = [f0velocity; diff(diffocttmp)/ts]; %norm by sampling period, so in octaves per sec
    f0accel = [f0accel; diff(diff(diffocttmp))/ts]; %in octaves per sec per sec
    
    %     smoothvel = smooth(diff(diffocttmp),'sgolay');
    %     f0velocity = [f0velocity; smoothvel/ts]; %norm by sampling period, so in octaves per sec
    %     f0accel = [f0accel; diff(smoothvel)/ts]; %in octaves per sec per sec
end

% %% Extract examples of voiced periods for high and low velocity and accel, from among the longer voiced periods
% egnum = min(5,round(size(ixvoicedbounds,1)/2)); %number of examples to collect
% egmindur = 0.300; %minimum duration for example voiced periods, in sec
% eggap = 1.000; % time gap to insert between examples (in sec) 
% segtaper = round(0.020.*fs); %taper for windowing audio segments
% 
% ixvoicedboundsLong = ixvoicedbounds(find(ixvoicedbounds(:,2)-ixvoicedbounds(:,1) > egmindur.*fsSAcC) ,:);
% for j = 1:size(ixvoicedboundsLong,1)  %the loop makes sure we're not calculating across segments
%     diffocttmp = diffoctf0(ixvoicedboundsLong(j,1):ixvoicedboundsLong(j,2));
%     
%     f0velocitySegMeanAbs(j) = mean(abs(diff(diffocttmp)/ts));
%     f0accelSegMeanAbs(j) = mean(abs(diff(diff(diffocttmp))/ts));
%     
% end
% ixvoicedboundsLongAudio = ixvoicedboundsLong.*(fs./fsSAcC); %identify voiced boundaries in audio sample rather than vocal analysis sample
% 
% velSorted = sort(f0velocitySegMeanAbs);
% ixVelLow = find(f0velocitySegMeanAbs<=velSorted(egnum));
% ixVelHigh= find(f0velocitySegMeanAbs>=velSorted(length(f0velocitySegMeanAbs)-egnum+1));
% 
% accelSorted = sort(f0accelSegMeanAbs);
% ixAccelLow = find(f0accelSegMeanAbs<=accelSorted(egnum));
% ixAccelHigh = find(f0accelSegMeanAbs>=accelSorted(length(f0accelSegMeanAbs)-egnum+1));
% 
% VelHighExamples = [];
% for z=1:length(ixVelHigh)
%     segTmp = S.waveform(round(ixvoicedboundsLongAudio(ixVelHigh(z),1)):round(ixvoicedboundsLongAudio(ixVelHigh(z),2)));
%     segWindow = [linspace(0,1,segtaper)'; ones(length(segTmp)-2*segtaper,1); linspace(1,0,segtaper)']; % linear taper ends to minimize transients
%     segTapered = segTmp.*segWindow;
%     VelHighExamples = [VelHighExamples; segTapered; zeros(round(eggap.*fs),1); segTapered; zeros(round(eggap.*fs),1); zeros(round(eggap.*fs),1)];
% end
% %sound(VelHighExamples,fs);
% audiowrite('Examples_MeanAbsVelocity_HIGH.wav',VelHighExamples,fs);
% 
% VelLowExamples = [];
% for z=1:length(ixVelLow)
%     segTmp = S.waveform(round(ixvoicedboundsLongAudio(ixVelLow(z),1)):round(ixvoicedboundsLongAudio(ixVelLow(z),2)));
%     segWindow = [linspace(0,1,segtaper)'; ones(length(segTmp)-2*segtaper,1); linspace(1,0,segtaper)']; % linear taper ends to minimize transients
%     segTapered = segTmp.*segWindow;
%     VelLowExamples = [VelLowExamples; segTapered; zeros(round(eggap.*fs),1); segTapered; zeros(round(eggap.*fs),1); zeros(round(eggap.*fs),1)];
% end
% %sound(VelLowExamples,fs);
% audiowrite('Examples_MeanAbsVelocity_LOW.wav',VelLowExamples,fs);
% 
% AccelHighExamples = [];
% for z=1:length(ixAccelHigh)
%     segTmp = S.waveform(round(ixvoicedboundsLongAudio(ixAccelHigh(z),1)):round(ixvoicedboundsLongAudio(ixAccelHigh(z),2)));
%     segWindow = [linspace(0,1,segtaper)'; ones(length(segTmp)-2*segtaper,1); linspace(1,0,segtaper)']; % linear taper ends to minimize transients
%     segTapered = segTmp.*segWindow;
%     AccelHighExamples = [AccelHighExamples; segTapered; zeros(round(eggap.*fs),1); segTapered; zeros(round(eggap.*fs),1); zeros(round(eggap.*fs),1)];
% end
% %sound(AccelHighExamples,fs);
% audiowrite('Examples_MeanAbsAccel_HIGH.wav',AccelHighExamples,fs);
% 
% AccelLowExamples = [];
% for z=1:length(ixAccelLow)
%     segTmp = S.waveform(round(ixvoicedboundsLongAudio(ixAccelLow(z),1)):round(ixvoicedboundsLongAudio(ixAccelLow(z),2)));
%     segWindow = [linspace(0,1,segtaper)'; ones(length(segTmp)-2*segtaper,1); linspace(1,0,segtaper)']; % linear taper ends to minimize transients
%     segTapered = segTmp.*segWindow;
%     AccelLowExamples = [AccelLowExamples; segTapered; zeros(round(eggap.*fs),1); segTapered; zeros(round(eggap.*fs),1); zeros(round(eggap.*fs),1)];
% end
% %sound(AccelHighExamples,fs);
% audiowrite('Examples_MeanAbsAccel_LOW.wav',AccelLowExamples,fs);

%%

S.analysis.t = S.f0_parameter.temporal_positions;
S.analysis.f0 = S.SAcC.f0;
S.analysis.f0Mean = f0mean;
S.analysis.f0Range = max(diffoctf0(ivuv))-min(diffoctf0(ivuv));
S.analysis.f0Range95percent = quantile(diffoctf0(ivuv),.975) - quantile(diffoctf0(ivuv),.025); % 95% of values in this range; appx 2 standard deviations for normal distribution
S.analysis.f0Kurtosis = kurtosis(diffoctf0(ivuv))-3; %-3 so zero is a normal distribution
S.analysis.f0Entropy = f0entropy;
%figure, hist(diffoctf0(ivuv),40);title([' kurtosis ' num2str(S.analysis.f0kurtosis)]);
S.analysis.f0Velocity = f0velocity;
S.analysis.f0MeanVelocity = mean(f0velocity);
S.analysis.f0MeanAbsVelocity = mean(abs(f0velocity));
S.analysis.f0SignMeanVelocity = sign(mean(f0velocity));
S.analysis.f0StdVelocity = std(f0velocity);
S.analysis.f0SkewnessVelocity = skewness(f0velocity);
S.analysis.f0Accel = f0accel;
S.analysis.f0MeanAccel = mean(f0accel);
S.analysis.f0MeanAbsAccel = mean(abs(f0accel));
S.analysis.f0SignMeanAccel =  sign(mean(f0accel));
S.analysis.f0StdAccel = std(f0accel);

%% PITCH STATS BASED ON DRIFT, if available (for comparison with the python port)
% Find contiguous Drift voiced periods longer than a certain duration, see http://www.mathworks.com/matlabcentral/fileexchange/5658-contiguous-start-and-stop-indices-for-contiguous-runs
% Careful not to measure time-dependent values (velocity or accel) across voiced boudaries!
% remove all integer values to ignore line noise (60Hz or 50Hz and their harmonics) or other artifacts    
if isfield(S,'drift')  % keep in mind the drift data is probably 10ms sampling period, not 5ms
    tsD = S.drift.tdrift(2)-S.drift.tdrift(1);
    fsD = 1/tsD;
    vuvD = S.drift.vuvdrift; 
    
    ivuvD = find(vuvD>0); %only work with voiced portions
    vdurthreshD = round(dminvoice/tsD); 
    ixtmpD = contiguous(vuvD,1); % find start and end indices
    ixallvoiceboundsD = ixtmpD{2};
    ixdiffD = ixallvoiceboundsD(:,2)-ixallvoiceboundsD(:,1);
    ixvoicedboundsD = ixallvoiceboundsD(find(ixdiffD>vdurthreshD),:); % start and end indices for voicing > vdurthresh in duration

    f0logD = log2(S.drift.f0drift);
    f0meanD = 2.^(mean(f0logD(ivuvD))); % log, as opposed to the linear % f0mean = mean(f0_original(ivuv));
    diffoctf0D = log2(S.drift.f0drift)-log2(f0meanD);
    f0histD = histcounts(diffoctf0D,25,'BinLimits',[-1 +1]); % 1/12 octave bins
    f0probD = f0histD./sum(f0histD);
    f0log2probD = log2(f0probD);
    f0log2probD(find(f0probD == 0)) = 0;
    f0entropyD = -sum(f0probD.*f0log2probD);

    f0velocityD = [];
    f0accelD = [];
    for i = 1:size(ixvoicedboundsD,1)  %the loop makes sure we're not calculating across segments
        diffocttmpD = diffoctf0D(ixvoicedboundsD(i,1):ixvoicedboundsD(i,2));
        diffocttmpD = sgolayfilt(diffocttmpD,2,7); %smooth f0 to avoid step artifacts, esp in acceleration: span = 7, degree = 2 as per Drift3
        f0velocityD = [f0velocityD; diff(diffocttmpD)/tsD]; %norm by sampling period, so in octaves per sec
        f0accelD = [f0accelD; diff(diff(diffocttmpD))/tsD]; %in octaves per sec per sec
    end
    
    S.analysis.Driftt = S.drift.tdrift;
    S.analysis.Driftf0 = S.drift.f0drift;
    S.analysis.Driftf0Mean = f0meanD;
    S.analysis.Driftf0Range = max(diffoctf0D(ivuvD))-min(diffoctf0D(ivuvD));
    S.analysis.Driftf0Range95percent = quantile(diffoctf0D(ivuvD),.975) - quantile(diffoctf0D(ivuvD),.025); %range of 2 standard deviations, so appx 95% of values in this range
    S.analysis.Driftf0Kurtosis = kurtosis(diffoctf0D(ivuvD))-3; %-3 so zero is a normal distribution
    S.analysis.Driftf0Entropy = f0entropyD;
    %figure, hist(diffoctf0(ivuv),40);title([' kurtosis ' num2str(S.analysis.f0kurtosis)]);
    S.analysis.Driftf0Velocity = f0velocityD;
    S.analysis.Driftf0MeanVelocity = mean(f0velocityD);
    S.analysis.Driftf0MeanAbsVelocity = mean(abs(f0velocityD));
    S.analysis.Driftf0SignMeanVelocity =  sign(mean(f0velocityD));
    S.analysis.Driftf0StdVelocity = std(f0velocityD);
    S.analysis.Driftf0SkewnessVelocity = skewness(f0velocityD);
    S.analysis.Driftf0Accel = f0accelD;
    S.analysis.Driftf0MeanAccel = mean(f0accelD);
    S.analysis.Driftf0MeanAbsAccel = mean(abs(f0accelD));
    S.analysis.Driftf0SignMeanAccel =  sign(mean(f0accelD));
    S.analysis.Driftf0StdAccel = std(f0accelD);

end

%% PAUSE STATS BASED ON ACOUSTICS (INTENSITY)
% Presently calculating linPower in audio2object function so we don't have to save the whole spectrogram (too much memory load)
% spectrogramScaled = S.spectrum_parameter.spectrogram./max(max(S.spectrum_parameter.spectrogram)); % scale to equalize across recordings
% linPower = sum(spectrogramScaled)';
linPower = S.spectrum_parameter.linPower;
logPower = 10*log10(linPower);

pausetmp = zeros(length(S.f0_parameter.temporal_positions),1);
ipause = find(logPower<(max(quantile(logPower,.9))-pausethresh));
pausetmp(ipause) = 1;
pausetmp = pausetmp.*(-(vuv-1)); %forbid any pauses during voicing

% First find indices for pauses, ignoring any that go to endpoints
ixptmp = contiguous(pausetmp,1); % find start and end indices for all pauses
ixallpausebounds = ixptmp{2};
ixonset = 1;
ixoffset = length(logPower);
if ixallpausebounds(1,1)==1
    ixonset = ixallpausebounds(1,2);
    ixallpausebounds = ixallpausebounds(2:end,:);
end
if ixallpausebounds(end,2)==length(logPower)
    ixoffset = ixallpausebounds(end,1);
    ixallpausebounds = ixallpausebounds(1:end-1,:);
end
ixpdiff = ixallpausebounds(:,2)-ixallpausebounds(:,1)+1;
ixpausebounds = ixallpausebounds(intersect(find(ixpdiff>=(dminpause/ts)),find(ixpdiff<=(dmaxpause/ts))),:); % ignore those too short. not really pauses at all, or those too long
pausedurs = ((ixpausebounds(:,2)-ixpausebounds(:,1))+1).*ts;

S.analysis.pausebounds = ixpausebounds;
S.analysis.PauseDurations = pausedurs;
S.analysis.PauseCount = length(pausedurs);
S.analysis.PauseRate = length(pausedurs)/fileseconds;
S.analysis.PauseDutyCycle = sum(pausedurs)/fileseconds;
S.analysis.MeanPauseDuration = mean(pausedurs);
S.analysis.PauseCount100 = length(find(pausedurs>=0.100));
S.analysis.PauseRate100 = length(find(pausedurs>=0.100))/fileseconds;
S.analysis.PauseMean100 = mean(pausedurs(find(pausedurs>=0.100)));
S.analysis.PauseCount250 = length(find(pausedurs>=0.250));
S.analysis.PauseRate250 = length(find(pausedurs>=0.250))/fileseconds;
S.analysis.PauseMean250 = mean(pausedurs(find(pausedurs>=0.250)));
S.analysis.PauseCount500 = length(find(pausedurs>=0.500));
S.analysis.PauseRate500 = length(find(pausedurs>=0.500))/fileseconds;
S.analysis.PauseMean500 = mean(pausedurs(find(pausedurs>=0.500)));
S.analysis.PauseCount1000 = length(find(pausedurs>=1.00));
S.analysis.PauseRate1000 = length(find(pausedurs>=1.00))/fileseconds;
S.analysis.PauseMean1000 = mean(pausedurs(find(pausedurs>=1.00)));
S.analysis.PauseCount2000 = length(find(pausedurs>=2.00));
S.analysis.PauseRate2000 = length(find(pausedurs>=2.00))/fileseconds;
S.analysis.PauseMean2000 = mean(pausedurs(find(pausedurs>=2.00)));
S.analysis.LongSilenceCount = length(find(ixpdiff>dmaxpause));



%% PAUSE STATS BASED ON GENTLE ALIGNMENT
if isfield(S,'gentle')    
    S.analysis.wpm = size(S.gentle.Gtxt,1)./S.gentle.Gtimes(end,end).*60; % words per minute, assuming all rows of the csv are words (whether succesfully aligned or not)
    Gdiff = S.gentle.Gtimes(2:end,1)-S.gentle.Gtimes(1:end-1,2);
    ixGpauses = intersect(find(Gdiff>=dminpause),find(Gdiff<=dmaxpause));
    Gpausedurs = Gdiff(ixGpauses);
    Gsps = ones(S.gentle.Gtimes(end,end).*S.gentle.fsG,1); % initialize speech-pause-speech array
    for i=1:size(ixGpauses) % set array to zero during all pauses
        Gsps(round(S.gentle.Gtimes(ixGpauses(i),2).*S.gentle.fsG)+1 : round(S.gentle.Gtimes(ixGpauses(i)+1,1).*S.gentle.fsG)-1) = 0;
    end
    ixWord1 = S.gentle.Gnum(1,1)*S.gentle.fsG +1;
    GspsCrop = Gsps(ixWord1:end);  % crop off beginning silence; start at first word onset
    
    S.analysis.Gentlesps = Gsps;
    S.analysis.GentlespsCrop = GspsCrop;
    S.analysis.GentlePauseDurations = Gpausedurs;
    S.analysis.GentlePauseCount = length(Gpausedurs);
    S.analysis.GentlePauseRate = length(Gpausedurs)/S.gentle.Gtimes(end,end);
    S.analysis.GentlePauseDutyCycle = sum(Gpausedurs)/S.gentle.Gtimes(end,end);
    S.analysis.GentleMeanPauseDuration = mean(Gpausedurs);
    
    S.analysis.GentlePauseCount100 = length(find(Gpausedurs>=0.100));
    S.analysis.GentlePauseRate100 = length(find(Gpausedurs>=0.100))/S.gentle.Gtimes(end,end);
    S.analysis.GentlePauseMean100 = mean(Gpausedurs(find(Gpausedurs>=0.100)));
    S.analysis.GentlePauseCount250 = length(find(Gpausedurs>=0.250));
    S.analysis.GentlePauseRate250 = length(find(Gpausedurs>=0.250))/S.gentle.Gtimes(end,end);
    S.analysis.GentlePauseMean250 = mean(Gpausedurs(find(Gpausedurs>=0.250)));
    S.analysis.GentlePauseCount500 = length(find(Gpausedurs>=0.500));
    S.analysis.GentlePauseRate500 = length(find(Gpausedurs>=0.500))/S.gentle.Gtimes(end,end);
    S.analysis.GentlePauseMean500 = mean(Gpausedurs(find(Gpausedurs>=0.500)));
    S.analysis.GentlePauseCount1000 = length(find(Gpausedurs>=1.00));
    S.analysis.GentlePauseRate1000 = length(find(Gpausedurs>=1.00))/S.gentle.Gtimes(end,end);
    S.analysis.GentlePauseMean1000 = mean(Gpausedurs(find(Gpausedurs>=1.00)));
    S.analysis.GentlePauseCount2000 = length(find(Gpausedurs>=2.00));
    S.analysis.GentlePauseRate2000 = length(find(Gpausedurs>=2.00))/S.gentle.Gtimes(end,end);
    S.analysis.GentlePauseMean2000 = mean(Gpausedurs(find(Gpausedurs>=2.00)));
    S.analysis.GentleLongSilenceCount = length(find(Gdiff>dmaxpause));
    %S.analysis.GcomplexityAllPauses = 100.*calc_lz_complexity(Gsps, 'exhaustive', 1);
    S.analysis.GentleComplexityAllPauses = 100.*calc_lz_complexity(GspsCrop, 'exhaustive', 1);
end


%% INTENSITY STATS
% %Infer indices for all speech (not just voicing) as the opposite of pauses, acoustically defined, but again careful not to count the ends as pauses
ixspeechbounds = zeros(size(ixpausebounds,1)+1,2);
ixspeechbounds(1,1)     = ixonset;
ixspeechbounds(1:end-1,2)=ixpausebounds(:,1)-1;
ixspeechbounds(2:end,1) = ixpausebounds(:,2)+1;
ixspeechbounds(end,end) = ixoffset;
ispeech = []; %get all speech indices, not just the boundaries
for k = 1:size(ixspeechbounds,1)
     ispeech = [ispeech ixspeechbounds(k,1):ixspeechbounds(k,2)];
end
sps = zeros(length(logPower),1); %speech pause speech, analogous to vuv
sps(ispeech) = 1;

% %Use speech-nonspeech to calculate intensity stats: however with noisy recordings, this is very tricky. Instead, probably best to use voiced periods only.% 
% Imean = 10.^(mean(logPower(ispeech)/10));  %only calc mean when speech, not pause
% difflogI = 10*log10(linPower/Imean);
% 
% Ivelocity = [];
% Iaccel = [];
% for i = 1:size(ixspeechbounds,1)  %the loop makes sure we're not calculating velocity etc across segments
%     diffocttmp = difflogI(ixspeechbounds(i,1):ixspeechbounds(i,2));
%     Ivelocity = [Ivelocity; diff(diffocttmp)/ts]; %norm by sampling period, so in octaves per sec
%     Iaccel = [Iaccel; diff(diff(diffocttmp))/ts]; %in octaves per sec per sec
% end

% Use only voiced periods to calculate intensity stats, as it should be less prone to bias in noisy recordings 
Imean = 10.^(mean(logPower(ivuv)/10));  %only calc power when voiced
difflogI = 10*log10(linPower/Imean);
Ivelocity = [];
IsegmentMeans = [];
Iaccel = [];
for i = 1:size(ixvoicedbounds,1)  %the loop makes sure we're not calculating velocity etc across segments
    difflogItmp = difflogI(ixvoicedbounds(i,1):ixvoicedbounds(i,2));    
    IsegmentMeans = [IsegmentMeans; mean(difflogItmp)];
    Ivelocity = [Ivelocity; diff(difflogItmp)/ts]; %norm by sampling period, so in log power per sec
    Iaccel = [Iaccel; diff(diff(difflogItmp))/ts]; %in log power per sec per sec
end

S.analysis.Intensity = logPower;
S.analysis.IntensityMean = Imean;
S.analysis.IsegmentMeans = IsegmentMeans;
S.analysis.IntensitySegmentRange95percent = quantile(IsegmentMeans,.975) - quantile(IsegmentMeans,.025); % 95% of values in this range; appx 2 standard deviations for normal distribution
S.analysis.IntensityVelocity = Ivelocity;
S.analysis.IntensityMeanVelocity = mean(Ivelocity);
S.analysis.IntensityMeanAbsVelocity = mean(abs(Ivelocity));
S.analysis.IntensitySignMeanVelocity = sign(mean(Ivelocity));
S.analysis.IntensityStdVelocity = std(Ivelocity);
S.analysis.IntensityAccel = Iaccel;
S.analysis.IntensityMeanAccel = mean(Iaccel);
S.analysis.IntensityMeanAbsAccel = mean(abs(Iaccel));
S.analysis.IntensitySignMeanAccel = sign(mean(Iaccel));
S.analysis.IntensityStdAccel = std(Iaccel);
S.analysis.ComplexityAllPauses = 100.*calc_lz_complexity(sps, 'exhaustive', 1); %note, complexity may depend on sampling period!

%warning('Complexity is calculated with sampling period 5ms. Decimate to 10ms when comparing to Drift')

% Calculate complexity using voiced-unvoiced, not speech-pause, because voicing has more importance for rhythm
SylMax = 0.400; %cutoff in sec for syllable length vs phrase length
ixSylBounds = ixallvoicebounds(find(ixdiff<SylMax/ts),:);
for ii = 1:size(ixSylBounds,1)-1 %shift all indices so no unvoiced periods are longer than the syllable length cutoff (else they influence complexity)  
    if ixSylBounds(ii+1,1)-ixSylBounds(ii,2) > SylMax/ts
        shiftup = ixSylBounds(ii+1,1)-ixSylBounds(ii,2) - round(SylMax/ts);
        ixSylBounds(ii+1:end,:) = ixSylBounds(ii+1:end,:) - shiftup;
    end
end
iSyl = []; %get all indices, not just the boundaries
for jj = 1:size(ixSylBounds,1)
    iSyl = [iSyl ixSylBounds(jj,1):ixSylBounds(jj,2)];
end
vuvSyl = zeros(length(max(iSyl)),1); 
vuvSyl(iSyl) = 1; 
try   % this catch is for the occasional recording that has only acoustically indistinct syllables
    S.analysis.ComplexitySyllables = 100.*calc_lz_complexity(vuvSyl, 'exhaustive', 1);
catch
    S.analysis.ComplexitySyllables = NaN;
end

ixPhraseBoundsTmp = ixallvoicebounds;
ixPhraseBounds = [];
iPhrase = []; %get all indices, not just the boundaries
for kk = 1:size(ixPhraseBoundsTmp,1)-1 %delete indices so short unvoiced periods are removed to make longer contiguous phrases
    if ixPhraseBoundsTmp(kk+1,1)-ixPhraseBoundsTmp(kk,2) < SylMax/ts
        ixPhraseBounds(end+1,:) = [ixPhraseBoundsTmp(kk,1) ixPhraseBoundsTmp(kk+1,2)];
    else
        ixPhraseBounds(end+1,:) = [ixPhraseBoundsTmp(kk,1) ixPhraseBoundsTmp(kk,2)];
    end
end
ixPhraseBounds(end+1,:) = [ixPhraseBoundsTmp(kk+1,1) ixPhraseBoundsTmp(kk+1,2)];
for ll = 1:size(ixPhraseBounds,1)
     iPhrase = [iPhrase ixPhraseBounds(ll,1):ixPhraseBounds(ll,2)];
end
vuvPhrase = zeros(length(vuv),1); 
vuvPhrase(iPhrase) = 1; 
S.analysis.ComplexityPhrases = 100.*calc_lz_complexity(vuvPhrase, 'exhaustive', 1); %note, complexity may depend on sampling period!


%% CORRELATIONS
%PITCH AND INTENSITY
% note that pitch is not defined at all speaking times, so we use vuv to
% index, or only the higher power where the pitch is well estimated
% rather than sps!
logPowervuv = logPower(find(vuv));
f0logvuv = f0log(find(vuv));
ixhighpow = find(logPowervuv>quantile(logPowervuv,.50)); %don't use the quiet moments, as the pitch estimation can crap out, octave jumps etc
logPowhighI = logPowervuv(ixhighpow);
f0loghighI = f0logvuv(ixhighpow);
[corrf0I corrf0Ipval]= corr([logPowhighI f0loghighI]);
S.analysis.Corrf0Intensity = corrf0I(1,2); % correlation between pitch and intensity
S.analysis.Corrf0IntensityPvalue = corrf0Ipval(1,2);

% figure, hold on, 
% scatter(logPowhighI,f0loghighI);
% xlabel('logPower'); 
% ylabel('f0log'); 
% title('Correlation between intensity and pitch');
% 
% bestfit = polyfit(logPowhighI,f0loghighI,1);
% y = bestfit(1)*logPowhighI + bestfit(2);
% plot(logPowhighI,y,'k');


%%  COMPOSITE METRICS
a=S.analysis;
%S.analysis.dynamism = (abs(a.f0speed) * a.f0entropy) + (a.complexitySyllables+a.complexityPhrases)/2*0.439; % 43.9 brings it into same range as first term, used for the final 100poets analysis.  1/2*0.439 = 0.2195
S.analysis.Dynamism = (abs(a.f0MeanAbsVelocity) * a.f0Entropy) + (a.ComplexitySyllables+a.ComplexityPhrases)/2*0.439; % updated variable names from original formula, still, 43.9 brings it into same range as first term, used for the final 100poets analysis.  1/2*0.439 = 0.2195
%S.analysis.Dynamism = abs(a.f0MeanAbsVelocity)/1.092050992 + a.f0Entropy/3.331034878 + (a.ComplexitySyllables/13.18735087+a.ComplexityPhrases/3.022951534)/2; % bring terms into same range ~1
%S.analysis.Dynamism = (a.f0MeanAbsVelocity/.1167627388 + a.f0Entropy/.3331034878)/2 + a.ComplexityAllPauses/.6691896835; % normalization factors from 100 poets, so each term ~10


%% OVERWRITE Voxit OBJECT FILE with new fields included
S.analysis.vuv = vuv;
S.analysis.sps = sps;

if overwrite
    disp('Overwriting Voxit object file with new fields')
    save(filein,'S','-v7.3');
end

end %function voxitAnalysis

%%-------------------------------------------------------------------------------------------------
% SMALL 3RD PARTY (MATLAB-CENTRAL FILE EXCHANGE) FUNCTIONS INCLUDED HERE TO REDUCE FILE CLUTTER
% and HELP END USERS UNDERSTAND THE CODE AT A GLANCE.
% THESE BELONG TO THE AUTHORS CITED BELOW: THANK THEM FOR THE USEFUL TOOLS!!!
% calc_lz_complexity.m
% https://www.mathworks.com/matlabcentral/fileexchange/38211-calc_lz_complexity
% by Quang Thai
% contiguous.m
% https://www.mathworks.com/matlabcentral/fileexchange/5658-contiguous-start-and-stop-indices-for-contiguous-runs
% by David Fass

function runs = contiguous(A,varargin)
%   RUNS = CONTIGUOUS(A,NUM) returns the start and stop indices for contiguous 
%   runs of the elements NUM within vector A.  A and NUM can be vectors of 
%   integers or characters.  Output RUNS is a 2-column cell array where the ith 
%   row of the first column contains the ith value from vector NUM and the ith 
%   row of the second column contains a matrix of start and stop indices for runs 
%   of the ith value from vector NUM.    These matrices have the following form:
%  
%   [startRun1  stopRun1]
%   [startRun2  stopRun2]
%   [   ...        ...  ]
%   [startRunN  stopRunN]
%
%   Example:  Find the runs of '0' and '2' in vector A, where
%             A = [0 0 0 1 1 2 2 2 0 2 2 1 0 0];  
%    
%   runs = contiguous(A,[0 2])
%   runs = 
%           [0]    [3x2 double]
%           [2]    [2x2 double]
%
%   The start/stop indices for the runs of '0' are given by runs{1,2}:
%
%           1     3
%           9     9
%          13    14
%
%   RUNS = CONTIGUOUS(A) with only one input returns the start and stop
%   indices for runs of all unique elements contained in A.
%
%   CONTIGUOUS is intended for use with vectors of integers or characters, and 
%   is probably not appropriate for floating point values.  You decide.  
%

if prod(size(A)) ~= length(A),
    error('A must be a vector.')
end

if isempty(varargin),
    num = unique(A);
else
    num = varargin{1};
    if prod(size(num)) ~= length(num),
        error('NUM must be a scalar or vector.')
    end
end

for numCount = 1:length(num),
    
    indexVect = find(A(:) == num(numCount));
    shiftVect = [indexVect(2:end);indexVect(end)];
    diffVect = shiftVect - indexVect;
    
    % The location of a non-one is the last element of the run:
    transitions = (find(diffVect ~= 1));
    
    runEnd = indexVect(transitions);
    runStart = [indexVect(1);indexVect(transitions(1:end-1)+1)];
    
    runs{numCount,1} = num(numCount);
    runs{numCount,2} = [runStart runEnd];
    
end
end %local function contiguous





function [C, H, gs] = calc_lz_complexity(S, type, normalize)
%CALC_LZ_COMPLEXITY Lempel-Ziv measure of binary sequence complexity. 
%   This function calculates the complexity of a finite binary sequence,
%   according to the algorithm published by Abraham Lempel and Jacob Ziv in
%   the paper "On the Complexity of Finite Sequences", published in 
%   "IEEE Transactions on Information Theory", Vol. IT-22, no. 1, January
%   1976.  From that perspective, the algorithm could be referred to as 
%   "LZ76".
%   
%   Usage: [C, H] = calc_lz_complexity(S, type, normalize)
%
%   INPUTS:
%   
%   S: 
%   A vector consisting of a binary sequence whose complexity is to be
%   analyzed and calculated.  Numeric values will be converted to logical
%   values depending on whether (0) or not (1) they are equal to 0.
%
%   type: 
%   The type of complexity to evaluate as a string, which is one of:
%       - 'exhaustive': complexity measurement is based on decomposing S 
%       into an exhaustive production process.
%       - 'primitive': complexity measurement is based on decomposing S 
%       into a primitive production process.
%   Exhaustive complexity can be considered a lower limit of the complexity
%   measurement approach proposed in LZ76, and primitive complexity an
%   upper limit.
%
%   normalize:
%   A logical value (true or false), used to specify whether or not the 
%   complexity value returned is normalized or not.  
%   Where normalization is applied, the normalized complexity is 
%   calculated from the un-normalized complexity, C_raw, as:
%       C = C_raw / (n / log2(n))
%   where n is the length of the sequence S.
%
%   OUTPUTS:
%
%   C:
%   The Lempel-Ziv complexity value of the sequence S.
%
%   H:
%   A cell array consisting of the history components that were found in
%   the sequence S, whilst calculating C.  Each element in H consists of a
%   vector of logical values (true, false), and represents
%   a history component.
%
%   gs:
%   A vector containing the corresponding eigenfunction that was calculated
%   which corresponds with S.
%
%
%
%   Author: Quang Thai (qlthai@gmail.com)
%   Copyright (C) Quang Thai 2012


%% Some parameter-checking.

% Make sure S is a vector.
if ~isvector(S)
    error('''S'' must be a vector');
end

% Make sure 'normalize' is a scalar.
if ~isscalar(normalize)
    error('''normalize'' must be a scalar');
end

% Make sure 'type' is valid.
if ~(strcmpi(type, 'exhaustive') || strcmpi(type, 'primitive'))
    error(['''type'' parameter is not valid, must be either ' ...
        '''exhaustive'' or ''primitive''']);
end


%% Some parameter 'conditioning'.
S = logical(S);
normalize = logical(normalize);


%% ANALYSIS

% NOTE: Many of these comments will refer to the paper "On the Complexity
% of Finite Sequences" by Lempel and Ziv, so to follow this code, it may 
% be useful to have the manuscript in front of you!

% Allocate memory for eigenfunction (vector of eigenvalues).
% The first value of this vector corresponds with gs(0), and is always
% equal to 0.
% Please note that, since MATLAB array indices start at 1, gs(n) in MATLAB
% actually holds gs(n-1) as defined in the paper.
n = length(S);
gs = zeros(1, n + 1);
gs(1) = 0;  % gs(0) = 0 from the paper


% The approach we will use to find the eigenfunction values at each
% successive prefix of S is as follows:
% - We wish to find gs(n), where 1 <= n <= l(S) (l(S) = length of S)
% - Lemma 4 says:
%       k(S(1,n-1)) <= k(S(1,n))
%           equivalently
%       gs(n-1) <= gs(n)
%   In other words, the eigenfunction is a non-decreasing function of n.
% - Theorem 6 provides the expression that defines the eigenvocabulary of
%   a sequence:
%       e(S(1,n)) = {S(i,n) | 1 <= i <= k(S(1,n))}
%           equivalently
%       e(S(1,n)) = {S(i,n) | 1 <= i <= gs(n)}
%   Note that we do not know what gs(n) is at this point - it's what we're
%   trying to find!!!
% - Remember that the definition of the eigenvocabulary of a sequence S(1,n), 
%   e(S(1,n)), is the subset of the vocabulary of S(1,n) containing words 
%   that are not in the vocabulary of any proper prefix of S(1,n), and the 
%   eigenvalue of S(1,n) is the subset's cardinality: gs(n) = |e(S(1,n))|
%   (p 76, 79)
% - Given this, a corollary to Theorem 6 is:
%       For each S(m,n) | gs(n) < m <= n, S(m,n) is NOT a member of
%       the eigenvocabulary e(S(1,n)).
%       By definition, this means that S(m,n) is in the vocabulary of at
%       least one proper prefix of S(1,n).
% - Also note that from Lemma 1: if a word is in the vocabulary of a
%   sequence S, and S is a proper prefix of S+, then the word is also 
%   in the vocabulary of S+.
% 
% As a result of the above discussion, the algorithm can be expressed in
% pseudocode as follows:
% 
% For a given n, whose corresponding eigenfunction value, gs(n) we wish to 
% find:
% - gs(0) = 0
% - Let m be defined on the interval: gs(n-1) <= m <= n
% - for each m
%       check if S(m,n) is in the vocabulary of S(1,n-1)
%       if it isn't, then gs(n) = m
%       end if
%   end for
%
% An observation: searching linearly along the interval 
% gs(n-1) <= m <= n will tend to favour either very complex sequences 
% (starting from n and working down), or very un-complex sequences
% (starting from gs(n-1) and working up).  This implementation will
% attempt to balance these outcomes by alternately searching from either
% end and working inward - a 'meet-in-the-middle' search.
%
% Note that:
% - When searching from the upper end downwards, we are seeking 
% the value of m such that S(m,n) IS NOT in the vocabulary of S(1,n-1).
% The eigenfunction value is then m.
% - When searching from the lower end upwards, we are seeking the value
% of m such that S(m,n) IS in the vocabulary of S(1,n-1).  The
% eigenfunction value is then m-1, since it is the MAXIMAL value of m
% whereby S(m,n) IS NOT in the vocabulary of S(1,n-1)


%% Calculate eigenfunction, gs(n)

% Convert to string form - aids the searching process!
S = logical(S(:));  %the next few lines embed Thai's binary_seq_to_string to remove that dependency
lookup_string = '01';
S_string = lookup_string(S + 1);
gs(2) = 1;  % By definition.  Remember: gs(2) in MATLAB is actually gs(1)
            % due to the first element of the gs array holding the
            % eigenvalue for n = 0.

for n = 2:length(S)
    
    eigenvalue_found = false;
    
    % The search space gs(n-1) <= m <= n.
    % Remember: gs(n) in MATLAB is actually gs(n-1).
    % Note that we start searching at (gs(n-1) + 1) at the lower end, since
    % if it passes the lower-end search criterion, then we subtract 1
    % to get the eigenvalue.
    idx_list = (gs(n)+1):n;
    for k = 1:ceil(length(idx_list)/2);

        % Check value at upper end of interval
        m_upper = idx_list(end - k + 1);
        if ~numel(strfind(S_string(1:(n-1)), S_string(m_upper:n)))
            % We've found the eigenvalue!
            gs(n+1) = m_upper;    % Remember: 
                                  % gs(n+1) in MATLAB is actually gs(n)
            eigenvalue_found = true;
            break;
        end 
        
        % Check value at lower end of interval.
        %
        % Note that the search at this end is slightly more complicated, 
        % in the sense that we have to find the first value of m where the
        % substring is FOUND, and then subtract 1.  However, this is
        % complicated by the 'meet-in-the-middle' search adopted, as
        % described below...
        m_lower = idx_list(k);
        if numel(strfind(S_string(1:(n-1)), S_string(m_lower:n)))
            % We've found the eigenvalue!
            gs(n+1) = m_lower-1;    % Remember: 
                                    % gs(n+1) in MATLAB is actually gs(n)
            eigenvalue_found = true;
            break;
        elseif (m_upper == m_lower + 1)
            % If we've made it here, then we know that:
            % - The search for substring S(m,n) from the upper end had a
            %   FOUND result
            % - The search for substring S(m,n) from the lower end had a 
            %   NOT FOUND result
            % - The value of m used in the upper end search is one more
            %   than the value of m used in this lower end search
            %
            % However, when searching from the lower end, we need a FOUND
            % result and then subtract 1 from the corresponding m.
            % The problem with this 'meet-in-the-middle' searching is that
            % it's possible that the actual eigenfunction value actually
            % does occur in the middle, such that the loop would terminate
            % before the lower-end search can reach a FOUND result and the
            % upper-end search can reach a NOT FOUND result.
            %
            % This branch detects precisely this condition, whereby
            % the two searches use adjacent values of m in the middle,
            % the upper-end search has the FOUND result that the lower-end
            % search normally requires, and the lower-end search has the
            % NOT FOUND result that the upper-end search normally requires.
            
            % We've found the eigenvalue!
            gs(n+1) = m_lower;      % Remember: 
                                    % gs(n+1) in MATLAB is actually gs(n)
            eigenvalue_found = true;
            break;
        end
                
    end
    
    if ~eigenvalue_found
        % Raise an error - something is not right!
        error('Internal error: could not find eigenvalue');
    end
    
end


%% Calculate the terminal points for the required production sequence.

% Histories are composed by decomposing the sequence S into the following
% sequence of words:
%       H(S) = S(1,h_1)S(h_1 + 1,h_2)S(h_2 + 1,h_3)...S(h_m-1 + 1,h_m)
% The indices {h_1, h_2, h_3, ..., h_m-1, h_m} that characterise a history
% make up the set of 'terminals'.
%
% Alternatively, for consistency, we will specify the history as:
%       H(S) = ...
%           S(h_0 + 1,h_1)S(h_1 + 1,h_2)S(h_2 + 1,h_3)...S(h_m-1 + 1,h_m)
% Where, by definition, h_0 = 0.


% Efficiency measure: we don't know how long the histories will be (and
% hence, how many terminals we need).  As a result, we will allocate an
% array of length equal to the eigenfunction vector length.  We will also
% keep a 'length' counter, so that we know how much of this array we are
% actually using.  This avoids us using an array that needs to be resized
% iteratively!
% Note that h_i(1) in MATLAB holds h_0, h_i(2) holds h_1, etc., since
% MATLAB array indices must start at 1.
h_i = zeros(1, length(gs));
h_i_length = 1;     % Since h_0 is already present as the first value!


if strcmpi(type, 'exhaustive')
    
    % - From Theorem 8, for an exhaustive history, the terminal points h_i,
    % 1 <= i <= m-1, are defined by:
    %       h_i = min{h | gs(h) > h_m-1}
    % - We know that h_0 = 0, so this definition basically bootstraps our
    % search process, allowing us to find h_1, then h_2, etc.
    
    h_prev = 0;     % Points to h_0 initially
    k = 1;
    while ~isempty(k)
        % Remember that gs(1) in MATLAB holds the value of gs(0).
        % Therefore, the index h_prev needs to be incremented by 1
        % to be used as an index into the gs vector.
        k = find(gs((h_prev+1+1):end) > h_prev, 1);
        
        if ~isempty(k)
            h_i_length = h_i_length + 1;
            
            % Remember that gs(1) in MATLAB holds the value of gs(0).
            % Therefore, the index h_prev needs to be decremented by 1
            % to be used as an index into the original sequence S.
            h_prev = h_prev + k;
            h_i(h_i_length) = h_prev;
        end
    end
    
    % Once we break out of the above loop, we've found all of the
    % exhaustive production components.
else
    
    % Sequence type is 'primitive'
   
    % Find all unique eigenfunction values, where they FIRST occur.

    % - From Theorem 8, for a primitive history, the terminal points h_i, 
    % 1 <= i <= m-1, are defined by:
    %        h_i = min{h | gs(h) > gs(h_i-1)}
    % - From Lemma 4, we know that the eigenfunction, gs(n), is
    % monotonically non-decreasing.
    % - Therefore, the following call to unique() locates the first
    % occurrance of each unique eigenfunction value, as well as the values
    % of n where the eigenfunction increases from the previous value.
    % Hence, this is also an indicator for the terminal points h_i.

    [~, n] = unique(gs, 'first');

    % The terminals h_i, 1 <= i <= m-1, is ultimately obtained from n by 
    % subtracting 1 from each value (since gs(1) in MATLAB actually
    % corresponds with gs(0) in the paper)
    h_i_length = length(n);
    h_i(1:h_i_length) = n - 1;
end

% Now we have to deal with the final production component - which may or
% may not be exhaustive or primitive, but can still be a part of an
% exhaustive or primitive process.
%
% If the last component is not exhaustive or primitive, we add it here
% explicitly.
%
% - From Theorem 8, for a primitive history, this simply enforces
% the requirement that:
%       h_m = l(S)
if h_i(h_i_length) ~= length(S)
    h_i_length = h_i_length + 1;
    h_i(h_i_length) = length(S);
end

% Some final sanity checks - as indicated by Theorem 8.
% Raise an error if these checks fail!
% Also remember that gs(1) in the MATLAB code corresponds with gs(0).
if strcmpi(type, 'exhaustive')
    % Theorem 8 - check that gs(h_m - 1) <= h_m-1
    if gs(h_i(h_i_length) - 1 + 1) > h_i(h_i_length-1)
        error(['Check failed for exhaustive sequence: ' ...
            'Require: gs(h_m - 1) <= h_m-1']);
    end
else
    % Sequence type is 'primitive'
    
    % Theorem 8 - check that gs(h_m - 1) = gs(h_m-1)
    if gs(h_i(h_i_length) - 1 + 1) ~= gs(h_i(h_i_length-1) + 1)
        error(['Check failed for primitive sequence: ' ...
            'Require: gs(h_m - 1) = gs(h_m-1)']); 
    end
end


%% Use the terminal points to construct the production sequence.

% Note the first value in h_i is h_0, so its length is one more than the 
% length of the production history.
H = cell([1 (h_i_length-1)]);
for k = 1:(h_i_length-1)
    H{k} = S((h_i(k)+1):h_i(k+1));
end


%% Hence calculate the complexity.
if normalize
    % Normalized complexity
    C = length(H) / (n / log2(n));
else
    % Un-normalized complexity
    C = length(H);
end


%% Eigenfunction is returned.
% The (redundant) first value (gs(0) = 0) is removed first.
gs = gs(2:end);

end %local function calc_lz_complexity





%% % EXTRA code: in beta or not presently used, but knock yourself out

% use gentle to plot words

% %%  SPEAKING RATE (ACOUSTIC)   using simple modspectral moment from N. Morgan, E. Fosler, and N. Mirghafori
% %       "Speech Recognition using On-line Estimation of Speaking Rate," in Proceedings of Eurospeech 1997, 1997, pp. 2079-2082
% % disp('Reminder: Using Depaused speech to calculate speaking rate')
% %linPowerDepause = linPower(find(sps));
% disp('Reminder: Speaking rate includes pauses')
% 
% fspow = 1/ts;
% nfft = 200;
% fres = fspow/nfft;
% 
% downs = 2;
% fres = fres/downs;
% %env1= linPowerDepause-mean(linPowerDepause);
% %env1= linPower-mean(linPower);
% env1 = logPower-mean(logPower);
% env1d=downsample(env1,downs);
% env1dfilt = filterbutterworth(env1d,[0 0.0001; 40 0], fspow, 4); % lowpass below 16Hz
% [p1,f1] = pwelch(env1dfilt,[],0.75*nfft,nfft,100);
% ix=[ceil(1.1/fres):min(round(16/fres),length(p1))]; % get indices to calculate first spectral moment, ignoring up to 1.1Hz
% rate = ix*p1(ix)/sum(p1(ix)).*fres;
% 
% S.analysis.speakingRate = rate; %using modspectral moment from Morgan et al 1997


% % FIND and PLOT STRESS PEAKS IN TIME
% % TALKER 1
% fs = S1.samplingFrequency;
% voiceFilt=[20 1000];
% spect = S1.spectrum_parameter.spectrogramWORLD;
% inc = (fs/2)/(size(spect,1)-1);
% fvals = [0:inc:fs/2];
% 
% spectLow=spect(min(find(fvals>voiceFilt(1))): max(find(fvals<voiceFilt(2))),:);
% linvpow1  = sum(spectLow);
% silence = 0.05.*max(linvpow1);
% disp('warning: finding power peaks arguments only for downsampled fs 200Hz. also noisy audio may need diff parameters')
% MPH = 0.2*mean(linvpow1(find(linvpow1>silence)));
% MPW = 3;
% MPD = 15;% samples
% MPP = 0.1*quantile(linvpow1,0.9);
% 
% figure(fig1)
% findpeaks(linvpow1,'MinPeakHeight',MPH,'MinPeakWidth',MPW,'MinPeakDistance',MPD,'MinPeakProminence',MPP);
% [pks,locs]= findpeaks(linvpow1,'MinPeakHeight',MPH,'MinPeakWidth',MPW,'MinPeakDistance',MPD,'MinPeakProminence',MPP);
% gcf; title([filein1 '   stress'])
% 
% fsyll1 = length(pks)/S1.f0_parameter.temporal_positions(end).* length(linvpow1)/length(find(linvpow1>silence)); %only non-silent periods







