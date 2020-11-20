function [] = voxitPrepWrapper(overwrite,spectKeep)
% Sets up variables for and calls voxitPrep, which writes a
% '_Vobj.mat' file for each audio file
% Make sure folder names only contain non-extended ascii, non-special
% characters, which may break some functions. Filenames with said
% characters will be automatically renamed.
%
%   overwrite   default 1 = re-run all (specified) files
%                       0 = skip any files that already have an associated
%                       Vobj.mat file
%                      
% copyright Lee M. Miller, latest mods 11/2019

if ~exist('overwrite','var')
    overwrite = 1; 
end
if ~exist('spectKeep','var')
    spectKeep = 0; % If you want to keep the spectrogram for later resynthesis, set this variable = 1;
end

filepath = pwd;

% List audio files explicitly
% fileinAudio = {'Bidart_Hollywood.mp3',
%            '01_GuestB.wav'};
% OR, by default work on all audio files in present directory
if ~exist('fileinAudio','var')
   wavfilestruct = dir('./*.wav');
   mp3filestruct = dir('./*.mp3');
   m4afilestruct = dir('./*.m4a');
   mp4filestruct = dir('./*.mp4');
   flacfilestruct = dir('./*.flac');
   oggfilestruct = dir('./*.ogg');
   allfilestruct = [wavfilestruct; mp3filestruct; m4afilestruct; mp4filestruct; flacfilestruct; oggfilestruct];
   fileinAudio = {allfilestruct.name};
end

for f = 1:length(fileinAudio)
    % Rename file if it has special or extended ascii characters, which will break some Matlab functions
    asciiOK = [32 45 46 48:57 65:90 95 97:122];
    if any(~ismember(double(fileinAudio{f}),asciiOK))
         ia = ismember(double(fileinAudio{f}),asciiOK);
         fileinAudioTmp = fileinAudio{f}(ia);
         copyfile(fileinAudio{f},fileinAudioTmp);
         fileinAudio{f} = fileinAudioTmp;
    end
            
    [dummy1,fname,dummy2] = fileparts(fileinAudio{f});
    Sfile = [fname '_Vobj.mat'];
    if overwrite == 1 | ~exist(['./' Sfile],'file')
        disp(['Converting ' fileinAudio{f} ' audio to Voxit object']);
        voxitPrep(filepath,fileinAudio{f},spectKeep);
    end
end

if ~isdeployed
    % archive code
    mfileUsed = which('voxitPrep');
    [status,result]=system(['copy ' mfileUsed ' '  [filepath filesep 'voxitPrep_ARCHIVED.m']]);
end