function [S] = STRAIGHTaudio2object(filepath,file,SAcCresynth,driftfile)
%%  modified from STRAIGHTs exampleScriptForAnalysisAndSynthesis.m
%   file         audio file
%   driftfile   (optional) use drift pitch values to overwrite those of STRAIGHT
%
%
%Test script for basic TANDEM-STRAIGHT analysis and synthesis
%   by Hideki Kawahara
%   20/April/2012
%   06/Oct./2015 R2015b compatibility fix
%   Please use this in "cell mode"
%   mods Lee Miller LMM 2/2017   my variable S always = S in Hideki's code


%%  Initialize conditions

if ~strcmp(filepath(end),filesep)
    filepath = [filepath filesep];
end
if ~exist('SAcCresynth','var')
    SAcCresynth = 0; % If you want to use the Ellis algorithm, set this variable 1;
end
if ~exist('driftfile','var')
    driftfile = 0; 
end


%%  Read speech data from a file
[x,fs] = audioread([filepath file]);
x = x(:,1); %   Make sure it is a comum vector.
%soundsc(x,fs) % Playback sound

%% Initialize
S = struct;
S.creationDate = datestr(now,30);
S.dataDirectory = filepath;
S.dataFileName = file;
S.samplingFrequency = fs;
S.waveform = x(:,1);
S.standAlone = true;
S.soundPath = filepath;
S.startedDirectory = pwd;


