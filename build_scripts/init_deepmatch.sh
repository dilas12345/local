# References: http://lear.inrialpes.fr/src/deepmatching/ 

#sudo apt-get install libblas-dev

code
#python -c "import utool as ut; print(ut.grab_zipped_url('http://lear.inrialpes.fr/src/deepmatching/code/deepmatching_1.0.2.zip', download_dir='.'))"
python -c "import utool as ut; print(ut.grab_zipped_url('http://lear.inrialpes.fr/src/deepmatching/code/deepmatching_1.2.zip', download_dir='.'))"

cd deepmatching_1.2_c++
make clean all
make -j9


#REPLACE
#  LAPACKLDFLAGS=/usr/lib64/atlas/libtatlas.so  # multi-threaded blas
#WITH
#  LAPACKLDFLAGS=/usr/lib/atlas-base/libatlas.so
#IN
#  Makefile

#  ALSO


#LIBPNG=/usr/lib/x86_64-linux-gnu/libpng.a
#LIBPNG=/usr/lib/x86_64-linux-gnu/libpng.a
##LIBPNG=/usr/lib64/libpng.a


##LIBJPG=/home/lear/douze/tmp/jpeg-6b/libjpeg.a
#LIBJPG=/usr/lib/x86_64-linux-gnu/libjpeg.a


##LIBZ=/usr/lib64/libz.a
#LIBZ=/usr/lib/x86_64-linux-gnu/libz.a


##LIBBLAS=/usr/lib64/libblas.a
#LIBBLAS=/usr/lib/atlas-base/atlas/libblas.a


##LIBFORTRAN=/usr/lib/gcc/x86_64-redhat-linux/4.9.2/libgfortran.a 
#LIBFORTRAN=/usr/lib/gcc/x86_64-linux-gnu/4.8/libgfortran.a


##QUADMATH=/usr/lib/gcc/x86_64-redhat-linux/4.9.2/libquadmath.a
#QUADMATH=/usr/lib/gcc/x86_64-linux-gnu/4.8/libquadmath.a
  
#STATICLAPACKLDFLAGS=-fPIC -Wall -g -fopenmp -static -static-libstdc++  $(LIBJPG) $(LIBPNG) $(LIBZ) $(LIBBLAS) $(LIBFORTRAN) $(QUADMATH)  # statically linked version


python -c 'import utool as ut; ut.copy(ut.grab_test_imgpath("easy1.png"), ".")'
python -c 'import utool as ut; ut.copy(ut.grab_test_imgpath("easy2.png"), ".")'
python -c 'import utool as ut; ut.copy(ut.grab_test_imgpath("easy3.png"), ".")'
python -c 'import utool as ut; ut.copy(ut.grab_test_imgpath("hard3.png"), ".")'
python -c 'import utool as ut; ut.copy(ut.grab_test_imgpath("lena.png"), ".")'


chmod +x deepmatching-static
./deepmatching-static

run_deepmatch()
{
    ./deepmatching-static $1 $2 -nt 9 -out match.$1.$2.out 
    cat match.$1.$2.out | python viz.py $1 $2
}

run_deepmatch easy1.png easy2.png
run_deepmatch easy3.png easy2.png
run_deepmatch hard3.png easy2.png
run_deepmatch easy1.png lena.png

./deepmatching-static easy1.png easy2.png -nt 9  > out12
cat out12 | python viz.py easy1.png easy2.png

./deepmatching-static easy1.png easy3.png -nt 9  > out13
cat out13 | python viz.py easy1.png easy3.png

./deepmatching-static easy1.png hard3.png -nt 9  > out1h3
cat out1h3 | python viz.py easy1.png hard3.png
