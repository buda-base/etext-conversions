#! /bin/bash

for s in *
do
for w in $s/*
do
	for v in $w/sources/*
	do
		vnm=$(basename $v)
		echo mkdir -p $w/rtfs/$vnm
		mkdir -p "$w/rtfs/$vnm"
		for f in $v/*.rtf
		do
			echo mv "$f" "$w/rtfs/$vnm/"
			mv "$f" "$w/rtfs/$vnm/"
		done
	done
done
done