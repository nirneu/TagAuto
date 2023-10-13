#!/bin/sh

#  ci_pre_xcodebuild.sh
#  FinnFinds
#
#  Created by Nir Neuman on 13/10/2023.
#

echo "Stage: PRE-Xcode Build is activated .... "

cd ../FinnFinds/

plutil -replace SERVER_KEY -string $SERVER_KEY Info.plist

plutil -p Info.plist

echo "Stage: PRE-Xcode Build is DONE .... "

exit 0
