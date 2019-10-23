# VOXIT: Vocal Analysis Tools
Matlab functions to analyze vocal parameters, by Lee M. Miller (https://millerlab.faculty.ucdavis.edu/) in collaboration with Marit J. MacArthur and Robert Ochshorn (author of Gentle and Drift http://www.rmozone.com/).

INSTRUCTIONS\
Get started analyzing vocal recordings in a few easy steps:

1) Make a local directory or folder to put the code, in any sensible place like C:\Users\you\Voxit, and and remember where it is. In the following instructions, we'll call this your ~/Voxit directory.

2) Obtain WORLD, Masanori Morise's speech analysis system, for Matlab (which follows on Hideki Kawahara's
TANDEM-STRAIGHT), here:\
http://www.kki.yamanashi.ac.jp/~mmorise/world/english/download.html \
The WORLD directory will be called something like world-0.2.1_4_matlab. Rename this to be "WORLD" and put this *inside* your ~/Voxit directory.

3) Download the Matlab version of Dan Ellis' Subband Autocorrelation Classificiation (SAcC) pitch tracker.
https://github.com/dpwe/SAcC \
Unzip the download.
If you get an error unzipping the "aux" folder, click "Skip" (Windows forbids directories with that name).
If you don't get an error during unzipping, then DELETE the "aux" folder. \

Put this SAcC directory inside vour ~/Voxit directory along with WORLD, and  rename the SAcC folder "EllisPitchTracker"
Also RENAME the function in EllisPitchTracker "audioread.m" to be something else, because it conflicts with a Matlab function.
e.g. rename it to be "audioreadELLIS.m"

4) Download from the Voxit repo the two directories:
codeToReplaceInEllisPitchTracker
Voxit
Once again, put these in your ~/Voxit directory alongside your WORLD and EllisPitchTracker directories

5) From the Github directory codeToReplaceInEllisPitchTracker, update your EllisPitchTracker directory:
REPLACE the three functions:
autocorrelogram.m\
autocorrSAcC.m\
SAcC_main.m
And MOVE the "waux" folder from your codeToReplaceInEllisPitchTracker download into the EllisPitchTracker directory.

6) Compile the core SAaC pitch tracker function autocorr.c into a mex file:
download it from here https://github.com/dpwe/calc_sbpca/blob/master/autocorr.c and put it in the EllisPitchTracker directory
From within matlab, in the EllisPitchTracker directory, enter\
  mex autocorr.c. This should create a mex file, e.g. autocorr.mexw64
If you have trouble, check your compiler in Matlab:\
  myCCompiler = mex.getCompilerConfigurations('C','Selected')
		and get one if you need to https://www.mathworks.com/support/compilers.html

7) So far, Matlab may not know where to find your vocal analysis code. To avoid having to tell it every time you restart, you can add it to a startup.m file (saved anywhere on your default matlab path). At the command line, type\
  open startup.m\
If you don't have one, use the Matlab editor to make one where Matlab will look for it e.g. in your matlab installation folder. https://www.mathworks.com/help/matlab/ref/startup.html \
In startup.m, which is just a text file, simply add lines like this with path pointing to wherever you put your ~/Voxit folder: addpath('C:\Users\you\Voxit\Voxit');
addpath('C:\Users\you\Voxit\WORLD');
addpath('C:\Users\you\Voxit\EllisPitchTracker');


You're done setting up!  Now for each set of audio files you want to analyze:\
i) Within Matlab, go to the directory containing the audio files, and run VoxitPrepWrapper, followed by
	VoxitWrapper\
ii) Enjoy the vocal analysis values in the output csv file!

___________________________________________________________________
Acknowledgments:

When you cite the Ellis SAaC algorithm, please include the article:
Lee, B.S. and D.P.W. Ellis. Noise robust pitch tracking by subband autocorrelation classification”. in Interspeech. 2012. Portland.

As per M. Morise's request on Github https://github.com/mmorise/World, when you cite the latest version of WORLD in your article, please include the following:
[1] M. Morise, F. Yokomori, and K. Ozawa: WORLD: a vocoder-based high-quality speech synthesis system for real-time applications, IEICE transactions on information and systems, vol. E99-D, no. 7, pp. 1877-1884, 2016.
[2] M. Morise: D4C, a band-aperiodicity estimator for high-quality speech synthesis, Speech Communication, vol. 84, pp. 57-65, Nov. 2016. http://www.sciencedirect.com/science/article/pii/S0167639316300413


