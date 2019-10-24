function [S] = VoxitPrep(filepath,file,spectKeep,SAcCresynth)
%% Voxit prep script for basic WORLD analysis and synthesis
% Important bits modified from WORLDs exampleScriptForAnalysisAndSynthesis.m
% INPUTS
%   filepath:   file path        
%   file:       audio filename
%   spectKeep   keep spectrogram and aperiodicity as part of the output structure in order
%               to resythesize later (takes up lots of space and memory). Default = 0
%   SAcCresynth: use the SAcC pitch when resythesizing audio
%
% OUTPUTS
%   S           WORLD/Voxit structure
%  
% IF there exist output files from DRIFT and GENTLE with identical
% filenames to the audio files, except with '-drift.csv' and '-gentle.csv', this
% function will also include their info in the output structure for later
% analysis.
% A Drift file's pitch values could also be used here to overwrite
%   those of WORLD or the matlab SAcC
%
% For multi-channel audio, this function only uses the first channel.
%   
% copyright Lee M. Miller, latest mods 11/2019


%%  Initialize conditions
if ~strcmp(filepath(end),filesep)
    filepath = [filepath filesep];
end
if ~exist('spectKeep','var')
    spectKeep = 0; % If you want to keep the spectrogram for later resynthesis, set this variable = 1;
end
if ~exist('SAcCresynth','var')
    SAcCresynth = 0; % If you want to use the Ellis algorithm for resynthesis, set this variable 1;
end



%%  Read speech data from a file
[x,fs] = audioread([filepath file]);
x = x(:,1); %   Make sure it is a column, mono vector.

%% Initialize
S = struct;
S.creationDate = datestr(now,30);
S.dataDirectory = filepath;
S.dataFileName = file;
S.samplingFrequency = fs;
S.waveform = x(:,1);

S.f0_parameter = Harvest(x, fs);
S.spectrum_parameter = CheapTrick(x, fs, S.f0_parameter);
S.source_parameter = D4C(x, fs, S.f0_parameter);

%% SAcC: Get a better F0 estimate for later analysis, NOT (yet) for resynthesis using SAcC. This uses Dan Ellis Subband PCA Autocorrelation algo. 
% We do this always, to resample and add the SAcC (and if applicable, the drift) f0 and vuv to the WORLD structure, regardless 
% of whether SAcC or drift is used to overwrite the WORLD f0 and thus be used in resynthesis.  The latter decision is in the  cell below.
% Resample and include SAcC pitch, vuv in S structure
[psacc,tsacc]=SAcCWrapper([filepath file]);
tsacc = round(tsacc*1000)/1000; %damn SAcC times can have an extra tiny significant digit. round to nearest ms 
tworld = S.f0_parameter.temporal_positions;
if (psacc(2)-psacc(1) ~= 0.01) & (tworld(2)-tworld(1) ~= 0.005) & psacc(1)~=0 & tworld(1)~=0
   error('Check sampling times: WORLD should have sampling period 5ms, SAcC/drift should have period 10ms, both starting at time 0.')
end
pnewSAcC = S.f0_parameter.f0; %SAcC will overwrite some of these values, so will be the conjunction of WORLD and (interpolated) SAcC f0, in case its needed  for resynthesis below.
vuvnewSAcC = S.f0_parameter.vuv; % to be the conjunction of WORLD and (interpolated )SAcC voicing, in case its needed  for resynthesis below.
f0tmp = zeros(length(pnewSAcC),1); % this just keeps the SAcC values, doesn't combine with WORLD f0, for SAcC-only analysis
vuvtmp = zeros(length(pnewSAcC),1);
for j = 1:length(tworld) 
    imatch = find(tsacc==tworld(j)); 
    if imatch % if both SAcC and WORLD have a common sample time
        if psacc(imatch)>0   % ... and if SAcC has voicing then
            pnewSAcC(j) = psacc(imatch);
            vuvnewSAcC(j) = 1;
            f0tmp(j) = psacc(imatch);
            vuvtmp(j) = 1;
        end  
    else  % if we need to interpolate (because SAcC is lower sampling rate than WORLD)
        try
           itlow = max(find(tsacc<tworld(j)));
           ithigh = min(find(tsacc>tworld(j)));               
           if psacc(itlow)>0 & psacc(ithigh)>0 %if you're within the sacc voiced region
               pnewSAcC(j) = mean([psacc(itlow) psacc(ithigh)]);% linear interpolation, only within exisiting vuv periods
               vuvnewSAcC(j) = 1;
               f0tmp(j) = pnewSAcC(j);
               vuvtmp(j) = 1;                  
           else  % keep WORLD values for pnewSAcC and vuvnewSAcC, in case you use later for resynthesis
               f0tmp(j) = 0;
               vuvtmp(j) = 0;
           end
        catch % keep WORLD values for pnewSAcC and vuvnewSAcC, in case you use later for resynthesis
           f0tmp(j) = 0;
           vuvtmp(j) = 0;
        end      
    end
