#!/bin/bash

[ -z $1 ] && echo "You must specify path for fixing permissions" && exit 1

# Fixes permissions in folders
for i in `find $1 -type d`
do
  [ -r $i ] && chmod go+r $i
  [ -w $i ] && chmod go+w $i
  [ -x $i ] && chmod go+x $i
done

# Goes up directories to root
f=$1
while [[ $f != "/" ]]; do chmod go+wx $f; f=$(dirname $f); done;

# Fixes permissions in files
for i in `find $1 -type f`
do
  [ -r $i ] && chmod go+r $i
  [ -w $i ] && chmod go+w $i
  [ -x $i ] && chmod go+x $i
done  

exit 0