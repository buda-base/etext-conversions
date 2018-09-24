#! /bin/bash

for w in *
do
	for v in $w/sources/*
	do
		vnm=$(basename $v)
		echo mkdir -p $w/rtfs/$vnm
		mkdir -p $w/rtfs/$vnm
		for f in $v/*.docx
		do
			fnm=$(basename $f .docx)
			echo textutil -convert rtf -output $w/rtfs/$vnm/$fnm.rtf $f
			textutil -convert rtf -output "$w/rtfs/$vnm/$fnm.rtf" $f
		done
	done
done
