# VOXIT: Vocal Analysis Tools
Automated analysis of vocal parameters in audio recordings, by [Lee M. Miller](https://millerlab.faculty.ucdavis.edu/) in collaboration with [Marit J. MacArthur](https://writing.ucdavis.edu/people/mjmacart/) and Robert Ochshorn (author of [Gentle](http://lowerquality.com/gentle/) and [Drift](http://drift3.lowerquality.com)). Standalone executable does NOT require a Matlab license; using the full editable codebase does.

<h2>How to Set Up Standalone VOXIT (without Matlab) on your Machine</h2>
Whether or not you have Matlab, you can install and use Voxit on your machine! For now, it works on Windows, but soon on Mac or Linux as well. Note that you may need administrative rights to install and/or run it (e.g. on Windows 10, "Run as administrator", or on Mac/Linux, "sudo"). 

1) From the repo ./Voxit folder, download the latest version of the VoxitStandaloneInstaller_.exe file. 

2) Run the installer file, and proceed through the popups accepting all defaults (except on Windows you sould have the option to create a desktop shortcut). This step may take awhile because it needs to download the Matlab Runtime Environment - the piece of Matlab that allows you to run Voxit without a Matlab license  [legally!](https://www.mathworks.com/products/compiler/matlab-runtime.html)).

3) Run Voxit, which pops up a window for you to choose the directory with your audio files. (This step may take a few minutes the first time you do it in a session, as the Matlab Runtime needs to start in the background... be patient). Pick a directory and wait for the magic to happen...  

4) Open the new voxitResults * .csv file with the analysis values for every audio file.\
\
You can also view the pitch estimates and other raw data used for analysis in each * DataArray.csv file.\
\
Finally, Voxit also saves Vobj.mat files with ALL the analysis values, as well as the pitch estimates and much MUCH more, for further exploration within Matlab (if you obtain a license) or  in the free program [Octave](https://www.gnu.org/software/octave/index).


<h2>How to Set Up VOXIT IN MATLAB on your Machine</h2>
If you have a Matlab license and want access to all the code, you can get started in a few easy steps:

1) Make a local directory or folder to put the code, in any sensible place like C:\Users\you\Voxit, and and remember where it is. In the following instructions, we'll call this your ~/Voxit directory.

2) Download Voxit by clicking the green "Clone or Download" button here on the Voxit Github page, and click "Download ZIP". Save in any convenient place and unzip it. When you unzip the file, you'll have a "Voxit-Master" directory with three directories within it:\
-EllisPitchTracker\
-Voxit\
-WORLD\
\
(Voxit is the part that we develop. [WORLD](http://www.kki.yamanashi.ac.jp/~mmorise/world/english/download.html) is Masanori Morise's wonderful speech analysis-synthesis system, for Matlab (which follows on Hideki Kawahara's TANDEM-STRAIGHT). EllisPitchTracker is Dan Ellis' [Subband Autocorrelation Classificiation (SAcC) pitch tracker](https://github.com/dpwe/SAcC), gently modified to work with Voxit)

3) MOVE the three directories (Voxit, EllisPitchTracker, and WORLD) from Voxit-Master to the ~/Voxit directory you made in step 1.

4) Compile the core SAaC pitch tracker function autocorr.c into a mex file: From within Matlab, in the EllisPitchTracker directory, enter\
  *mex autocorr.c*.\
  This should create a mex file, e.g. autocorr.mexw64
If you have trouble, check your compiler in Matlab:\
  myCCompiler = mex.getCompilerConfigurations('C','Selected')
		and get one [here](https://www.mathworks.com/support/compilers.html) if you need one.

5) So far, Matlab may not know where to find your vocal analysis code. To avoid having to tell it every time you restart, you should add it to your startup.m file (saved anywhere on your default matlab path). At the command line, type\
  open startup.m\
