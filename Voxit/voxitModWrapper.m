function [] = voxitModWrapper(overwrite)
% Modify the vocal parameters in Voxit '_Vobj.mat' files and resynthesize
%% To create Voxit object file, run VoxitPrepWrapper
%filein = 'Vobj.mat';
%
% IMPORTANT: the resynthesis requires the spectrogram to be kept
% in the Voxit structure, so you must run voxitPrep with spectKeep = 1 (this increases memory
% load significantly for voxitAnalysis, as well as takes up a lot more disk space);
% copyright Lee M. Miller 2019, latest mods 10/2019

if ~exist('overwrite','var')
    overwrite = 1; 
end


%% Name your STRAIGHT object files to work on
%% by wildcard
lstruct=dir('./*Vobj.mat');
filein = {lstruct.name};

% or by name
% filein = {'AprilIstheCruelestMonth_StrObj.mat','HillaryTrumpTemperament_StrObj.mat','GluckWildIrisItIsTerrible_StrObj.mat'...
%       'MullenPresentTenseNowThatMyEars_StrObj.mat','RichToHaveYouListen_StrObj.mat',...
%       'YeatsIWillArise_StrObj.mat'};
%filein = {'AprilIstheCruelestMonth_Vobj.mat'};


%% Choose your manipulation
%manipulation = {'flat','flip'};
%manipulation = {'flat'};
%manipulation = {'stress2pitch'};
%manipulation = {'pitchNsize'};
manipulation = {'flat','flip','MFM','pitchNsize'};
%rmsnorm = 0.05;
rmsnorm = 0.1;

%% Run manipulation on all files
for f = 1:length(filein)
    for m = 1:length(manipulation)
        [newsound,fs] = voxitMod(filein{f},manipulation{m},rmsnorm);
    end
end

