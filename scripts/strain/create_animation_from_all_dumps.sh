#!/bin/bash

mkdir -p resolute_animation

dumps=$(find . -name '*.dump'|sed 's/.dump$//'|sort -n|sed 's/$/.dump/'|less)

step=1
for dump in $dumps; do
	cp $dump resolute_animation/$((step++)).dump
done


