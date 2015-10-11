#!/bin/bash

mkdir -p animation

dirs=$(find . -name "min.*"|sort)

step=1
for dir in $dirs; do
	final_dump_file=$(find $dir -name '*.dump'|sort -n -r|sed -n 1p)
	cp $final_dump_file animation/$((step++)).dump
done

