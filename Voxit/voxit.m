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

% open gui for user to specify path
selpath = uigetdir

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

catch ME
  fprintf(1, 'ERROR:\n%s\n', ME.message);
end
diary off

disp("Done!")