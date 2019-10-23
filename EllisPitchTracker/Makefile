PROG=SAcC
VER=$(shell grep '^\s*VERSION' ${PROG}.m | sed -e 's/[^0-9.]*\([0-9.]*\)[^0-9.]*/\1/')
DST=${PROG}-v${VER}
#TAR=${DST}.tgz
ZIP=${DST}.zip

ARCH=$(shell ./matlab_arch.sh)
arch=$(shell ./matlab_arch.sh 1)

PROGARCH=${PROG}_${ARCH}
#PROGARCH=${PROG}_${arch}
#PROGARCH=${PROG}
PROGPRJ=${PROG}_prj

# modified version of binary for SRI's config system
PROGSRI=SAcCsri
PROGSRIPRJ=${PROGSRI}_prj
PROGSRIARCH=${PROGSRI}_${ARCH}

# trainer
TRAINER=train_SAcC
TRAINERARCH=${TRAINER}_${ARCH}
TRAINERPRJ=${TRAINER}_prj

MATLAB=/usr/bin/Matlab 
DEPLOYTOOL=/usr/bin/deploytool
#MATLAB=/Applications/MATLAB_R2009a.app/bin/matlab
# MacOS 64 bit (dpwe-macbook)
#DEPLOYTOOL=/Applications/MATLAB_R2010b.app/bin/deploytool
# Linux 64 bit (hog)
#DEPLOYTOOL=/usr/local/MATLAB/R2010b/bin/deploytool 
# Linux 32 bit (cherry)
#DEPLOYTOOL=${MATLAB} -r deploytool

# MCC
#MCC=/Applications/MATLAB_R2010b.app/bin/mcc
MCC=/usr/bin/mcc

# MEX
#MEX=/Applications/MATLAB_R2010b.app/bin/mex
MEX=/usr/bin/mex

DEMOFILE=demo_${PROG}
MAINFILE=${PROG}.m

THUMB=${PROG}_thumb.png

TRNSRCS= train_SAcC.m \
	 train_mkMLP.m \
	 train_mkLabFile.m \
	 train_mkFtrFile.m \
	 config_write.m \
	 freq2pitchix.m \
	 pfinfo.m \
	 pt_read.m \
	 \
	 train_make_ftr_file.sh \
	 sbpca_out.config

SRCS=${DEMOFILE}.m \
	SAcC.m \
	SAcCsri.m \
	SAcC_main.m \
	SAcC_pitchtrack.m \
	autocorrelogram.m \
	cal_ac.m \
	filterbank.m \
	bpfiltbank.m \
	cochlearfilt.m \
	MakeERBFilter.m \
	pitch2freq.m \
	mlp_fwd.m \
	readmlpnorms.m \
	readmlpwts.m \
	config_read_srs.m \
	config_read_sri.m \
	config_set.m \
	config_default.m \
	config_init.m \
	pem_read.m \
	audioread.m \
	wavread_downsamp.m \
	tracking_pitch_candidates.m \
	dithering.m \
	normalise.m \
	vsize.m \
	writesri.m \
	\
	pfile_uttfrmprefix.m \
	pfile_ascwriteappend.m \
	\
	autocorr.c \
	viterbi_path_LOG_helper.c \
	\
	${TRNSRCS}

DATA=	files.list files_b.list files+pem.list \
	${THUMB} \
	README

SUBDIRS = conf aux audio pem out.ref out.ref+pem

EXTRABINS= autocorr.mexmaci64 autocorr.mexa64 \
	   viterbi_path_LOG_helper.mexmaci64 viterbi_path_LOG_helper.mexa64 \
	   ReadSound.mexmaci64 ReadSound.mexa64

FORCOMPILE=${PROGPRJ}.prj ${PROGSRIPRJ}.prj ${TRAINERPRJ}.prj run_prj_${ARCH}.sh Makefile matlab_arch.sh

DEMOHTML=html/${DEMOFILE}.html
DEMOINDEX=html/index.html

DSTINDEX=${DST}/index.html

# Data to copy to website (referenced from demo_ file) 
# but not otherwise included in packages
NONPKGDATA=\
	${PROG}_MACI64.zip \
	${PROG}_GLNXA64.zip \
	${PROGSRI}_MACI64.zip \
	${PROGSRI}_GLNXA64.zip \
	${TRAINER}_MACI64.zip \
	${TRAINER}_GLNXA64.zip

