SAcC_v1.4/README
----------------------------------------
OBJECTIVE:

Do pitch tracking using Subband Autocorrelation Classificiation (SAcC)

----------------------------------------
USAGE:

The MATLAB Compiler Runtime (MCR) function is "SAcC" that takes 
"file_list" and "config_file" as inputs. It follows the SRI Feature 
Extractor (FE) API format. The "config_file" is using srs_config
format developed for Babel Swordfish. For the test, run the following.

./run_SAcC.sh files.list <config_file>

Note that the run_SAcC.sh script must be edited to point to the 
correct <MCRROOT> that is the path of installed MCR or MATLAB. For 
example, our local <MCRROOT> is 
/opt/MATLAB/MATLAB_Compiler_Runtime/v714 .

This package includes some example files to try, with:

./run_SAcC.sh files.list

This will create a directory "out/" containing several 
output files.  They should match the files in "out.ref/", 
which you can check with:

diff -r out.ref out

"files.list" contains the following sample input/output files:
audio/rl001.wav,out/rl001.SAcC.pitch
audio/rl002.wav,out/rl002.SAcC.pitch
audio/sb001.wav,out/sb001.SAcC.pitch
audio/sb002.wav,out/sb002.SAcC.pitch

The "files.list" contains one pair of an input file and an output file
separated by a comma in each line.

The input file can be in various formats, e.g. wav or sph; and the 
calculated features are saved to the output file in ASCII format, 
consisting of lines like:

0 0 0 0.015397
0 1 0 0.018432
0 2 0 0.21075
0 3 0 0.012144
0 4 127.14 0.94357
0 5 127.14 0.99529
0 6 130.86 0.99961
0 7 130.86 1

where the first column is the utterance number (always zero), the 
second column is the frame number (in 10ms units), the third 
column is the pitch in Hz (0 = unvoiced), and the 4th column 
is the raw voicing posterior (before Viterbi smoothing).

The "audio" folder contains the following audio files:
rl001.wav
rl002.wav
sb001.wav
sb002.wav
BP_104.sph

The "out.ref" folder contains the following files:
rl001.SAcC.pitch
rl002.SAcC.pitch
sb001.SAcC.pitch
sb002.SAcC.pitch
BP_104.SAcC.pitch

The "config" folder contains the following four configuration 
definition files:
rats_sr16k_bpo16_sb48_k10.config
   - original, slower version trained on RATS data
rats_sr8k_bpo6_sb24_k10.config
   - faster version trained on RATS, but running at 8 kHz
keele_sr8k_bpo6_sb24_k10.config
   - trained on Keele pitch data with added pink noise
Babelnet_sr8k_bpo6_sb24_k10.config
   - trained on mix of RATS and Keele data for balance

The "aux" directory contains the parameter files:
sub_qtr_rats_h800.wgt
   - the MLP classifier weightsfor the original version
rats_sr8k_bpo6_sb24_k10_aCH_h100.wgt
   - MLP for the faster RATS-trained version
keele_sr8k_bpo6_sr24_k10_h100.wgt
   - MLP weights for the Keele-trained system
sub_qtr_rats_keele_sr8k_bpo6_sb24_k10_ep5_h100.wgt
   - MLP for the RATS-plus-Keele system
PCA_sr16k_bpo16_sb48_k10.mat
   - subband autocorrelation PCA bases for 16 kHz data
PCA_sr8000_bpo6_nchs24_k10.mat
   - PCA bases for 8 kHz / 24 subband data
sub-qtr-rats-dat.norms
   - feature normalization constants for original RATS
tr_rats_sr8k_bpo6_sb24_k10.norms
   - feature normalization constants for faster RATS
tr_keele_rbf_pinknoise_sr8000_bpo6_nchs24_k10.norms
   - feature normalization constants for Keele data
pitch_candidates_freqz.txt
   - mapping from discrete pitch bins to Hz

*

This package also includes SAcCsri, which is the same program 
slightly modified to conform to the SRI conventions; specifically, 
it uses metadb (which must be in the path) to read config files.

----------------------------------------
CONTACT:

Byung Suk Lee, bsl@ee.columbia.edu
Dan Ellis, dpwe@ee.columbia.edu
LabROSA, Columbia University, 2012-08-03
