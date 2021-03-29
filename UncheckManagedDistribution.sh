#!/bin/bash

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

# Unselect 'managed distribution' for all iOS apps, based on GetiOSAppIDs function
UncheckForiOS () {
for id in $ids; do
echo "updating iOS ID $id..."
curl -H "accept: text/xml" -H "content-type: text/xml" -H "authorization: Basic $auth" -ks "$JSSURL/JSSResource/mobiledeviceapplications/id/$id" -X PUT -d  "<mobile_device_application><vpp><assign_vpp_device_based_licenses>false</assign_vpp_device_based_licenses><vpp_admin_account_id>-1</vpp_admin_account_id></vpp></mobile_device_application>" 
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

# Uncheck Managed Distribution box for all MacOS Apps
UncheckForMacOS () {
for id in $ids; do
echo "updating Mac App ID $id..."
curl -H "accept: text/xml" -H "content-type: text/xml" -H "authorization: Basic $auth" -ks "$JSSURL/JSSResource/macapplications/id/$id" -X PUT -d  "<mac_application><vpp><assign_vpp_device_based_licenses>false</assign_vpp_device_based_licenses><vpp_admin_account_id>-1</vpp_admin_account_id></vpp></mac_application>" 
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


# Ask if we want to disassociate all iOS licenses
while true; do
	read -p "Would you like to disassociate all iOS licenses? (y/n) " yn
	case $yn in
		[Yy]* )
		GetiOSAppIds
		UncheckForiOS
		break
		;;
		[Nn]* ) 
		break;;
		* ) echo "Please answer yes or no.";;
	esac
done

# Ask if we want to disassociate all MacOS licenses
while true; do
	read -p "Would you like to disassociate all MacOS licenses? (y/n) " yn
	case $yn in
		[Yy]* )
		GetMacAppIds
		UncheckForMacOS
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
echo "All selected Apps should now have the 'Assign Volume Content' box unchecked in the Managed Distribution tab"
echo " "
echo "The 'In Use' count for each App listing should be decreasing"
echo "To view the In Use count, go to Settings > Volume Purchasing > your legacy VPP portal token"
echo "Under the Content tab, we will want to wait until all In-Use reads 0 for Mobile Device Apps"
echo "If this does not happen, go to Mobile Devices > Mobile Device Apps, and sort by 'Total Purchased'"
echo "Manually uncheck the 'Assign Volume Content' box of every app that still has a license count"
