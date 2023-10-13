#!/bin/sh

#  ci_post_clone.sh
#  FinnFinds
#
#  Created by Nir Neuman on 13/10/2023.
#  

echo "Stage: Post-Xcode Build is activated .... "

cd ../FinnFinds/

plutil -replace SERVER_KEY -string $SERVER_KEY Info.plist

plutil -p Info.plist

echo "Stage: Post-Xcode Build is DONE .... "

exit 0
