function [] = SAcCsri(files_list, config_file)
% Perform pitch tracking using Subband Autocorrelation Classification
% (SAcC) pitch tracker
%
% USAGE:   SAcCsri(files_list, config_file)
%
% ARGS:    files_list = mandatory, list (one per line) of audio file in any
%                   format and the output file in ascii, separated by a comma
%
%          config_file = optional, use config.default if not specified
%
% OUTPUT:  output is saved in ./out/ folder (with corresponding input filenames)
%
% OPTION:    -h = usage instructions will be displayed with all config items explanation
%
% This version uses SRI's metadb script to read the configuration file
%
%% [2012-05-30] Byung Suk Lee bsl@ee.columbia.edu

if nargin < 1; files_list = '-h'; end
if nargin < 2; config_file = ''; end

IS_SRI = 1;

% Vector off to the actual routine
SAcC(files_list, config_file, IS_SRI);
