function [S] = vocAnal(filein,overwrite)
% Analyze vocal parameters
% Sfilein STRAIGHT object

if ~exist('overwrite','var')
    overwrite = 0;
end

[pathstr,fileinname,ext] = fileparts(filein);
%%
load(filein)
if ~exist('S','var')
    S=STRAIGHTobject; clear STRAIGHTobject;
end
if isfield(S,'analysis')
    disp('overwriting previous analysis field');
    S=rmfield(S,'analysis');
end

% DEFINE ANALYSIS PARAMETERS
fs = S.samplingFrequency;
ts = S.refinedF0Structure.temporalPositions(2)-S.refinedF0Structure.temporalPositions(1);
vuv = S.SAcC.vuv;
fileseconds = S.refinedF0Structure.temporalPositions(end);

dminvoice = .100; % miminum voiced duration, in sec
dminpause = .100; %minimum pause duration (so we don't count stops esp initial voiceless ones)
pausethresh = 10;  % thresh to detemine pause, e.g. 10dB down from the 90% intensity percentile.
                   % notice this will be overridden by SAcC voicing decision: even low power will be speech if it's voiced
S.analysis.dminvoice = dminvoice;
S.analysis.dminpause = dminpause;
S.analysis.pausethresh = pausethresh;


% %% PITCH plot (sanity check)
% f0_plot = S.AperiodicityStructure.f0;
% f0_plot(S.AperiodicityStructure.vuv==0) = nan;
% t = S.refinedF0Structure.temporalPositions;
% f0sacc_plot = S.SAcC.f0;
% f0sacc_plot(S.SAcC.vuv==0) = nan;
% fig1=figure; hold on
% plot(t,f0_plot,'Linewidth',1.5,'color','b');
% plot(t,f0sacc_plot,'Linewidth',1.5,'color','r')
% % plot(t,f0_plot./max(f0_plot)*100,'Linewidth',1.5,'color','b') % norm to be visible with intensity overlayed, see below
% % plot(t,f0sacc_plot./max(f0sacc_plot)*100,'Linewidth',1.5,'color','r')
% gcf; title([filein '   pitch'])


%% PITCH STATS
% Find contiguous SAcC voiced periods longer than a certain duration, see http://www.mathworks.com/matlabcentral/fileexchange/5658-contiguous-start-and-stop-indices-for-contiguous-runs
% Careful not to measure time-dependent values (velocity or accel) across voiced boudaries!
ivuv = find(S.SAcC.vuv>0); %only work with voiced portions
vdurthresh = round(dminvoice/ts); 
ixtmp = contiguous(S.SAcC.vuv,1); % find start and end indices
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
%     smoothvel = smooth(diff(diffocttmp),'sgolay');
%     f0velocity = [f0velocity; smoothvel/ts]; %norm by sampling period, so in octaves per sec
%     f0accel = [f0accel; diff(smoothvel)/ts]; %in octaves per sec per sec
    f0velocity = [f0velocity; diff(diffocttmp)/ts]; %norm by sampling period, so in octaves per sec
    f0accel = [f0accel; diff(diff(diffocttmp))/ts]; %in octaves per sec per sec
end
S.analysis.f0 = S.SAcC.f0;
S.analysis.f0mean = f0mean;
S.analysis.f0range = max(diffoctf0(ivuv))-min(diffoctf0(ivuv));
S.analysis.f0kurtosis = kurtosis(diffoctf0(ivuv))-3; %-3 so zero is a normal distribution
S.analysis.f0entropy = f0entropy;
%figure, hist(diffoctf0(ivuv),40);title([' kurtosis ' num2str(S.analysis.f0kurtosis)]);
S.analysis.f0velocity = f0velocity;
S.analysis.f0velocitymean = mean(f0velocity);
S.analysis.f0speed = mean(abs(f0velocity)) * sign(mean(f0velocity)); %signed speed, actually
S.analysis.f0velocitystd = std(f0velocity);
S.analysis.f0accel = f0accel;
S.analysis.f0accelmean = mean(f0accel);
S.analysis.f0contour = mean(abs(f0accel)) * sign(mean(f0accel)); %signed directionless acceleration
S.analysis.f0accelstd = std(f0accel);

       
%% PAUSE STATS
spectrogramScaled = S.SpectrumStructure.spectrogramSTRAIGHT./max(max(S.SpectrumStructure.spectrogramSTRAIGHT)); % scale to equalize across recordings
logPower = 10*log10(sum(spectrogramScaled))';
linPower = sum(spectrogramScaled)';
pausetmp = zeros(length(S.refinedF0Structure.temporalPositions),1);
ipause = find(logPower<(max(quantile(logPower,.9))-pausethresh));
pausetmp(ipause) = 1;
pausetmp = pausetmp.*(-(S.SAcC.vuv-1)); %forbid any pauses during voicing

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
ixpausebounds = ixallpausebounds(find(ixpdiff>(dminpause/ts)),:); % ignore those too short. not really pauses at all
pausedurs = ((ixpausebounds(:,2)-ixpausebounds(:,1))+1).*ts;
S.analysis.pausedurs = pausedurs;
S.analysis.pausecount = length(pausedurs);
S.analysis.pauserate = length(pausedurs)/fileseconds;
S.analysis.pausetime = sum(pausedurs)/fileseconds;
S.analysis.pausemean = mean(pausedurs);
S.analysis.pausecount100 = length(find(pausedurs>=0.100));
S.analysis.pauserate100 = length(find(pausedurs>=0.100))/fileseconds;
S.analysis.pausemean100 = mean(pausedurs(find(pausedurs>=0.100)));
S.analysis.pausecount250 = length(find(pausedurs>=0.250));
S.analysis.pauserate250 = length(find(pausedurs>=0.250))/fileseconds;
S.analysis.pausemean250 = mean(pausedurs(find(pausedurs>=0.250)));
S.analysis.pausecount500 = length(find(pausedurs>=0.500));
S.analysis.pauserate500 = length(find(pausedurs>=0.500))/fileseconds;
S.analysis.pausemean500 = mean(pausedurs(find(pausedurs>=0.500)));
S.analysis.pausebounds = ixpausebounds;

%% INTENSITY STATS
%Then infer indices for speech (not just voicing!) as the opposite of pauses, but again careful not to count the ends as pauses
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

Imean = 10.^(mean(logPower(ispeech)/10));  %only calc mean when speech, not pause
difflogI = 10*log10(linPower/Imean);

Ivelocity = [];
Iaccel = [];
for i = 1:size(ixspeechbounds,1)  %the loop makes sure we're not calculating velocity etc across segments
    diffocttmp = difflogI(ixspeechbounds(i,1):ixspeechbounds(i,2));
    Ivelocity = [Ivelocity; diff(diffocttmp)/ts]; %norm by sampling period, so in octaves per sec
    Iaccel = [Iaccel; diff(diff(diffocttmp))/ts]; %in octaves per sec per sec
end
S.analysis.Ilog = logPower;
S.analysis.Imean = Imean;
S.analysis.Ivelocity = Ivelocity;
S.analysis.Ivelocitymean = mean(Ivelocity);
S.analysis.Ispeed = mean(abs(Ivelocity)) * sign(mean(Ivelocity)); %signed speed, actually
S.analysis.Ivelocitystd = std(Ivelocity);
S.analysis.Iaccel = Iaccel;
S.analysis.Iaccelmean = mean(Iaccel);
S.analysis.Icontour = mean(abs(Iaccel)) * sign(mean(Iaccel)); %signed directionless acceleration
S.analysis.Iaccelstd = std(Iaccel);
S.analysis.complexityAllPauses = 100.*calc_lz_complexity(sps, 'exhaustive', 1);

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
S.analysis.complexitySyllables = 100.*calc_lz_complexity(vuvSyl, 'exhaustive', 1);

ixPhraseBoundsTmp = ixallvoicebounds;
ixPhraseBounds = [];
iPhrase = []; %get all indices, not just the boundaries
for kk = 1:size(ixPhraseBoundsTmp,1)-1 %delete indices so short unvoiced periods are removed to make longer continguous phrases
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
S.analysis.complexityPhrases = 100.*calc_lz_complexity(vuvPhrase, 'exhaustive', 1);

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
S.analysis.corrf0I = corrf0I(1,2); % correlation between pitch and intensity
S.analysis.corrf0Ipval = corrf0Ipval(1,2);

figure, hold on, 
scatter(logPowhighI,f0loghighI);
xlabel('logPower'); 
ylabel('f0log'); 
title('Correlation between intensity and pitch');

bestfit = polyfit(logPowhighI,f0loghighI,1);
y = bestfit(1)*logPowhighI + bestfit(2);
plot(logPowhighI,y,'k');



%%  SPEAKING RATE   using simple modspectral moment from N. Morgan, E. Fosler, and N. Mirghafori
%       "Speech Recognition using On-line Estimation of Speaking Rate," in Proceedings of Eurospeech 1997, 1997, pp. 2079-2082
% disp('Reminder: Using Depaused speech to calculate speaking rate')
%linPowerDepause = linPower(find(sps));
disp('Reminder: Speaking rate includes pauses')

fspow = 1/ts;
nfft = 200;
fres = fspow/nfft;

downs = 2;
fres = fres/downs;
%env1= linPowerDepause-mean(linPowerDepause);
%env1= linPower-mean(linPower);
env1 = logPower-mean(logPower);
env1d=downsample(env1,downs);
env1dfilt = filterb(env1d,[0 0.0001; 40 0], fspow, 4); % lowpass below 16Hz
[p1,f1] = pwelch(env1dfilt,[],0.75*nfft,nfft,100);
ix=[ceil(1.1/fres):min(round(16/fres),length(p1))]; % get indices to calculate first spectral moment, ignoring up to 1.1Hz
rate = ix*p1(ix)/sum(p1(ix)).*fres;

S.analysis.speakingRate = rate; %using modspectral moment from Morgan et al 1997


%%  COMPOSITE METRICS
a=S.analysis;
%S.analysis.dynamism = (abs(a.f0speed) * a.f0entropy) +
%(a.complexitySyllables+a.complexityPhrases)/2*0.439; % 43.9 brings it into
%same range as first term. this should be what we used for the final
%100poets analysis.  1/2*0.439 = 0.2195
S.analysis.dynamism = abs(a.f0speed)/1.092050992 + a.f0entropy/3.331034878 + (a.complexitySyllables/13.18735087+a.complexityPhrases/3.022951534)/2; % bring terms into same range ~1
% This "dynamism" is an average of 4 measures (scaled to appx mean across
% poets = 100): pitch speed, pitch entropy, syllabic complexity, and
% phrasal complexity
%S.analysis.dynamism = 100/4.*(abs(a.f0speed)/1.09 + a.f0entropy/3.33 + a.complexitySyllables/13.19 + a.complexityPhrases/3.02); % bring terms into same range ~1


%S.analysis.dynamism = a.f0range * a.f0invkurt * a.corrf0I;
% mean values from 100 poets:  f0speed = -1.092050992; f0entropy =
% 3.331034878; complexitySyllables = 13.18735087; complexityPhrases =
% 3.022951534;



%% PLOT (once debugged, move this to separate function)

%load gentle file to plot words




%% OVERWRITE STRAIGHT OBJECT FILE with new fields included
S.analysis.vuv = vuv;
S.analysis.sps = sps;

if overwrite
    disp('Overwriting Straight object file with new fields')
    save(filein,'S','-v7.3');
end






% %% EXTRA
% % FIND and PLOT STRESS PEAKS IN TIME
% % TALKER 1
% fs = S1.samplingFrequency;
% voiceFilt=[20 1000];
% spect = S1.SpectrumStructure.spectrogramSTRAIGHT;
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
% fsyll1 = length(pks)/S1.refinedF0Structure.temporalPositions(end).* length(linvpow1)/length(find(linvpow1>silence)); %only non-silent periods







