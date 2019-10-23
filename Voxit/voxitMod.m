function [newsound,fs] = voxitMod(filein,manipulation,rmsnorm)
% VOXIT MOD modifies vocal parameters in a Voxit object file and resynthsizes the sound
%
% IMPORTANT: the resynthesis requires the spectrogram to be kept
% in the Voxit structure, so you must run voxitPrep with spectKeep = 1 (this increases memory
% load significantly for voxitAnalysis, as well as takes up a lot more disk space);
%
% copyright Lee M. Miller 2019, latest mods 10/2019


load(filein)
[pathstr,fileinname,ext] = fileparts(filein);
if strfind(fileinname,'_Vobj') %remove the Sobj suffix
    fileinname=[fileinname(1:strfind(fileinname,'_Vobj')-1) fileinname(strfind(fileinname,'_Vobj')+5:end)];
end

disp('CONFIRM THAT WE STILL HAVE THE SPECTROGRAM AND APERIODICITY')

%If you ran STRAIGHTaudio2object, you should have variable S in your workspace. This is the STRAIGHTobject
%If you have variable "STRAIGHTobject" instead call this S for simplicity.
%S= STRAIGHTobject;

% get the pitch contour
f0_original = S.AperiodicityStructure.f0; 


%IF desired, remove  very brief voiced periods (may help with noisy audio? maybe no diff at all)
% vuvmin = 5; % duration of minimum voiced period, in samples (default 5ms period)
% vuv = S.AperiodicityStructure.vuv;
% vuvclean = vuv;
% L=bwlabel(vuv);
% [h,n]=hist(L,[0:max(L)]);
% vuvminvals = n(find(h<vuvmin));
% ishort = ismember(L,vuvminvals);
% vuvclean(ishort)=0;  % set all the brief voicing periods to vuv=0
% S.AperiodicityStructure.vuv = vuvclean;

switch manipulation
    
    case 'double';
        f0_new = f0_original*2;

    case 'flat';
        ivuv = find(S.AperiodicityStructure.vuv>0); %only work with voiced portions
        f0mean = 2.^(mean(log2(f0_original(ivuv)))); % log, as opposed to the linear f0mean = mean(f0_original(ivuv));
        f0_new = f0_original;
        f0_new(ivuv) = f0mean;

    case 'pitch2stress'
        ivuv = find(S.AperiodicityStructure.vuv>0); %only work with voiced portions
        f0mean = 2.^(mean(log2(f0_original(ivuv)))); % log, as opposed to the linear % f0mean = mean(f0_original(ivuv));
        f0_new = f0_original;
        diffoct = log2(f0_original) - log2(f0mean);
        if length(S.AperiodicityStructure.vuv)~=length(S.SpectrumStructure.temporalPositions)
            error('Aperiodicity and Spectrum info are different lengths. Cannot combine them')
        end
        stressfactor = zeros(1,length(S.SpectrumStructure.temporalPositions));
        stressfactor(ivuv) = diffoct(ivuv)';
        modifiedPower = stressfactor; %?? as is, or scaled somehow?
        logPower = 10*log10(sum(S.SpectrumStructure.spectrogramSTRAIGHT)); %this is how the manipulationulation GUI changes levels
        powerModifier = 10.0.^((modifiedPower-logPower)/10);
      
        modifiedPower = min(-2,modifiedPower);
        disp('figure what the hell  modifiedPower means numerically in dB')
        modifiedPower = repmat(modifiedPower,size(S.SpectrumStructure.spectrogramSTRAIGHT,1),1);
        stressedSpectrogram = S.SpectrumStructure.spectrogramSTRAIGHT .* modifiedPower;
        S.SpectrumStructure.spectrogramSTRAIGHT = stressedSpectrogram; 
        
  case 'stress2pitch'
        If0scalefactor = 1; % multiplier to map intensity changes onto pitch. Try between 1 and 2. ish.
        Iquantile = 0.5; % intensity quantile to change pitch at all (less intense sounds not changed in pitch)
        ivuv = find(S.AperiodicityStructure.vuv>0); %only work with voiced portions
        f0mean = 2.^(mean(log2(f0_original(ivuv)))); % log, as opposed to the linear % f0mean = mean(f0_original(ivuv));
        f0_new = f0_original;
        diffoct = log2(f0_original) - log2(f0mean);
        if length(S.AperiodicityStructure.vuv)~=length(S.SpectrumStructure.temporalPositions)
            error('Aperiodicity and Spectrum info are different lengths. Cannot combine them')
        end;
        logPower = 10*log10(sum(S.SpectrumStructure.spectrogramSTRAIGHT)); %this is how the manipulationulation GUI changes levels
        powerModifier = zeros(size(diffoct));
        logPowerNormed = (logPower - quantile(logPower,Iquantile))./max(logPower) .* If0scalefactor; % first norm to select range
        logPowerNormed = max(logPowerNormed,0)'; % rectify, so only change pitch if loud enough in the first place
        modifiedPitch = f0mean*2.^(diffoct+logPowerNormed);
        f0_new(ivuv) = modifiedPitch(ivuv);
        
    case 'flip';
        ivuv = find(S.AperiodicityStructure.vuv>0); %only work with voiced portions
        f0mean = 2.^(mean(log2(f0_original(ivuv)))); % log, as opposed to the linear % f0mean = mean(f0_original(ivuv));
        f0_new = f0_original;
        diffoct = log2(f0_original) - log2(f0mean);
        f0_new(ivuv) = f0mean*2.^(-diffoct(ivuv));  % as opposed to linear f0_new(ivuv) = -f0_original(ivuv)+2*f0mean;
        f0_new = max(f0_new,50); %guard against negative values, lowest pitch 

    case 'fliplin'
        ivuv = find(S.AperiodicityStructure.vuv>0); %only work with voiced portions
        f0mean = mean(f0_original(ivuv)); 
        f0_new = f0_original;
        f0_new(ivuv) = -f0_original(ivuv)+2*f0mean;
        f0_new = max(f0_new,50); %guard against negative values, lowest pitch 

        
    case 'pitchNsize'
        f0_new = f0_original*2;  %make this an argin, or perhaps some plausible ratio of pitch and size manip
        
        nFrames = length(S.SpectrumStructure.temporalPositions);
        sizeModifier = ones(nFrames,1).*0.8;  % make this an argin! <1 makes size smaller
        baseFrequency = (0:size(S.SpectrumStructure.spectrogramSTRAIGHT,1)-1)/...
            (size(S.SpectrumStructure.spectrogramSTRAIGHT,1)-1)/2*S.samplingFrequency;
        for ii = 1:nFrames
            S.SpectrumStructure.spectrogramSTRAIGHT(:,ii) = interp1(baseFrequency,...
                S.SpectrumStructure.spectrogramSTRAIGHT(:,ii),...
                baseFrequency*sizeModifier(ii),'linear',S.SpectrumStructure.spectrogramSTRAIGHT(end,ii));
        end;
    case 'MFM'
        nFrames = length(S.SpectrumStructure.temporalPositions);
        f0modifier = linspace(1,2,nFrames)';
        f0_new = f0_original.*f0modifier;  %make this an argin, or perhaps some plausible ratio of pitch and size manip
        sizeModifier = linspace(1,0.8,nFrames);  % make this an argin! <1 makes size smaller
        baseFrequency = (0:size(S.SpectrumStructure.spectrogramSTRAIGHT,1)-1)/...
            (size(S.SpectrumStructure.spectrogramSTRAIGHT,1)-1)/2*S.samplingFrequency;
        for ii = 1:nFrames
            S.SpectrumStructure.spectrogramSTRAIGHT(:,ii) = interp1(baseFrequency,...
                S.SpectrumStructure.spectrogramSTRAIGHT(:,ii),...
                baseFrequency*sizeModifier(ii),'linear',S.SpectrumStructure.spectrogramSTRAIGHT(end,ii));
        end; 
        
        
    otherwise
        error('Unrecognized pitch manipulationulation')
        