%% Auto LF clean --  which is the default in the GUI! (f0ExtractorGUI.m line 262+
autoLFClean = 1;
if autoLFClean
    xtmp = S.waveform;
    xClean = blackmanBasedHPF(xtmp,fs,20,1); % This default can be modified 24/April/2013
    xClean = inductionAndLowFrequencyNoizeSuppression(xClean,fs);
    S.waveform = xClean;
end;


%%  Extract source (F0) information
disp(['Extracting F0 for file ' file])
S.F0extractionDate = datestr(now,30);

optP.debugperiodicityShaping = 1.3;% LMM looks like this is what it uses via GUI
optP.channelsPerOctave = 3; % LMM as per GUI default
optP.f0ceil = 650;% LMM as per gui default

% LMM the following do not appear to be set in the GUI. 
%Rather, exF0candidatesTSTRAIGHTGB  will use its  defaults
% optP.compensationCoefficient = 0;
% optP.exponentControl = 1;
% optP.numberOfHarmonicsForExtraction = 4;% 22/May/2010

% Extract F0 information
S.originalF0Structure = exF0candidatesTSTRAIGHTGB(S.waveform,fs,optP);

S.originalF0Structure.f0Extractor = 'XSX';

% This first vuv is probably very important for subsequent synthesis. 
%This is, in fact, what the GUI does, although Hideki comments 'The following line is too poor. This has to be elaborated'. 
S.originalF0Structure.vuv = S.originalF0Structure.periodicityLevel>0.71; %1.42*(2.5/2);

%%Shift around some structure fields
additionalInformation.controlParameters = S.originalF0Structure.controlParameters;
%rmfield(S.originalF0Structure,'controlParameters');
additionalInformation.dateOfSourceExtraction = S.originalF0Structure.dateOfSourceExtraction;
%rmfield(S.originalF0Structure,'dateOfSourceExtraction');
additionalInformation.statusParamsF0 = S.originalF0Structure.statusParamsF0;
%rmfield(S.originalF0Structure,'statusParamsF0');
additionalInformation.elapsedTimeForF0 = S.originalF0Structure.elapsedTimeForF0;
%rmfield(S.originalF0Structure,'elapsedTimeForF0');
S.originalF0Structure.additionalInformation = additionalInformation;


disp('Auto-tracking F0') % Clean F0 trajectory by tracking
S.refinedF0Structure = autoF0Tracking(S.originalF0Structure,S.waveform);

%% SAcC: Get a better F0 estimate for later analysis, NOT (yet) for resynthesis using SAcC. This uses Dan Ellis Subband PCA Autocorrelation algo. 
% We do this always, to resample and add the SAcC (and if applicable, the drift) f0 and vuv to the STRAIGHT structure, regardless 
% of whether SAcC or drift is used to overwrite the STRAIGHT f0 and thus be used in resynthesis.  The latter decision is in the  cell below.
disp('Warning: ASSUMING STRAIGHT sampling period 5ms, SAcC/drift period 10ms, both starting at time 0! Fix if not true')
% Resample and include SAcC pitch, vuv in S structure
[psacc,tsacc]=SAcCWrapper([filepath file]);
tsacc = round(tsacc*1000)/1000; %damn SAcC times can have an extra tiny significant digit. round to nearest ms 
tstraight = S.refinedF0Structure.temporalPositions;
pnewSAcC = S.refinedF0Structure.f0; %SAcC will overwrite some of these values, so will be the conjunction of STRAIGHT and (interpolated) SAcC f0, in case its needed  for resynthesis below.
vuvnewSAcC = S.refinedF0Structure.vuv; % to be the conjunction of STRAIGHT and (interpolated )SAcC voicing, in case its needed  for resynthesis below.
f0tmp = zeros(length(pnewSAcC),1); % this just keeps the SAcC values, doesn't combine with STRAIGHT f0, for SAaC-only analysis
vuvtmp = zeros(length(pnewSAcC),1);
for j = 1:length(tstraight) 
    imatch = find(tsacc==tstraight(j)); 
    if imatch % if both SAcC and STRAIGHT have a common sample time
        if psacc(imatch)>0   % ... and if SAcC has voicing then
            pnewSAcC(j) = psacc(imatch);
            vuvnewSAcC(j) = 1;
            f0tmp(j) = psacc(imatch);
            vuvtmp(j) = 1;
        end  
    else  % if we need to interpolate (because SAcC is lower sampling rate than STRAIGHT)
        try
           itlow = max(find(tsacc<tstraight(j)));
           ithigh = min(find(tsacc>tstraight(j)));               
           if psacc(itlow)>0 & psacc(ithigh)>0 %if you're within the sacc voiced region
               pnewSAcC(j) = mean([psacc(itlow) psacc(ithigh)]);% linear interpolation, only within exisiting vuv periods
               vuvnewSAcC(j) = 1;
               f0tmp(j) = pnewSAcC(j);
               vuvtmp(j) = 1;                  
           else  % keep STRAIGHT values for pnewSAcC and vuvnewSAcC
               f0tmp(j) = 0;
               vuvtmp(j) = 0;
           end
        catch % keep STRAIGHT values for pnewSAcC and vuvnewSAcC
           f0tmp(j) = 0;
           vuvtmp(j) = 0;
        end      
    end
end;
S.SAcC.f0 = f0tmp;  
S.SAcC.vuv = vuvtmp; 

%% Resample and include DRIFT pitch, vuv in S structure. Same as we did withSAcC
% NOT CURRENTLY USING THIS FOR overwriting pitch values. confirm match with SAcC
% if driftfile
%     [num,txt,raw] = xlsread(driftfile);
%     [C,ia,ib] = intersect(tsacc,num(:,1));
%     pdrift = zeros(size(psacc));
%     pdrift(ia) = num(ib,2);
%     tdrift = tsacc;
%     
%     tstraight = S.refinedF0Structure.temporalPositions;
%     pnewDrift = S.refinedF0Structure.f0; %SAcC will overwrite some of these values, so will be the conjunction of STRAIGHT and (interpolated) SAcC f0
%     vuvnewDrift = S.refinedF0Structure.vuv; % to be the conjunction of STRAIGHT and (interpolated )SAcC voicing
%     f0tmp = zeros(length(pnewDrift),1); % this just keeps the Drift values, doesn't combine with STRAIGHT f0
%     vuvtmp = zeros(length(pnewDrift),1);
%     for j = 1:length(tstraight) 
%         imatch = find(tdrift==tstraight(j)); 
%         if imatch % if both SAcC and STRAIGHT have a common sample time
%             if pdrift(imatch)>0   % ... and if SAcC has voicing then
%                 pnewDrift(j) = pdrift(imatch);
%                 vuvnewDrift(j) = 1;
%                 f0tmp(j) = pdrift(imatch);
%                 vuvtmp(j) = 1;
%             end  
%         else  % if we need to interpolate (because SAcC is lower sampling rate than STRAIGHT)
%             try
%                itlow = max(find(tdrift<tstraight(j)));
%                ithigh = min(find(tdrift>tstraight(j)));               
%                if pdrift(itlow)>0 & pdrift(ithigh)>0 %if you're within the sacc voiced region
%                    pnewDrift(j) = mean([pdrift(itlow) pdrift(ithigh)]);% linear interpolation, only within exisiting vuv periods
%                    vuvnewDrift(j) = 1;
%                    f0tmp(j) = pnewDrift(j);
%                    vuvtmp(j) = 1;                  
%                else  % keep STRAIGHT values for pnewDrift and vuvnewDrift
%                    f0tmp(j) = 0;
%                    vuvtmp(j) = 0;
%                end
%             catch % keep STRAIGHT values for pnewDrift and vuvnewDrift
%                f0tmp(j) = 0;
%                vuvtmp(j) = 0;
%             end      
%         end
%     end;
%     S.drift.f0 = f0tmp;  
%     S.drift.vuv = vuvtmp;   
% end
% Notice we have NOT overwritten the S.refinedF0structure.pnewDrift or .vuvnewDrift. We dedide that next...

%% Refine F0 estimate. If indicated, use the SAaC-improved STRAIGHT pitch for resynthesis. Otherwise, use STRAIGHT default. 
% However for any samples without SAcC estimate, pnewSAcC and vuvnewSAcC (from above) keep the STRAIGHT f0 and vuv respectively
% otherwise you're left with powerful but (as far as SAcC is concerned)
% unvoiced bits that sound crappy upon resynth.   Build field .refinedF0Structure    LMM170223
if SAcCresynth % use Ellis 2012 algo to get pitch contours. But have to interpolate f0 values to STRAIGHT temporal positions
    S.refinedF0Structure.f0 = pnewSAcC; % the conjunction of STRAIGHT and (interpolated) SAcC f0
    S.refinedF0Structure.vuv = vuvnewSAcC; %the conjunction of STRAIGHT and (interpolated) SAcC voicing    
% if driftfile  % use pitch having drift values overwriting STRAIGHT values
%     S.refinedF0Structure.f0 = pnewDrift; % the conjunction of STRAIGHT and (interpolated) SAcC f0
%     S.refinedF0Structure.vuv = vuvnewDrift; %the conjunction of STRAIGHT and (interpolated) SAcC voicing    
else  %default, if not SAcC use STRAIGHT autoF0tracking already done above
    S.refinedF0Structure.vuv = refineVoicingDecision(S.waveform,S.refinedF0Structure);
end


%% Extract Aperiodicity information
disp('Extracting aperiodicity info')
S.AperiodicityExtractionDate = datestr(now,30);
S.AperiodicityStructure = aperiodicityRatioSigmoid(S.waveform,S.refinedF0Structure,2,2,0); % originally 2
if isfield(S.refinedF0Structure,'vuv')
    S.AperiodicityStructure.vuv = S.refinedF0Structure.vuv;
end;


%%  Extract spectral information
disp('Extracting spectral info')
S.SpectrumExtractionDate = datestr(now,30);
SpectrumStructure = exSpectrumTSTRAIGHTGB(S.waveform, ...
    S.samplingFrequency, ...
    S.refinedF0Structure);
S.SpectrumStructure = SpectrumStructure;
S.SpectrumStructure.spectrogramSTRAIGHT = unvoicedProcessing(S);
S.SpectrumStructure.logPower = 10*log10(sum(S.SpectrumStructure.spectrogramSTRAIGHT));

%% plot spectrogram
sgramSTRAIGHT = 10*log10(S.SpectrumStructure.spectrogramSTRAIGHT);
maxLevel = max(max(sgramSTRAIGHT));
figure;
imagesc([0 S.SpectrumStructure.temporalPositions(end)],[0 fs/2],max(maxLevel-80,sgramSTRAIGHT));
axis('xy')
set(gca,'fontsize',14);
xlabel('time (s)')
ylabel('frequency (Hz)');
title('STRAIGHT spectrogram')


%TRIED INSERTING SAcC PITCH AT THE VERY END, BEFORE SYNTHESIS. nope.
%S.AperiodicityStructure.vuv = vuvSAcC'; 
%S.AperiodicityStructure.f0 = pnewSAcC';

%% (Re)Synthesize and Save STRAIGHT object.
disp('(Re)Synthesizing and saving STRAIGHT object')
S.SynthesisStructure = exGeneralSTRAIGHTsynthesisR2(S.AperiodicityStructure,...
    S.SpectrumStructure);
S.lastUpdate = datestr(now);
[filepathstr,fname,fext] = fileparts(file);

if SAcCresynth
    fname = [fname '_SAcC'];
end

Sfileout = [filepath fname '_Sobj.mat'];
save([Sfileout],'S','-v7.3'); % save STRAIGHT object
synth = S.SynthesisStructure.synthesisOut;
synth = synth./max(1,max(abs(synth))*1.01); %normalize for writing to file
synthfileout = [filepath fname '_resynth.wav'];
audiowrite(synthfileout,synth,S.SynthesisStructure.samplingFrequency);% save resynthesized sound


   
figure;
plot(S.refinedF0Structure.temporalPositions,S.refinedF0Structure.f0);grid on
set(gca,'fontsize',14);
xlabel('time (s)')
ylabel('fundamental frequency (Hz)');
title('fundamental frequency')


%% Save (Re)Synthesized sound  LMM THIS NEEDS DEBUGGING
%disp('Saving Synthesized sound')
% outSignal = S.SynthesisStructure.synthesisOut;
% attenuation = 0.85/max(abs(outSignal));
% outSignal = outSignal*attenuation;
% audiowrite([filepath file],outSignal,S.samplingFrequency);
% % s = exTandemSTRAIGHTsynthNx(q,f)
% % sound(s.synthesisOut/max(abs(s.synthesisOut))*0.8,fs) % old implementation

%%
%%
   % if SAcC  % this is from Hideki's original script. looks like it only deals with LF noise
   %     disp('Cleaning noise and re-extracting F0')
   %      xtmp = removeLF(S.originalF0Structure.waveform,fs,S.originalF0Structure.f0,S.originalF0Structure.periodicityLevel); % Low frequency noise remover
   %      S.originalF0Structure = exF0candidatesTSTRAIGHTGB(xtmp,fs,optP);
   %      S.originalF0Structure.f0Extractor = 'XSX';
   %
   %     % LMM all these may be redundant if we're packing them all into additionalINformation, but I'm leaving them for good measure
   %      % Hideki says 'The following line is too poor. This has to be elaborated'.
   %     S.originalF0Structure.vuv = S.originalF0Structure.periodicityLevel>0.71; %1.42*(2.5/2);
   %     %shift around some structure fields
   %     additionalInformation.controlParameters = S.originalF0Structure.controlParameters;
   %     %rmfield(S.originalF0Structure,'controlParameters');
   %     additionalInformation.dateOfSourceExtraction = S.originalF0Structure.dateOfSourceExtraction;
   %     %rmfield(S.originalF0Structure,'dateOfSourceExtraction');
   %     additionalInformation.statusParamsF0 = S.originalF0Structure.statusParamsF0;
   %     %rmfield(S.originalF0Structure,'statusParamsF0');
   %     additionalInformation.elapsedTimeForF0 = S.originalF0Structure.elapsedTimeForF0;
   %     %rmfield(S.originalF0Structure,'elapsedTimeForF0');
   %     S.originalF0Structure.additionalInformation = additionalInformation;
   % end;


