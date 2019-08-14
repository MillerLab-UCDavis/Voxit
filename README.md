# VOXIT: Vocal Analysis Tools
Matlab functions to analyze vocal parameters, by Lee M. Miller (https://millerlab.faculty.ucdavis.edu/) in collaboration with Marit J. MacArthur and Robert Ochshorn (author of Gentle and Drift http://www.rmozone.com/).

INSTRUCTIONS\
Get started analyzing vocal recordings in a few easy steps:

1) Obtain WORLD, Masanori Morise's speech analysis system, for Matlab (which follows on Hideki Kawahara's
TANDEM-STRAIGHT), here:\
http://www.kki.yamanashi.ac.jp/~mmorise/world/english/download.html \
Put WORLD in a sensible folder, name it whatevery you want - let's call it "vocalcode" - and remember where it is.

2) Download the Matlab version of Dan Ellis' Subband Autocorrelation Classificiation (SAcC) pitch tracker.
https://github.com/dpwe/SAcC 

For convenience, put it in the same "vocalcode" folder as WORLD, and please name the SAcC folder "EllisPitchTracker"
First, rename the function in EllisPitchTracker "audioread.m" to be something else, because it conflicts with a matlab function.
e.g. rename it to be "audioreadELLIS.m"
Within the EllisPitchTracker folder, RENAME folder "aux" to be "waux", because 

3) Download from the Vocal_Analysis_Tools repo the two directories:\
codeToReplaceInEllisPitchTracker\
codeVocalAnalyses\
Once again, for convenience, put them in the same "vocalcode" folder as WORLD and SAcC

4) From the Github directory codeToReplaceInEllisPitchTracker, in your SAcC directory:
REPLACE the three functions:
autocorrelogram.m\
autocorrSAcC.m\
SAcC_main.m

and ADD the directory waux (this just replicates Ellis' "aux" directory, but Windows has a big problem with directories called "aux")

5) Compile the core SAaC pitch tracker function autocorr.c into a mex file:
download it from here https://github.com/dpwe/calc_sbpca/blob/master/autocorr.c and put it in the Ellis directory
From within matlab, in the SAaC directory, enter\
  mex autocorr.c. This should create a mex file, e.g. autocorr.mexw64
If you have trouble, check your compiler in Matlab:\
  myCCompiler = mex.getCompilerConfigurations('C','Selected')
		and get one if you need to https://www.mathworks.com/support/compilers.html

7) So far, Matlab may not know where to find your vocal analysis code. To avoid having to tell it every time you restart, you can add it to a startup.m file (saved anywhere on your default matlab path). At the command line, try\
  open startup.m\
If you don't have one, make one e.g. your matlab installation folder. https://www.mathworks.com/help/matlab/ref/startup.html \
In startup.m, which is just a text file, simply a line like this with path pointing to wherever you put your "vocalcode" folder: addpath(genpath('C:\users\me\importantStuff\vocalcode'));


You're done setting up!  Now for each set of audio files you want to analyze:\
i) Within Matlab, go to the directory containing the audio files, and run WORLDaudio2objectWrapper, followed by
	WORLDvocAnalWrapper\
ii) Enjoy the vocal analysis values in the output csv file!

___________________________________________________________________
Acknowledgments:

When you cite the Ellis SAaC algorithm, please include the article:
Lee, B.S. and D.P.W. Ellis. Noise robust pitch tracking by subband autocorrelation classification”. in Interspeech. 2012. Portland.

As per M. Morise's request on Github https://github.com/mmorise/World, when you cite the latest version of WORLD in your article, please include the following:
[1] M. Morise, F. Yokomori, and K. Ozawa: WORLD: a vocoder-based high-quality speech synthesis system for real-time applications, IEICE transactions on information and systems, vol. E99-D, no. 7, pp. 1877-1884, 2016.
[2] M. Morise: D4C, a band-aperiodicity estimator for high-quality speech synthesis, Speech Communication, vol. 84, pp. 57-65, Nov. 2016. http://www.sciencedirect.com/science/article/pii/S0167639316300413


