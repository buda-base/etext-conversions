#! /bin/bash

w="Precious-and-Rare-Disk-01-20130424"
for v in $w/sources/*
do
	vnm=$(basename $v)
# 		echo mkdir $w/rtfs/$vnm
# 		mkdir $w/rtfs/$vnm
	for f in $v/*.doc
	do
		fnm=$(basename $f .doc)
		echo textutil -convert rtf -output $w/rtfs/$vnm/$fnm.rtf $f
		textutil -convert rtf -output "$w/rtfs/$vnm/$fnm.rtf" $f
	done
done
