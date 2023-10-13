#!/bin/sh

echo "Stage: PRE-Xcode Build is activated .... "

cd $CI_WORKSPACE/ci_scripts || exit 1

plutil -replace SERVER_KEY -string $SERVER_KEY Info.plist

plutil -p Info.plist

echo "Stage: PRE-Xcode Build is DONE .... "

exit 0