end;
S.SAcC.f0 = f0tmp;  
S.SAcC.vuv = vuvtmp; 

%% If available, resample and include DRIFT pitch and vuv in S structure. Same as we did withSAcC
% NOT CURRENTLY USING THIS FOR overwriting pitch values. Confirm match with SAcC
[p1,fileroot,e1] = fileparts(file);
driftfile = [fileroot '-drift.csv'];
if exist(driftfile,'file')
    [num,txt,raw] = xlsread(driftfile);
    [C,ia,ib] = intersect(tsacc,num(:,1));
    f0drift = zeros(size(psacc));
    f0drift(ia) = num(ib,2);
    tdrift = tsacc;
    vuvdrift = zeros(length(tdrift),1);
    vuvdrift(find(f0drift>0)) = 1;
    
    S.drift.f0drift = f0drift;
    S.drift.tdrift = tdrift;
    S.drift.vuvdrift = vuvdrift;
   
    tworld = S.f0_parameter.temporal_positions;
    pnewDrift = S.f0_parameter.f0; %SAcC will overwrite some of these values, so will be the conjunction of WORLD and (interpolated) SAcC f0
    vuvnewDrift = S.f0_parameter.vuv; % to be the conjunction of WORLD and (interpolated )SAcC voicing
    f0tmp = zeros(length(pnewDrift),1); % this just keeps the Drift values, doesn't combine with WORLD f0
    vuvtmp = zeros(length(pnewDrift),1);
    for j = 1:length(tworld) 
        imatch = find(tdrift==tworld(j)); 
        if imatch % if both SAcC and WORLD have a common sample time
            if f0drift(imatch)>0   % ... and if SAcC has voicing then
                pnewDrift(j) = f0drift(imatch);
                vuvnewDrift(j) = 1;
                f0tmp(j) = f0drift(imatch);
                vuvtmp(j) = 1;
            end  
        else  % if we need to interpolate (because SAcC is lower sampling rate than WORLD)
            try
               itlow = max(find(tdrift<tworld(j)));
               ithigh = min(find(tdrift>tworld(j)));               
               if f0drift(itlow)>0 & f0drift(ithigh)>0 %if you're within the sacc voiced region
                   pnewDrift(j) = mean([f0drift(itlow) f0drift(ithigh)]);% linear interpolation, only within exisiting vuv periods
                   vuvnewDrift(j) = 1;
                   f0tmp(j) = pnewDrift(j);
                   vuvtmp(j) = 1;                  
               else  % keep WORLD values for pnewDrift and vuvnewDrift
                   f0tmp(j) = 0;
                   vuvtmp(j) = 0;
               end
            catch % keep WORLD values for pnewDrift and vuvnewDrift
               f0tmp(j) = 0;
               vuvtmp(j) = 0;
            end      
        end
    end;
    S.drift.f0interp = f0tmp;  
    S.drift.vuvinterp = vuvtmp;   
else
    disp(['Could not find file ' driftfile '. It is not required, proceeding without it...']);
end
% Notice we have NOT overwritten the S.f0_parameter.pnewDrift or .vuvnewDrift. We dedide that next...

