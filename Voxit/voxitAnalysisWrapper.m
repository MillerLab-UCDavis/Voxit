function [T] = voxitAnalysisWrapper(fileinVobj)
% Sets up variables for and calls voxitAnalysis, which by default runs on all
% '_Vobj.mat' files in this directory, then outputs a csv of select
% results
%
% copyright Lee M. Miller, latest mods 11/2019

% List 'Vobj.mat' files explicity
%fileinVobj =       {'Bidart_Hollywood_Wobj.mat',
%                '01_GuestB_Wobj.mat'};% Find all WORLD object files
% OR by default, find all of them
if ~exist('fileinVobj','var')
   lstruct=dir(['.' filesep '*_Vobj.mat']);
   fileinVobj = {lstruct.name};
end

% List all measures that you want output to csv file
measureNames = {'f0Mean',...
            'f0Range95percent',...
            'f0Entropy',...
            'f0MeanAbsVelocity',...
            'f0MeanAbsAccel',...
            'PauseCount',...
            'PauseRate',...
            'PauseDutyCycle',...
            'MeanPauseDuration',...
            'ComplexityAllPauses',...
            'ComplexitySyllables',...
            'ComplexityPhrases',...
            'IntensitySegmentRange95percent',...
            'IntensityMeanAbsVelocity',...
            'IntensityMeanAbsAccel',...
            'Dynamism'};

overwrite = 1; %Overwrite existing WORLD object file with additional field for analysis results
RowName = cell(length(fileinVobj),1); % files are row names in csv output

for f = 1:length(fileinVobj)
   disp(['Analyzing ' fileinVobj{f}]);
   
   [S] = voxitAnalysis(fileinVobj{f},overwrite); % this is where all the action happens
   
   a = S.analysis;
   RowName = {fileinVobj{f}};  
  
   measureValues = []; %
   for i=1:length(measureNames)
       measureValues(i) = a.(measureNames{i});
   end
   
   if f==1 % duh I don't know how to initialize a table, thus the "if" statement
       T = array2table(measureValues,'VariableNames',measureNames,'RowNames',RowName);
   else
       Tnew = array2table(measureValues,'VariableNames',measureNames,'RowNames',RowName);
       T = [T; Tnew];
   end
   
   %if isdeployed        % Write pitch and speech vs no speech data to comma-delimited text file
       DataArray = array2table([S.analysis.t' S.analysis.f0 S.analysis.sps],'VariableNames',{'time_s','pitch_hz', 'speech_no_speech'}); 
       [dummy1,fname,dummy2] = fileparts(fileinVobj{f});
       i = strfind(fname,'_Vobj');
       DataFile = [fname(1:i-1) '_DataArray.csv'];
       writetable(DataArray,DataFile);
   %end
end

T.Properties.DimensionNames{1}='file';

% Write table to comma-delimited text file
p = pwd;
ip = findstr(p,filesep);
localdir = p(ip(end)+1:end);
resultsFile = ['voxitResults_' localdir '.csv'];
writetable(T,resultsFile,'WriteRowNames',true)

% archive code
if ~isdeployed
    filepath = pwd;
    mfileUsed = which('voxitAnalysis');
    [status,result]=system(['copy ' mfileUsed ' '  [filepath filesep 'voxitAnalysis_ARCHIVED.m']]);
end

%% Extra, to add if we pull in gentle file to the vocAnal
%    %gentlefile = [gentleDir filein{f}(1:strfind(filein{f},'_Sobj')-1) 'gentle.csv']; %might use this in future   
%    if exist('gentlefilein','var')
%        [S] = WORLDvocAnal(fileinVobj{f},overwrite,gentlefilein{f});
%    else
%        [S] = WORLDvocAnal(fileinVobj{f},overwrite);
%    end
