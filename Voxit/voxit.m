function []=voxit(datadir)
% Launcher for all of Voxit (both the prep and analysis). Necessary to
% package a single standalone version.
%
% INPUTS
%    datadir:  directory name with sound files to be analyzed.
%              May be relative or absolute path. Default: pwd
%
% OUTPUTS
% (none)
%
% copyright Lee M. Miller, latest mods 10/2020

if ~exist('datadir','var')
    datadir = pwd;
end

% Change directory to the data directory, with the sound files
cd(datadir);

% Run the WORLD voxit prep function
voxitPrepWrapper;

% Run the voxit analysis
voxitAnalysisWrapper;