#! /bin/bash

sourceDir=$1
echo sourceDir = $sourceDir

targetDir=$2
echo targetDir = $targetDir

cd $sourceDir

for fnm in ./*.xml ; do
	f=$(basename $fnm)
	wrkDir="${f%%-*}"
	vDir="${f%.xml}"
	
	path="$targetDir/$wrkDir/xml/$vDir"
	mkdir -p "$path"
	mv "$f" "$path/" 
done