%% If indicated, use the SAcC-improved WORLD pitch for resynthesis. Otherwise, use WORLD default. 
% However for any samples without SAcC estimate, pnewSAcC and vuvnewSAcC (from above) keep the WORLD f0 and vuv respectively
% otherwise you're left with powerful but (as far as SAcC is concerned)
% unvoiced bits that sound crappy upon resynth.   Build field .f0_parameter    LMM170223
if SAcCresynth % use Ellis 2012 algo to get pitch contours. But have to interpolate f0 values to WORLD temporal positions
    S.f0_parameter.f0 = pnewSAcC; % the conjunction of WORLD and (interpolated) SAcC f0
    S.f0_parameter.vuv = vuvnewSAcC; %the conjunction of WORLD and (interpolated) SAcC voicing    
end



%% Load Gentle data if available, for later analysis
gentlefile = [fileroot '-gentle.csv'];
if exist(gentlefile,'file')
    [Gnum,Gtxt,Graw]=xlsread(gentlefile);
    %Gtimes = Gnum(:,3:4); %assuming start and stop times of words are columns 3 and 4
    Gtimes = round(Gnum.*10000)./10000; %round to nearest 10th of a millisecond to avoid aberrant rounding errors in csv
    fsG = 100; %assumes gentle sampling rate of 100Hz or period of 10ms
    GtimesNoNaN = Gtimes(~isnan(Gtimes)); % Gentle (fall 2019) outputs NaNs for non-aligned words. Ignore those when checking sampling rate.
    if find(mod(GtimesNoNaN,1/fsG))
        error('Gentle sampling rate was assumed to be 100Hz, but csv file times are not multiples of period 10ms');
    end
    S.gentle.Gnum = Gnum;
    S.gentle.Gtxt = Gtxt;
    S.gentle.Gtimes = Gtimes;
    S.gentle.fsG =  fsG;
else
    disp(['Could not find file ' gentlefile '. It is not required, proceeding without it...']);
end

%% plot spectrogram
% sgram = 10*log10(S.spectrum_parameter.spectrogram);
% maxLevel = max(max(sgram));
% figure;
% imagesc([0 S.spectrum_parameter.temporal_positions(end)],[0 fs/2],max(maxLevel-80,sgram));
% axis('xy')
% set(gca,'fontsize',14);
% xlabel('time (s)')
% ylabel('frequency (Hz)');
% title(['WORLD spectrogram ' file])


%% (Re)Synthesize and Save WORLD object
disp('(Re)Synthesizing and saving WORLD/Voxit object')

synth = Synthesis(S.source_parameter, S.spectrum_parameter);
fs_synth = fs;
[filepathstr,fname,fext] = fileparts(file);
if SAcCresynth
    fname = [fname '_SAcC'];
end

% Remove fields that (we think) won't be needed later, to save space/memory
S.f0_parameter = rmfield(S.f0_parameter,'f0_candidates');
S.source_parameter = rmfield(S.source_parameter,'f0_candidates');
S.source_parameter = rmfield(S.source_parameter,'coarse_ap');

if ~spectKeep
    disp('After synthesis, replacing spectrogram with overall power to reduce memory load in later analyses.')
    disp('But this will limit some analyses or modifications!')
    linPower = sum(S.spectrum_parameter.spectrogram./max(max(S.spectrum_parameter.spectrogram)))'; % scale to equalize across recordings
    S.spectrum_parameter.linPower = linPower;
    S.spectrum_parameter = rmfield(S.spectrum_parameter,'spectrogram')
    S.source_parameter = rmfield(S.source_parameter,'aperiodicity');
end

Sfileout = [filepath fname '_Vobj.mat'];
save([Sfileout],'S','-v7.3'); % save WORLD object
synth = synth./max(1,max(abs(synth))*1.01); %normalize for writing to file
synthfileout = [filepath fname '_Wsynth.wav'];
%audiowrite(synthfileout,synth,fs_synth);% save resynthesized sound


% Remove SAcC output file, as we don't use it
SAcCfileout = [filepath fname 'SAcC.mat'];
delete(SAcCfileout);


figure;
plot(S.f0_parameter.temporal_positions,S.f0_parameter.f0);grid on
set(gca,'fontsize',14);
set(gca,'Yscale','log')
xlabel('time (s)')
ylabel('Pitch (Hz)');
filenameNoUnderscores = file;
filenameNoUnderscores(strfind(file,'_')) = ' ';
title(['Pitch: ' filenameNoUnderscores])

