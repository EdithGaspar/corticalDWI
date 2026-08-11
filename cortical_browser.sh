#!/bin/bash
# This is just a wrapper script to call the cortical_browser.py script with the correct arguments.

thisDir=$(readlink -f `dirname $0`)
$thisDir/cortical_browser/cortical_browser.py $1 $2 $3 $4 $5 $6 $7 $8 $9