all: dist

${DEMOHTML}: ${DEMOFILE}.m ${SRCS} ${DATA} 
	${MATLAB} -r "publish ${DEMOFILE}; exit"

${DEMOINDEX}: ${DEMOHTML}
	sed -e 's@<div class="content">@<a href="http://labrosa.ee.columbia.edu/">LabROSA</a> : <a href="http://labrosa.ee.columbia.edu/projects/">Projects</a>: <div class="content"> <IMG SRC="'${THUMB}'" ALIGN="LEFT" HSPACE="10">@' -e 's/amp;auml;/auml;/g' -e 's/@VER@/${VER}/g' < ${DEMOHTML} > ${DEMOINDEX}

autocorr.mex${arch}: autocorr.c
	${MEX} autocorr.c

viterbi_path_LOG_helper.mex${arch}: viterbi_path_LOG_helper.c
	${MEX} viterbi_path_LOG_helper.c

compile: compilesacc compilesri compiletrn

compilesacc: ${PROGARCH}.zip
compilesri: ${PROGSRIARCH}.zip
compiletrn: ${TRAINERARCH}.zip


${PROGARCH}.zip: ${SRCS} autocorr.mex${arch} viterbi_path_LOG_helper.mex${arch}
	-rm -rf ${PROGPRJ}
	${DEPLOYTOOL} -build ${PROGPRJ}
#	${MCC} -o ${PROGPRJ} -W main:${PROGPRJ} -T link:exe -w enable:specified_file_mismatch -w enable:repeated_file -w enable:switch_ignored -w enable:missing_lib_sentinel -w enable:demo_license -R singleCompThread -R -nodisplay -R -nojvm -v ${MAINFILE}
#	-d ${PROGPRJ}/src 
	mv ${PROGPRJ}/distrib ${PROGPRJ}/${PROGARCH}
	rm ${PROGPRJ}/${PROGARCH}/run_${PROGPRJ}.sh
	cp run_prj_${ARCH}.sh ${PROGPRJ}/${PROGARCH}/run_${PROG}.sh
	rm ${PROGPRJ}/${PROGARCH}/readme.txt
	cp README ${PROGPRJ}/${PROGARCH}/README
	for d in ${SUBDIRS}; do cp -pr $$d ${PROGPRJ}/${PROGARCH}/; done
	for f in ${DATA}; do cp -p $$f ${PROGPRJ}/${PROGARCH}/$$f; done
	cd ${PROGPRJ} && zip -r ${PROGARCH}.zip ${PROGARCH} && cd ..
	mv ${PROGPRJ}/${PROGARCH} ${PROGPRJ}/distrib
	mv ${PROGPRJ}/${PROGARCH}.zip .

${PROGSRIARCH}.zip: ${SRCS} autocorr.mex${arch} viterbi_path_LOG_helper.mex${arch}
	-rm -rf ${PROGSRIPRJ}
	${DEPLOYTOOL} -build ${PROGSRIPRJ}
	mv ${PROGSRIPRJ}/distrib ${PROGSRIPRJ}/${PROGSRIARCH}
	rm ${PROGSRIPRJ}/${PROGSRIARCH}/run_${PROGSRIPRJ}.sh
	cp run_prj_${ARCH}.sh ${PROGSRIPRJ}/${PROGSRIARCH}/run_${PROGSRI}.sh
	rm ${PROGSRIPRJ}/${PROGSRIARCH}/readme.txt
	cp README ${PROGSRIPRJ}/${PROGSRIARCH}/README
	for d in ${SUBDIRS}; do cp -pr $$d ${PROGSRIPRJ}/${PROGSRIARCH}/; done
	for f in ${DATA}; do cp -p $$f ${PROGSRIPRJ}/${PROGSRIARCH}/$$f; done
	cd ${PROGSRIPRJ} && zip -r ${PROGSRIARCH}.zip ${PROGSRIARCH} && cd ..
	mv ${PROGSRIPRJ}/${PROGSRIARCH} ${PROGSRIPRJ}/distrib
	mv ${PROGSRIPRJ}/${PROGSRIARCH}.zip .

