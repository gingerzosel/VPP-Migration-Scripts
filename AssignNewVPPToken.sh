#!/bin/bash
# This script should be run after the 'Uncheck' script, and will recheck the 'Managed Distribution' tab
#############################################################################################
#
# Copyright (c) 2020, JAMF Software, LLC. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without # modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright # notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright # notice, this list of conditions and the following disclaimer in the # documentation and/or other materials provided with the distribution.
# * Neither the name of the JAMF Software, LLC nor the # names of its contributors may be used to endorse or promote products # derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY # EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE # DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY # DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; # LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND # ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#############################################################################################
# Ginger Zosel
# March 2021

echo "This script is designed to run after UncheckManagedDistribution.sh script"
echo "and transferring the licenses to the new token"
echo "this script will re-check the 'Managed Distribution' box and assign to the designated VPP token"

# Enter in the URL of the JSS . 
echo " "
echo " "
echo "Please enter your Jamf Pro URL"
echo "On-Prem Example: https://myjss.com:8443"
echo "Jamf Cloud Example: https://myjss.jamfcloud.com"
read JSSURL
echo ""

# Trim the trailing slash off if necessary
if [ $(echo "${JSSURL: -1}") == "/" ]; then
	JSSURL=$(echo $JSSURL | sed 's/.$//')
fi

# Get Login Credentials
echo "Please enter an Adminstrator's username for the JSS:"
read JSSUser
echo ""

echo "Please enter the password for $JSSUser's account:"
read -s -p "Jamf Pro Password: " JSSPassword
echo ""

echo "Please enter the ID number of our new VPP token:"
read token
echo ""

auth=$( printf "$JSSUser:$JSSPassword" | Base64 )

###############
#
#    Functions
#
########

# Get a list of all iOS Apps
GetiOSAppIds () {
echo ""
echo "Retrieving List of iOS Apps to update"
ids=$(curl -H "authorization: Basic $auth" -H "Content-type: text/xml" -ks "$JSSURL/JSSResource/mobiledeviceapplications" | xmllint --format - | awk -F '[<>]' '/<id>/{print $3}')
}

# Select 'managed distribution' for all iOS apps and assign to new VPP token, based on GetiOSAppIDs function
UpdateForiOS () {
for id in $ids; do
echo "updating iOS ID $id..."
curl -H "accept: text/xml" -H "content-type: text/xml" -H "authorization: Basic $auth" -ks "$JSSURL/JSSResource/mobiledeviceapplications/id/$id" -X PUT -d  "<mobile_device_application><vpp><assign_vpp_device_based_licenses>true</assign_vpp_device_based_licenses><vpp_admin_account_id>$token</vpp_admin_account_id></vpp></mobile_device_application>" 
echo ""
done
echo ""
echo "****** Complete ******"
echo ""
}

# Get a list of all MacOS Apps
GetMacAppIds () {
echo ""
echo "Retrieving List of MacOS Apps to update"
echo "..."
ids=$(curl -H "authorization: Basic $auth" -H "Content-type: text/xml" -ks "$JSSURL/JSSResource/macapplications" | xmllint --format - | awk -F '[<>]' '/<id>/{print $3}')
}

# Check Managed Distribution box for all MacOS Apps and assign to new VPP token
UpdateForMacOS () {
for id in $ids; do
echo "updating Mac App ID $id..."
curl -H "accept: text/xml" -H "content-type: text/xml" -H "authorization: Basic $auth" -ks "$JSSURL/JSSResource/macapplications/id/$id" -X PUT -d  "<mac_application><vpp><assign_vpp_device_based_licenses>true</assign_vpp_device_based_licenses><vpp_admin_account_id>$token</vpp_admin_account_id></vpp></mac_application>" 
echo ""
done
echo ""
echo "****** Complete ******"
echo ""
}


###############
#
#    Selections and Actions
#
########

tokenname=$(curl -H "authorization: Basic $auth" -H "Content-type: text/xml" -ks "$JSSURL/JSSResource/vppaccounts/id/$token" | xmllint -xpath /vpp_account/name - | sed -e 's/<[^>]*>//g')
echo ""
echo "The selected token is $tokenname"

# Ask if we want to assign all iOS apps to the new token
while true; do
	read -p "Would you like to assign all iOS apps to use the \"$tokenname\" VPP token? (y/n) " yn
	case $yn in
		[Yy]* )
		GetiOSAppIds
		UpdateForiOS
		break
		;;
		[Nn]* ) 
		break;;
		* ) echo "Please answer yes or no.";;
	esac
done

# Ask if we want to assign all MacOS apps to the new token
while true; do
	read -p "Would you like to assign all MacOS apps to use the $tokenname VPP token? (y/n) " yn
	case $yn in
		[Yy]* )
		GetMacAppIds
		UpdateForMacOS
		break
		;;
		[Nn]* ) 
		break;;
		* ) echo "Please answer yes or no.";;
	esac
done



###############
#
#    Update Admin on Status
#
########


echo ""
echo ""
echo ""
echo ""
echo ""
echo "All selected Apps should now have the 'Assign Volume Content' box checked in the Managed Distribution tab"
echo "We should also see all apps assigned to the new VPP token"
echo " "
echo "The 'In Use' count for each App listing should be increasing"
echo "There should also be licensing information listed on the Devices > Apps page for each app"
echo "If this does not happen, go to Mobile Devices > Mobile Device Apps, and sort by 'Total Purchased'"
echo "Manually check 'Assign Volume Content' box of every app that is not displaying license information, and assign to the new token"
