HOW TO CREATE A STANDALONE VOXIT APP

REQUIREMENTS:
1) a working version of Voxit (including your compiled autocorr mexfile, which will be platform-specific!)
2) Matlab Compiler license 

INSTRUCTIONS
* read this, esp the section about using applicationCompiler, so  you understand the issues
https://www.mathworks.com/help/compiler/create-and-install-a-standalone-application-from-matlab-code.html
* put your entire matlab startup.m script within a conditional: if ~isdeployed ... end, to avoid compiling paths that don't exist on client
* Start applicationCompiler from the command line
* In MAIN FILE, choose your voxit.m. The “Files required..” pane below should populate with dependencies.
* ensure Radio button “Runtime downloaded from Web” is selected, and type “VoxitInstaller_v1.0” in the text field, replacing version number with whatever you put below in Application information
* in Settings, choose folders to save the output. You can leave the default logfile and folder names but just choose your desired local path
* Under Application Information
	* fill out "Voxit" in the first line, including version, and whatever else you like below
	* just to the left of your "Voxit" (first line), click on the icon; click "Select icon", choose "VoxitIcon1.jpg" from your voxit repo /Development folder, then click "Save and use"
	* set custom splash screen, and insert VoxitSplashScreen1.jpg from your voxit repo /Development folder
* Under Additional installer options, Select custom logo and insert VoxitLogo1.jpg from your voxit repo /Development folder
* In the “Files required for your application to run, add the following:
	* \EllisPitchTracker\waux\pca_sr8k_bpo6_sb24_k10.mat
	* \EllisPitchTracker\waux\py_pitch_candidates_freqz.txt
	* \EllisPitchTracker\waux\py_sub_qtr_rats_keele_sr8k_bpo6_sb24_k10_ep5_h100.wgt
	* \EllisPitchTracker\waux\py_tr_keele_rbf_pinknoise_sr8000_bpo6_nchs24_k10.norms
	* \EllisPitchTracker\conf\rats_sr8k_bpo6_sb24_k10.config
* Under Additional runtime settingS
	* for Windows, uncheck “Do not display the Windows Command Shell…”
	* (optional) check Create log file, and call it something like “VoxitLog.txt”, as this might help debugging

* In the upper right, click Package
	* you should now find the installer executable in the folder you designated in Settings, /for_redistribution
* In the upper left, click Save and save the project anywhere sensible - that way you don't have to do all this next time!
* Run the executable to install Voxit!