${TRAINERARCH}.zip: ${TRNSRCS}
	-rm -rf ${TRAINERPRJ}
	${DEPLOYTOOL} -build ${TRAINERPRJ}
#	${MCC} -o ${TRAINERPRJ} -W main:${TRAINERPRJ} -T link:exe -w enable:specified_file_mismatch -w enable:repeated_file -w enable:switch_ignored -w enable:missing_lib_sentinel -w enable:demo_license -R singleCompThread -R -nodisplay -R -nojvm -v ${TRNMAINFILE}
#	-d ${TRAINERPRJ}/src
	mv ${TRAINERPRJ}/distrib ${TRAINERPRJ}/${TRAINERARCH}
	rm ${TRAINERPRJ}/${TRAINERARCH}/run_${TRAINERPRJ}.sh
	cp run_prj_${ARCH}.sh ${TRAINERPRJ}/${TRAINERARCH}/run_${TRAINER}.sh
	rm ${TRAINERPRJ}/${TRAINERARCH}/readme.txt
	cp README ${TRAINERPRJ}/${TRAINERARCH}/README
	cd ${TRAINERPRJ} && zip -r ${TRAINERARCH}.zip ${TRAINERARCH} && cd ..
	mv ${TRAINERPRJ}/${TRAINERARCH} ${TRAINERPRJ}/distrib
	mv ${TRAINERPRJ}/${TRAINERARCH}.zip .

test: testsacc testsri testtrn

testsacc: ${PROGARCH}.zip
	-rm -rf out
	${PROGPRJ}/distrib/run_${PROG}.sh files.list
	diff -r out out.ref
	${PROGPRJ}/distrib/run_${PROG}.sh files+pem.list
	diff -r out out.ref+pem

testsri: ${PROGSRIARCH}.zip
	-rm -rf out
	${PROGSRIPRJ}/distrib/run_${PROGSRI}.sh files.list
	diff -r out out.ref.sri

testtrn: ${TRAINERARCH}.zip
	-rm -rf out
	${TRAINERPRJ}/distrib/run_${TRAINER}.sh ../../data/pitch/keele/idlist.txt ../../data/pitch/keele/wav .wav ../../data/pitch/keele/ptk/gt -gt.txt keeleclean
	${PROGPRJ}/distrib/run_${PROG}.sh files.list keeleclean-config.txt
	diff -r out out.ref.trn

# training using alternate external feature calculation
testtrnextftr: ${TRAINERARCH}.zip
	./train_make_ftr_file.sh keele.list keeleclean-sbac.pf
	-rm -rf out
	${TRAINERPRJ}/distrib/run_${TRAINER}.sh ../../data/pitch/keele/idlist.txt "" "" ../../data/pitch/keele/ptk/gt -gt.txt keeleclean
	${PROGPRJ}/distrib/run_${PROG}.sh files.list keeleclean-config.txt
	diff -r out out.ref.trn


dist: ${SRCS} ${DATA} ${DEMOINDEX} ${EXTRABINS} ${FORCOMPILE}
	rm -rf ${PROG}
	rm -rf ${DST}
	mkdir ${DST}
	cp -pr html/* ${DST}
	rm ${DST}/${DEMOFILE}.html
	for d in ${SUBDIRS}; do cp -pr $$d ${DST}/; done
	for f in ${SRCS} ${DATA} ${EXTRABINS} ${FORCOMPILE}; do cp -p $$f ${DST}/$$f; done
	rm -f ${DST}/*~
	-rm-extended-attribs.sh ${DST}
#	tar cfz ${TAR} ${DST}
	zip -r ${ZIP} ${DST}
# needs to be called PROG (no ver number) not DST on server
	mv ${DST} ${PROG}
	cp -p ${ZIP} ${PROG}
#	cp -p ${PROG}_${ARCH}.zip ${PROG}
	cp -p ${NONPKGDATA} ${PROG}
	scp -pr ${PROG} wool.ee.columbia.edu:public_html/LabROSA/projects/
	scp -pr ${PROG} wool.ee.columbia.edu:wool-public_html/LabROSA/projects/
	scp -pr ${PROG} labrosa.ee.columbia.edu:/var/www/LabROSA/projects/