If you don't have one yet, use the Matlab editor to make one where Matlab will look for it e.g. in your matlab installation folder. https://www.mathworks.com/help/matlab/ref/startup.html \
In startup.m, which is just a text file, simply add lines like this with path pointing to your ~/Voxit folder:\
addpath('C:\Users\you\Voxit\Voxit');\
addpath('C:\Users\you\Voxit\WORLD');\
addpath('C:\Users\you\Voxit\EllisPitchTracker');\
\
At the Matlab command prompt >> , type *startup* and enter, so Matlab learns the Voxit paths you just added (or just restart Matlab, which runs startup.m automatically).\
\
Congratulations, you're done setting up!  


<h2>How to Use VOXIT</h2>
<h2For each set of audio files you want to analyze:</h2>

i) *Within Matlab*, navigate to the directory containing the audio files, and type *voxitPrepWrapper*, at the >> command prompt, then Enter. Wait until it's finished and you see the >> prompt again. Be patient, this step will take longer than the next one. You should now have _*Vobj.mat_ file for each of your audio files. This _*Vobj.mat_ file contains the WORLD analysis of the audio, with some other bits.

ii) Then enter *voxitAnalysisWrapper* and wait until it's done, and you see the >> prompt again. Although you didn't notice, all your vocal analysis results are now appended in the _*Vobj.mat* file.

iii) There should now be an output csv file in the audio file directory, with all your analysis results! View it with Excel or similar. To help you understand and interpret the measures, see the articles below, under Acknowledgments.


<h2>ADVANCED USERS</h2>
The default csv only contains a subset of the analyzed measures. For a complete list, load the Vobj.mat file and list the structure fields in *S.analysis*. You can add any of these measures to the csv output (provided they are scalar values) by going into voxitAnalysisWrapper and editing the variable *measureNames* with your desired field names.

___________________________________________________________________
<h2>ACKNOWLEDGMENTS:</h2>
When you cite Voxit -- and please do so -- include the articles:
[MacArthur MJ, Zellou G, Miller LM (2018)](http://culturalanalytics.org/2018/04/beyond-poet-voice-sampling-the-non-performance-styles-of-100-american-poets/). Beyond Poet Voice: Sampling the (Non-) Performance Styles of 100 American Poets. Journal of Cultural Analytics DOI: 10.7910/DVN/OJI8NB. and our [Stanford Arcade piece](https://arcade.stanford.edu/content/after-scansion-visualizing-deforming-and-listening-poetic-prosody/). These also give some background, motivation, and validation of the approach for those who want to learn more.<br/>
<br/>
When you cite the Ellis SAaC algorithm --  and please do so --  include the article:
Lee, B.S. and D.P.W. Ellis. Noise robust pitch tracking by subband autocorrelation classification”. in Interspeech. 2012. Portland. Minor changes were required for SAaC to work with Voxit, and these are noted in the code.<br/>
<br/>
Please also cite WORLD. As per M. Morise's [request](https://github.com/mmorise/World) on Github, please include the following:
[1] M. Morise, F. Yokomori, and K. Ozawa: WORLD: a vocoder-based high-quality speech synthesis system for real-time applications, IEICE transactions on information and systems, vol. E99-D, no. 7, pp. 1877-1884, 2016.
[2] M. Morise: D4C, a band-aperiodicity estimator for high-quality speech synthesis, Speech Communication, vol. 84, pp. 57-65, Nov. 2016. http://www.sciencedirect.com/science/article/pii/S0167639316300413<br/>
<br/>

**The development of Voxit has been generously supported by an ACLS Digital Innovations Fellowship and by Tools for Listening to Text-in-Performance, a NEH-funded grant project: https://textinperformance.soc.northwestern.edu/. Its continued development is supported by SpokenWeb, a SSHRC-funded grant project: https://spokenweb.ca/.**

<h2>LICENSES:</h2>
The SAcC code is use with permission from Dan Ellis and respects the [BSD 2 Clause license](https://opensource.org/licenses/BSD-2-Clause/)

The version of WORLD cloned for use in Voxit is presently v0.2.3 for Matlab and can be found [here](http://www.kki.yamanashi.ac.jp/~mmorise/world/english/download.html), respecting the license terms specified in ./WORLD/DOC/copying.txt and [here](https://github.com/mmorise/World/blob/master/LICENSE.txt).  


