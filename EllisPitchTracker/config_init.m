function [P,D] = config_init()
% [P,D] = config_init()
%   Initialize P (parameter struct) and D (bindings definition) for
%   config system.  P is empty, D is preset with srcdir as the
%   directory containing this script.
% 2012-09-13 Dan Ellis dpwe@ee.columbia.edu

P = struct();
D = containers.Map();

% setup CWD
mycwd = fileparts(which('config_init'));
D('srcdir') = mycwd;



