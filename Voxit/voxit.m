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

% Run the WORLD voxit prep function
voxitPrepWrapper;

% Run the voxit analysis
voxitAnalysisWrapper;