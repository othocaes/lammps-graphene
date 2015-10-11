#!/bin/bash

# Script to create an mpeg4 from a jmol animation.

script_dir="$(dirname $0)/.."

source $script_dir/func/utility.src

mkdir images.tmp

echo 'frame 1
num_frames = getProperty("modelInfo.modelCount")
for (var i = 1; i <= num_frames; i = i+1)
   var filename = "images.tmp/movie"+("00000"+i)[-4][0]+".jpg"
   write IMAGE 800 600 JPG @filename
   frame next
end for
exitJmol' >> make_images.jmol.tmp

jmol -k --nosplash $1 -s make_images.jmol.tmp 

mencoder "mf://images.tmp/*.jpg" -o $1.avi -ovc lavc -lavcopts vcodec=msmpeg4v2:autoaspect:vbitrate=2160000:mbd=2:keyint=132:vqblur=1.0:cmp=2:subcmp=2:dia=2:mv0:last_pred=3 -fps 8

clean