end %switch


% soft limiter to moderate extreme values
disp('WARNING: soft limiting pitch extremes')
f0low = 60;
f0high= 500;
dslope = .2;
f0_new(find(f0_new<f0low)) = f0_new(find(f0_new<f0low)) + dslope*(f0low-f0_new(find(f0_new<f0low)));
f0_new(find(f0_new>f0high)) = f0_new(find(f0_new>f0high)) + dslope*(f0_new(find(f0_new>f0high))-f0high);

% make a copy of the Straight object and replace that pitch field
S_new = S;
S_new.AperiodicityStructure.f0 = f0_new;

% Resythesize the new sound
newsoundStruct = exGeneralSTRAIGHTsynthesisR2(S_new.AperiodicityStructure,S_new.SpectrumStructure);

% write the old sound
% origsound = S.waveform;
% if exist('rmsnorm','var')
%     origsound = origsound./(rms(origsound)/rmsnorm);
% end
% 
% if max(abs(origsound))>1
%     origsound = origsound ./ max(abs(origsound)) .* .99;
%     warning('had to scale ORIGINAL (possibly normed) sound output file to avoid clipping');
% end
% fs = S.samplingFrequency;
% origsoundfile = [pathstr fileinname '_orig.wav'];
% audiowrite(origsoundfile,origsound,fs);

% write new sound
newsound = newsoundStruct.synthesisOut;
if exist('rmsnorm','var')
    newsound = newsound./(rms(newsound)/rmsnorm);
end

if max(abs(newsound))>1
    newsound = newsound ./ max(abs(newsound)) .* .99;
    warning('had to scale NEW (possibly normed) sound output file to avoid clipping ');
end
fs = S.samplingFrequency;
newsoundfile = [pathstr fileinname '_' manipulation '.wav'];
audiowrite(newsoundfile,newsound,fs);

disp('SAVE MODULATION PARAMETERS IN Vobj S.mod.filename ')

% Oh, for plotting you just want to change unvoiced f0 values to nan's 
figure, hold on, xlabel('Time (s)'), ylabel('Pitch (Hz)')
t=S.AperiodicityStructure.temporalPositions; % time axis
f0_original_plot = f0_original;
f0_original_plot(S.AperiodicityStructure.vuv==0) = nan;
plot(t,f0_original_plot,'Linewidth',1.5,'color','b') % blue

f0_newplot = f0_new;
f0_newplot(S_new.AperiodicityStructure.vuv==0) = nan;
plot(t,f0_newplot,'Linewidth',1.5,'color','r') % red

title(filein)

end