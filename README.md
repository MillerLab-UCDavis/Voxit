# VOXIT: Vocal Analysis Tools
Functions to analyze vocal parameters in (mostly) Matlab, by Lee M. Miller (https://millerlab.faculty.ucdavis.edu/) in collaboration with [Marit J. MacArthur](https://writing.ucdavis.edu/people/mjmacart/) and Robert Ochshorn (author of Gentle and Drift http://www.rmozone.com/).

INSTRUCTIONS\
Get started analyzing vocal recordings in a few easy steps:

1) Make a local directory or folder to put the code, in any sensible place like C:\Users\you\Voxit, and and remember where it is. In the following instructions, we'll call this your ~/Voxit directory.

2) Download Voxit by clicking the green "Clone or Download" button here on the Voxit Github page, and click "Download ZIP". Save in any convenient place and unzip it. When you unzip the file, you'll have a "Voxit-Master" directory with three directories within it:\
EllisPitchTracker
Voxit
WORLD\
\
(Voxit is the part that we develop. [WORLD](http://www.kki.yamanashi.ac.jp/~mmorise/world/english/download.html) is Masanori Morise's wonderful speech analysis system, for Matlab (which follows on Hideki Kawahara's TANDEM-STRAIGHT). EllisPitchTracker is Dan Ellis' [Subband Autocorrelation Classificiation (SAcC) pitch tracker](https://github.com/dpwe/SAcC), gently modified to work with Voxit)\

3) MOVE the three directories (Voxit, EllisPitchTracker, and WORLD) from Voxit-Master to the ~/Voxit directory you made in step 1.

4) Compile the core SAaC pitch tracker function autocorr.c into a mex file: From within Matlab, in the EllisPitchTracker directory, enter\
  *mex autocorr.c*. This should create a mex file, e.g. autocorr.mexw64
If you have trouble, check your compiler in Matlab:\
  myCCompiler = mex.getCompilerConfigurations('C','Selected')
		and get one [here](https://www.mathworks.com/support/compilers.html) if you need one.

5) So far, Matlab may not know where to find your vocal analysis code. To avoid having to tell it every time you restart, you should add it to your startup.m file (saved anywhere on your default matlab path). At the command line, type\
  open startup.m\
If you don't have one yet, use the Matlab editor to make one where Matlab will look for it e.g. in your matlab installation folder. https://www.mathworks.com/help/matlab/ref/startup.html \
In startup.m, which is just a text file, simply add lines like this with path pointing to your ~/Voxit folder:\
addpath('C:\Users\you\Voxit\Voxit');\
addpath('C:\Users\you\Voxit\WORLD');\
addpath('C:\Users\you\Voxit\EllisPitchTracker');

At the Matlab command prompt >> , type *startup"* and enter, so Matlab learns the Voxit paths you just added (or just restart Matlab, which runs startup.m automatically).


You're done setting up!  Now for each set of audio files you want to analyze:\
i) *Within Matlab*, navigate to the directory containing the audio files, and type *voxitPrepWrapper*, at the >> command prompt, then Enter. Wait until it's finished and you see the >> prompt again. Be patient, this step will take longer than the next one. Then enter *voxitAnalysisWrapper* and wait until it's done, and you see the >> prompt again.  
ii) There should now be an output csv file in the audio file directory, with all your analysis results! View it with Excel or similar.

ADVANCED USERS\
The default csv only contains a subset of the analyzed measures. For a complete list, load the Vobj.mat file and list the structure fields in *S.analysis*. You can add any of these measures to the csv output (provided they are scalar values) by going into voxitAnalysisWrapper and editing the variable *measureNames* with your desired field names.

___________________________________________________________________
ACKNOWLEDGMENTS:\
When you cite Voxit -- and please do so -- include the article:
[MacArthur MJ, Zellou G, Miller LM (2018). Beyond Poet Voice: Sampling the (Non-) Performance Styles of 100 American Poets. Journal of Cultural Analytics DOI: 10.7910/DVN/OJI8NB.](http://culturalanalytics.org/2018/04/beyond-poet-voice-sampling-the-non-performance-styles-of-100-american-poets)/

When you cite the Ellis SAaC algorithm --  and please do so --  include the article:
Lee, B.S. and D.P.W. Ellis. Noise robust pitch tracking by subband autocorrelation classification”. in Interspeech. 2012. Portland. Minor changes were required for SAaC to work with Voxit, and these are noted in the code.

Please also cite WORLD. As per M. Morise's request on [Github](https://github.com/mmorise/World), please include the following:
[1] M. Morise, F. Yokomori, and K. Ozawa: WORLD: a vocoder-based high-quality speech synthesis system for real-time applications, IEICE transactions on information and systems, vol. E99-D, no. 7, pp. 1877-1884, 2016.
[2] M. Morise: D4C, a band-aperiodicity estimator for high-quality speech synthesis, Speech Communication, vol. 84, pp. 57-65, Nov. 2016. http://www.sciencedirect.com/science/article/pii/S0167639316300413

LICENSES:\
The SAcC code is use with permission from Dan Ellis and respects the [BSD 2 Clause license](https://opensource.org/licenses/BSD-2-Clause)

The version of WORLD cloned for use in Voxit is presently v0.2.3 for Matlab and can be found [here](http://www.kki.yamanashi.ac.jp/~mmorise/world/english/download.html), respecting the license terms specified in ./WORLD/DOC/copying.txt and [here](https://github.com/mmorise/World/blob/master/LICENSE.txt).  


