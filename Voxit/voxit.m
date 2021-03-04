function []=voxit
% Launcher for all of Voxit (both the prep and analysis). Necessary to
% package a single standalone version.
%
% INPUTS
%  (none)
%
% OUTPUTS
% (none)
%
% copyright Lee M. Miller, latest mods 10/2020
if isdeployed
    set(0,'DefaultUicontrolFontName','Arial'); %for cross-platform compatibility, these apply only during this matlab session
    set(0,'defaultUipanelFontName','Arial');
    set(0,'DefaultUitableFontName','Arial');
    set(0,'defaultAxesFontName','Arial');
    set(0,'defaultTextFontName','Arial');
end

% open gui for user to specify path
selpath = uigetdir([],'Select folder containing audio files')

% Change directory to the data directory, with the sound files
cd(selpath);

diary % This statement and the entire try/catch block
                        % for debugging: to write all output to logfile 
                        % even in event of a crash.
try
    
    % Run the WORLD voxit prep function
    voxitPrepWrapper;

    % Run the voxit analysis
    voxitAnalysisWrapper;

    disp('Done!')
    waitbar(1,'Done!');
catch ME
  fprintf(1, 'ERROR:\n%s\n', ME.message);
  waitbar(1,'Something went wrong. Check error in file diary');
end
diary off


