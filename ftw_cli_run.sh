#!/bin/bash

# Created by Michael Ibarra, Check Point SE, michaelib@checkpoint.com
# Freely distribute and re-use as needed, but please give original credit to
# the author above. Enjoy!

# Runs through first-time wizard steps, using an external file of referenced values

timestamp=$(date +%Y%m%d-%H%M%S)

echo ""
echo "Welcome to the FTW CLI script!"
echo "!!! PLEASE NOTE this script is ONLY intended for a Security Gateway !!!"
echo ""

read -p "Please enter your desired admin password: " -s admin_pw1
echo
read -p "Please enter your desired admin password again: " -s admin_pw2
echo

while [ $admin_pw1 != $admin_pw2 ]
do
    echo
    echo "Passwords do not match! Please try again."
    read -p "Please enter your desired admin password: " -s admin_pw1
    echo
    read -p "Please enter your desired admin password again: " -s admin_pw2
    echo
done

admin_pw=$admin_pw1

# Generates a SHA512 hash with a random salt value
# '$6' indicates SHA512
# Following 16 chars indicate salt value
# Following 86 chars are the hashed password value

admin_hash=$(cpopenssl passwd -6 $admin_pw)
echo ""
echo "The resulting hash is: $admin_hash"
echo "admin_hash='$admin_hash'" >> ftw_config_$timestamp
echo ""

read -p "Enter a hostname: " hostname
echo "hostname=$hostname" >> ftw_config_$timestamp
echo ""

read -p "Enter your desired SIC key: " -s ftw_sic_key1
echo
read -p "Enter your desired SIC key again: " -s ftw_sic_key2
echo

while [ $ftw_sic_key1 != $ftw_sic_key2 ]
do
    echo
    echo "Keys do not match! Please try again."
    read -p "Enter your desired SIC key: " -s ftw_sic_key1
    echo
    read -p "Please enter your desired SIC key again: " -s ftw_sic_key2
    echo
done

ftw_sic_key=$ftw_sic_key1

echo "ftw_sic_key=$ftw_sic_key" >> ftw_config_$timestamp
echo ""

echo "install_security_managment=false" >> ftw_config_$timestamp
echo "install_security_gw=true" >> ftw_config_$timestamp
echo "gateway_daip=false" >> ftw_config_$timestamp
echo "install_ppak=true" >> ftw_config_$timestamp
echo "gateway_cluster_member=false" >> ftw_config_$timestamp

read -p "Enter a static IP address for the management interface: " ipaddr_v4
read -p "Enter the subnet mask length (0 - 32): " mask_len

while [[ $(($mask_len)) -gt 32 || $(($mask_len)) -lt 0 ]]
do
    echo
    echo "Invalid mask length entered! Please try again."
    read -p "Enter the subnet mask length (0 - 32): " mask_len
done

read -p "Enter the default gateway: " default_gw_v4
read -p "Enter the domain name: " domainname
echo "ipaddr_v4=$ipaddr_v4" >> ftw_config_$timestamp
echo "mask_len=$mask_len" >> ftw_config_$timestamp
echo "default_gw_v4=$default_gw_v4" >> ftw_config_$timestamp
echo "domainname=$domainname" >> ftw_config_$timestamp
echo ""

read -p "Enter your primary DNS server: " primary
read -p "Enter your secondary DNS server (Enter for none): " secondary
read -p "Enter your tertiary DNS server (Enter for none): " tertiary
echo "primary=$primary" >> ftw_config_$timestamp
echo "secondary=$secondary" >> ftw_config_$timestamp
echo "tertiary=$tertiary" >> ftw_config_$timestamp
echo ""

read -p "Enter the timezone in tz database format (e.g., America/Los_Angeles): " timezone
ntp_primary=ntp.checkpoint.com
ntp_secondary=ntp2.checkpoint.com
read -p "Enter primary NTP server (Enter to keep default): " ntp_primary
read -p "Enter secondary NTP server (Enter to keep default): " ntp_secondary
echo "timezone='$timezone'" >> ftw_config_$timestamp
echo "ntp_primary=$ntp_primary" >> ftw_config_$timestamp
echo "ntp_primary_version=4" >> ftw_config_$timestamp
echo "ntp_secondary=$ntp_secondary" >> ftw_config_$timestamp
echo "ntp_secondary_version=4" >> ftw_config_$timestamp
echo ""

read -p "Keep defaults for communicating with User Center? Enter y/n: " uc_choice

if [[ $uc_choice = "y" ]]
then
    echo "download_info=true" >> ftw_config_$timestamp
    echo "upload_info=true" >> ftw_config_$timestamp
    echo "upload_crash_data=false" >> ftw_config_$timestamp
else
    echo
    echo "Fine! Have it your way..."
    read -p "Download info from UC? Enter y/n: " download_info
    if [[ $download_info = "y" ]]
    then
        echo "download_info=true" >> ftw_config_$timestamp
    else
        echo "download_info=false" >> ftw_config_$timestamp
    fi
    read -p "Upload info to UC? Enter y/n: " upload_info
    if [[ $upload_info = "y" ]]
    then
        echo "upload_info=true" >> ftw_config_$timestamp
    else
        echo "upload_info=false" >> ftw_config_$timestamp
    fi
    read -p "Upload crash data (which may contain PII)? Enter y/n: " upload_crash_data
    if [[ $upload_crash_data = "y" ]]
    then
        echo "upload_crash_data=true" >> ftw_config_$timestamp
    else
        echo "upload_crash_data=false" >> ftw_config_$timestamp
    fi
fi

echo ""

read -p "Should the gateway reboot automatically when config is complete? Enter y/n: " reboot_if_required

if [[ $reboot_if_required = "y" ]]
then
    echo "reboot_if_required=true" >> ftw_config_$timestamp
else
    echo "reboot_if_required=false" >> ftw_config_$timestamp
fi

echo ""

echo "That's all I need! Let me check your config..."
echo ""

config_check_result=$(config_system --dry-run -f ftw_config_$timestamp | tail -n 2)

if [[ $config_check_result =~ "Failed" ]]
then
    echo ""
    echo "Oh no! The check failed :( ... please start over!"
    exit
else
        echo "Hooray! Your config checks out!"
fi

echo ""

read -p "Ready to apply for real? Enter y/n: " proceed
if [[ $proceed = "y" ]]
then
    echo "OK! Here we go..."
    echo ""
    config_system -f ftw_config_$timestamp
else
    echo "OK, pausing until you can make up your mind!"
fi

echo ""