##########################
# STEP 2
# Grab Caffe repository code
cd ~/
mkdir code
cd code
git clone https://github.com/BVLC/caffe.git
cd caffe

cat >  ~/code/caffe/Makefile.config << EOL
## Refer to http://caffe.berkeleyvision.org/installation.html
# Contributions simplifying and improving our build system are welcome!

# CPU-only switch (uncomment to build without GPU support).
# CPU_ONLY := 1

# To customize your choice of compiler, uncomment and set the following.
# N.B. the default for Linux is g++ and the default for OSX is clang++
#CUSTOM_CXX := g++-4.6
CUSTOM_CXX := g++

# CUDA directory contains bin/ and lib/ directories that we need.
CUDA_DIR := /usr/local/cuda
# On Ubuntu 14.04, if cuda tools are installed via
# "sudo apt-get install nvidia-cuda-toolkit" then use this instead:
# CUDA_DIR := /usr

# CUDA architecture setting: going with all of them (up to CUDA 5.5 compatible).
# For the latest architecture, you need to install CUDA >= 6.0 and uncomment
# the *_50 lines below.
CUDA_ARCH := -gencode arch=compute_20,code=sm_20 \
		-gencode arch=compute_20,code=sm_21 \
		-gencode arch=compute_30,code=sm_30 \
		-gencode arch=compute_35,code=sm_35 \
		-gencode arch=compute_50,code=sm_50 \
		-gencode arch=compute_50,code=compute_50

# BLAS choice:
# atlas for ATLAS (default)
# mkl for MKL
# open for OpenBlas
BLAS := atlas
# Custom (MKL/ATLAS/OpenBLAS) include and lib directories.
# Leave commented to accept the defaults for your choice of BLAS
# (which should work)!
# BLAS_INCLUDE := /path/to/your/blas
# BLAS_LIB := /path/to/your/blas

# This is required only if you will compile the matlab interface.
# MATLAB directory should contain the mex binary in /bin.
# MATLAB_DIR := /usr/local
# MATLAB_DIR := /Applications/MATLAB_R2012b.app

# NOTE: this is required only if you will compile the python interface.
# We need to be able to find Python.h and numpy/arrayobject.h.
PYTHON_INCLUDE := /usr/include/python2.7 \
		/usr/lib/python2.7/dist-packages/numpy/core/include

# We need to be able to find libpythonX.X.so or .dylib.
PYTHON_LIB := /usr/lib/x86_64-linux-gnu/
# PYTHON_LIB := \$(HOME)/anaconda/lib

# Whatever else you find you need goes here.
INCLUDE_DIRS := \$(PYTHON_INCLUDE) /usr/local/include
LIBRARY_DIRS := \$(PYTHON_LIB) /usr/local/lib /usr/lib

BUILD_DIR := build
DISTRIBUTE_DIR := distribute

# Uncomment for debugging. Does not work on OSX due to https://github.com/BVLC/caffe/issues/171
# DEBUG := 1

# The ID of the GPU that make runtest will use to run unit tests.
TEST_GPUID := 0
EOL

cat  ~/code/caffe/Makefile.config

export NCPUS=$(grep -c ^processor /proc/cpuinfo)
echo $NCPUS
export NCPUSPP=`expr $NCPUS + 1`
echo $NCPUSPP

# Update Makefile.config
#cp ~/Downloads/caffe-Makefile.config ~/code/caffe/Makefile.config
# Compile Caffe
make all -j$NCPUSPP
make test -j$NCPUSPP
# Test Caffe
make runtest
# Compile Python bindings
make pycaffe -j$NCPUSPP
# Test PyCaffe
sudo pip install -r python/requirements.txt
# Download models
mkdir models/bvlc_reference_caffenet/
cd models/bvlc_reference_caffenet/
wget http://dl.caffe.berkeleyvision.org/bvlc_reference_caffenet.caffemodel
cd ~/code/caffe
python python/classify.py examples/images/cat.jpg foo
python python/classify.py --gpu examples/images/cat.jpg foo
# Remove installation lock file
sudo rm -rf ~/Downloads/caffe.lock
