function [T] = WORLDvocAnalWrapper(fileinWobj)
% Sets up variables for and calls WORLDvocAnal, which by default runs on all
% '_Wobj.mat' files in this directory, then outputs a csv of select
% results
%
% copyright Lee M. Miller 2016, latest mods 01/2019

% List 'Wobj.mat' files explicity
%fileinWobj =       {'Bidart_Hollywood_Wobj.mat',
%                '01_GuestB_Wobj.mat'};% Find all WORLD object files
% OR by default, find all of them
if ~exist('fileinWobj','var')
   lstruct=dir('./*_Wobj.mat');
   fileinWobj = {lstruct.name};
end

% List all measures that you want output to csv file
measureNames = {'f0Mean',...
            'f0Range2sd',...
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
            'IntensitySegmentMeanSD',...
            'IntensityMeanAbsVelocity',...
            'IntensityMeanAbsAccel',...
            'Dynamism'};

overwrite = 1; %Overwrite existing WORLD object file with additional field for analysis results
RowName = cell(length(fileinWobj),1); % files are row names in csv output

for f = 1:length(fileinWobj)
   disp(['Analyzing ' fileinWobj{f}]);
   
   [S] = WORLDvocAnal(fileinWobj{f},overwrite); % this is where all the action happens
   
   a = S.analysis;
   RowName = {fileinWobj{f}};  
  
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
   
end

T.Properties.DimensionNames{1}='file';

% Write table to comma-delimited text file
writetable(T,'vocAnalResults.csv','WriteRowNames',true)



%% Extra, to add if we pull in gentle file to the vocAnal
%    %gentlefile = [gentleDir filein{f}(1:strfind(filein{f},'_Sobj')-1) 'gentle.csv']; %might use this in future   
%    if exist('gentlefilein','var')
%        [S] = WORLDvocAnal(fileinWobj{f},overwrite,gentlefilein{f});
%    else
%        [S] = WORLDvocAnal(fileinWobj{f},overwrite);
%    end
