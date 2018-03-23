# Vocal_Analysis_Tools
Matlab functions to analyze vocal parameters, in collaboration with Marit MacArthur.

Get started analyzing vocal recordings in a few easy steps:

1) Obtain TANDEM-STRAIGHT, Hideki Kawahara's speech analysis system for Matlab, here:
http://www.wakayama-u.ac.jp/~kawahara/STRAIGHTadv/index_e.html

2) Download the Matlab version of Dan Ellis' Subband Autocorrelation Classificiation (SAcC) pitch tracker.
https://github.com/dpwe/SAcC

3) Download from the Vocal_Analysis_Tools repo the three directories:
codeToReplaceInEllisPitchTracker, codeDependencies, and codeVocalAnalyses. Note that codeDependencies will eventually be replaced. At the moment they contain functions available on Matlab Central or the ERPlab toolbox.

4) From directory codeToReplaceInEllisPitchTracker, replace the three functions in the SAcC directory:
autocorrelogram.m
autocorrSAcC.m
SAcC_main.m

5) Compile the core SAaC pitch tracker function autocorr.c into a mex file:
download it from here https://github.com/dpwe/calc_sbpca/blob/master/autocorr.c and put it in the SAaC directory
From within matlab, in the SAaC directory, enter >> mex autocorr.c. This should create a mex file, e.g. autocorr.mexw64
If you have trouble, check your compiler in Matlab:>> myCCompiler = mex.getCompilerConfigurations('C','Selected')
		and get one if you need to https://www.mathworks.com/support/compilers.html

6) Update the paths at the beginning of SAcCWrapper.m and STRAIGHTaudio2objectWrapper.m to reflect your own directory organization.

7) Run STRAIGHTaudio2objectWrapper.m on your audio files, followed by vocAnalWrapper.m. 

8) Enjoy the vocal analysis values in the output csv file
