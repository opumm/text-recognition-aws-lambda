#!/usr/bin/env bash
TESSERACT_VERSION="4.1.1"

# docker_build tesseract
cd ~
wget https://github.com/tesseract-ocr/tesseract/archive/$TESSERACT_VERSION.tar.gz
ls
tar -xzvf $TESSERACT_VERSION.tar.gz
cd tesseract-$TESSERACT_VERSION
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
./autogen.sh
./configure
make
make install

cd ~
mkdir tesseract-standalone
cd tesseract-standalone
cp /usr/local/bin/tesseract .
mkdir lib
cp /usr/local/lib/libtesseract.so.4 lib/
cp /usr/local/lib/liblept.so.5 lib/
cp /usr/lib64/libjpeg.so.62 lib/
cp /usr/lib64/libwebp.so.4 lib/
cp /usr/lib64/libpng15.so.15 lib/
cp /usr/lib64/libtiff.so.5 lib/
cp /usr/lib64/libgomp.so.1 lib/
cp /usr/lib64/libjbig.so.2.0 lib/
cp /usr/lib64/libstdc++.so.6 lib/
cp /usr/lib64/libpthread.so lib/
cp /usr/lib64/librt.so lib/
cp /usr/lib64/libz.so lib/ 
cp /usr/lib64/libm.so lib/ 
cp /usr/lib64/libpng12.so.0 lib/
cp /usr/lib64/libjpeg.so.62 lib/ 
cp /usr/lib64/libtiff.so.5 lib/ 
cp /usr/lib64/libpthread.so lib /
cp /usr/lib64/libstdc++.so.6 lib /
cp /usr/lib64/libjbig.so.2.0 lib/ 
cp /usr/lib64/libwebp.so.4 lib/


mkdir tessdata
cd tessdata

wget https://github.com/tesseract-ocr/tessdata_fast/raw/refs/heads/main/eng.traineddata

mkdir configs
cp /usr/local/share/tessdata/configs/pdf configs/
cp /usr/local/share/tessdata/pdf.ttf .

cd ..
zip -r /tmp/build/tesseract.zip *