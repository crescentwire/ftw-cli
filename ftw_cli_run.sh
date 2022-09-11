#!/bin/bash

# Created by Michael Ibarra, Check Point SE, michaelib@checkpoint.com
# Freely distribute, modify, and use as needed, but please give original credit to
# the author above. 
# Enjoy!

# Now with all the things! Supports security gateways, management, MDS, and standalone
# configurations. 

# PLEASE NOTE: VSX and scalable platforms are not supported (yet!).


# This script runs through first-time wizard steps, using an external file of referenced values


timestamp=$(date +%Y%m%d-%H%M%S)

echo ""
echo "Welcome to the FTW CLI script!"
echo ""


# Define Management interface

function list_intfs {
    clish -c "lock database override" > /dev/null
    mapfile -t intf_array < <(clish -c "show interfaces")
    # declare -p intf_array
    for i in "${!intf_array[@]}"
    do
        printf "(%s) %s\n" "$i" "${intf_array[$i]}"
    done
}

mgmt_intf_curr=$(clish -c "show configuration" | grep "set management interface" | awk -F ' ' '{print $NF}')

read -p "Change current management interface ($mgmt_intf_curr)? Enter y/n: " mgmt_intf_bool
echo ""

while [[ "$mgmt_intf_bool" != "y" && "$mgmt_intf_bool" != "n" ]]
do
    read -p "Invalid entry. Please enter y/n: " mgmt_intf_bool
done

if [[ "$mgmt_intf_bool" == "y" ]]
then
    echo "Please define the new management interface. Options are below: "
    echo ""
    list_intfs
    echo ""
    intf_array_len=$(( ${#intf_array[@]} - 1 ))
    read -p "Enter desired management interface (0-$intf_array_len): " mgmt_intf
    
    while [[ $(("$mgmt_intf")) -lt 0 || $(("$mgmt_intf")) -gt $(("$intf_array_len")) ]]
    do
        echo "Invalid entry. Please try again."
        read -p "Enter desired management interface (0-$intf_array_len): " mgmt_intf
        echo ""
    done

    echo "iface=${intf_array[$mgmt_intf]}" >> ftw_config_$timestamp
fi


# Define IPv4 addressing for Management interface

function ipv4_config {

    mgmt_intf_ip_curr=$(clish -c "show interface $mgmt_intf_curr" | grep ipv4-address | awk -F ' ' '{print $NF}')

    read -p "Change current IP address ($mgmt_intf_ip_curr) for $mgmt_intf_curr? Enter y/n: " mgmt_intf_ip_bool
    echo ""

    while [[ "$mgmt_intf_ip_bool" != "y" && "$mgmt_intf_ip_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " mgmt_intf_ip_bool
    done

    if [[ "$mgmt_intf_ip_bool" == "y" ]]
    then
        read -p "Enter new IPv4 address: " ipv4_addr

        while [[ -z "$ipv4_addr" ]]
        do
            echo "IPv4 address cannot be empty. Please try again."
            read -p "Enter new IPv4 address: " ipv4_addr
            echo ""
        done

        echo "ipaddr_v4=$ipv4_addr" >> ftw_config_$timestamp

        read -p "Enter new subnet mask length in CIDR format (0-32): " ipv4_mask

        while [[ $(("$ipv4_mask")) -lt 0 || $(("$ipv4_mask")) -gt 32 ]]
        do
            echo "Invalid mask length entered. Please try again."
            read -p "Enter new subnet mask legnth in CIDR format (0-32): " ipv4_mask
        done

        echo "masklen_v4=$ipv4_mask" >> ftw_config_$timestamp

        read -p "Enter new default gateway: " ipv4_gw

        while [[ -z "$ipv4_gw" ]]
        do
            echo "Default gateway cannot be empty. Please try again."
            read -p "Enter new default gateway: " ipv4_gw
            echo ""
        done

        echo ""
        echo "default_gw_v4=$ipv4_gw" >> ftw_config_$timestamp
    fi
}

read -p "Configure IPv4 for management interface? Enter y/n: " ipv4_config_bool
echo ""

while [[ "$ipv4_config_bool" != "y" && "$ipv4_config_bool" != "n" ]]
do
    read -p "Invalid entry. Please enter y/n: " ipv4_config_bool
done

if [[ "$ipv4_config_bool" == "y" ]]
then
    echo "ipstat_v4=manually" >> ftw_config_$timestamp
    ipv4_config
elif [[ "$ipv4_config_bool" == "n" ]]
then
    read -p  "WARNING: This will DISABLE IPv4 on $mgmt_intf_curr. Are you sure? Enter y/n: " ipv4_config_conf_bool
    echo ""
    
    while [[ "$ipv4_config_conf_bool" != "y" && "$ipv4_config_conf_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " ipv4_config_conf_bool
    done

    if [[ "$ipv4_config_conf_bool" == "n" ]]
    then
        echo "ipstat_v4=manually" >> ftw_config_$timestamp
        ipv4_config
    elif [[ "$ipv4_config_conf_bool" == "y" ]]
    then
        echo "ipstat_v4=off" >> ftw_config_$timestamp
    fi
fi


# Define IPv6 addressing for Management interface

function ipv6_config {
    read -p "Enter IPv6 address: " ipv6_addr
    read -p "Enter IPv6 prefix length (0-128): " ipv6_mask

    while [[ $(("$ipv6_mask")) -gt 128 || $(("$ipv6_mask")) -lt 0 ]]
    do
        echo "Invalid mask length entered. Please try again."
        read -p "Enter IPv6 prefix length (0-128): " ipv6_mask
    done

    read -p "Enter default gateway: " ipv6_gw
    echo ""
    echo "ipaddr_v6=$ipv6_addr" >> ftw_config_$timestamp
    echo "masklen_v6=$ipv6_mask" >> ftw_config_$timestamp
    echo "default_gw_v6=$ipv6_gw" >> ftw_config_$timestamp

}

read -p "Configure IPv6 for management interface? Enter y/n: " ipv6_config_bool
echo ""

while [[ "$ipv6_config_bool" != "y" && "$ipv6_config_bool" != "n" ]]
do
    read -p "Invalid entry. Please enter y/n: " ipv6_config_bool
done

if [[ "$ipv6_config_bool" == "y" ]]
then
    echo "ipstat_v6=manually" >> ftw_config_$timestamp
    ipv6_config
elif [[ "$ipv6_config_bool" == "n" ]]
then
    echo "ipstat_v6=off" >> ftw_config_$timestamp
fi


# Define hostname, domain name, and DNS

function host_domain_dns {
    read -p "Enter hostname: " hostname

    while [[ -z "$hostname" ]]
    do
        echo "Hostname cannot be empty. Please try again."
        read -p "Enter hostname: " hostname        
    done

    read -p "Enter domain name: " domain_name

    while [[ -z "$domain_name" ]]
    do
        echo "Domain name cannot be empty. Please try again."
        read -p "Enter domain name: " domain_name        
    done

    echo ""
    read -p "Enter primary DNS server: " dns_primary

    while [[ -z "$dns_primary" ]]
    do
        echo "Primary DNS server cannot be empty. Please try again."
        read -p "Enter primary DNS server: " dns_primary
    done

    read -p "Enter secondary DNS server (Enter to skip): " dns_secondary
    read -p "Enter tertiary DNS server (Enter to skip): " dns_tertiary
    echo ""
    echo "hostname=$hostname" >> ftw_config_$timestamp
    echo "domainname=$domain_name" >> ftw_config_$timestamp
    echo "primary=$dns_primary" >> ftw_config_$timestamp
    echo "secondary=$dns_secondary" >> ftw_config_$timestamp
    echo "tertiary=$dns_tertiary" >> ftw_config_$timestamp
}

host_domain_dns


# Define proxy server

function proxy_config {
    read -p "Enter proxy server (IP or FQDN): " proxy_server

    while [[ -z "$proxy_server" ]]
    do
        echo "Proxy server address cannot be empty. Please try again."
        read -p "Enter proxy server (IP or FQDN): " proxy_server
    done

    read -p "Enter port number (0-65535): " proxy_port

    while [[ $(("$proxy_port")) -lt 0 || $(("$proxy_port")) -gt 65535 ]]
    do
        echo "Invalid port number. Please try again."
        read -p "Enter port number (0-65535): " proxy_port
    done

    echo ""
    echo "proxy_address=$proxy_server" >> ftw_config_$timestamp
    echo "proxy_port=$proxy_port" >> ftw_config_$timestamp
}

read -p "Use a proxy server? Enter y/n: " proxy_bool

while [[ "$proxy_bool" != "y" && "$proxy_bool" != "n" ]]
do
    read -p "Invalid entry. Please enter y/n: " proxy_bool
done

if [[ "$proxy_bool" == "y" ]]
then
    proxy_config
elif [[ "$proxy_bool" == "n" ]]
then
    echo ""
fi


# Define time settings

function time_config {
    read -p "Change current NTP version (4)? Enter y/n: " ntp_ver_bool
    echo ""

    while [[ "$ntp_ver_bool" != "y" && "$ntp_ver_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " ntp_ver_bool
    done

    if [[ "$ntp_ver_bool" == "y" ]]
    then
        read -p "Enter desired NTP version number (1-4): " ntp_ver

        while [[ $(("$ntp_ver")) -lt 1 || $(("$ntp_ver")) -gt 4 ]]
        do
            echo "Invalid entry. Please try again."
            read -p "Enter desired NTP version number (1-4): " ntp_ver
        done

        echo "ntp_primary_version=$ntp_ver" >> ftw_config_$timestamp
        echo "ntp_secondary_version=$ntp_ver" >> ftw_config_$timestamp
    elif [[ "$ntp_ver_bool" == "n" ]]
    then
        echo "ntp_primary_version=4" >> ftw_config_$timestamp
        echo "ntp_secondary_version=4" >> ftw_config_$timestamp
    fi

    read -p "Change Check Point default NTP servers? Enter y/n: " ntp_change_bool
    echo ""
    
    while [[ "$ntp_change_bool" != "y" && "$ntp_change_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " ntp_change_bool
    done

    if [[ "$ntp_change_bool" == "n" ]]
    then
        echo "ntp_primary=ntp.checkpoint.com" >> ftw_config_$timestamp
        echo "ntp_primary=ntp2.checkpoint.com" >> ftw_config_$timestamp
    elif [[ "$ntp_change_bool" == "y" ]]    
    then
        read -p "Enter primary NTP server (IP or FQDN): " ntp_primary

        while [[ -z "$ntp_primary" ]]
        do
            echo "NTP server address cannot be empty. Please try again."
            read -p "Enter primary NTP server (IP or FQDN): " ntp_primary
            echo ""
        done

        echo "ntp_primary=$ntp_primary" >> ftw_config_$timestamp

        read -p "Enter secondary NTP server (IP or FQDN) (Enter to skip): " ntp_secondary
        echo "ntp_secondary=$ntp_secondary" >> ftw_config_$timestamp
    fi

    read -p "Enter timezone (in tz database format, e.g., America/Los_Angeles): " timezone
    echo ""

    while [[ -z "$timezone" ]]
    do
        echo "Timezone cannot be empty. Please try again."
        read -p "Enter timezone (in tz database format, e.g., America/Los_Angeles): " timezone
        echo ""
    done

    echo "timezone='$timezone'" >> ftw_config_$timestamp
}

read -p "Configure NTP? Enter y/n: " ntp_bool
echo ""

while [[ "$ntp_bool" != "y" && "$ntp_bool" != "n" ]]
do
    read -p "Invalid entry. Please enter y/n: " ntp_bool
done

if [[ "$ntp_bool" == "y" ]]
then
    time_config
elif [[ "$ntp_bool" == "n" ]]
then
    echo "NTP disabled."
    echo ""
    echo "Please manually configure date and time in the web UI "
    echo "after configuration is complete and device has rebooted."
    echo ""
fi


# Other functions

function sic_key {
    read -p "Enter SIC key: " -s sic_key1
    echo
    read -p "Enter SIC key again: " -s sic_key2
    echo ""

    while [[ ${#sic_key1} -lt 4 || ${#sic_key2} -lt 4 ]] || [[ "$sic_key1" != "$sic_key2" ]]
    do
        echo "Invalid entry. Keys must match and be at least 4 characters. Please try again."
        read -p "Enter SIC key: " -s sic_key1
        echo
        read -p "Enter SIC key again: " -s sic_key2
        echo ""
    done

    sic_key=$sic_key1

    echo "ftw_sic_key=$sic_key" >> ftw_config_$timestamp
    echo ""
}

function mgmt_username_pass {
    read -p "Change GAIA default \"admin\" username? Enter y/n: " admin_username_bool

    while [[ "$admin_username_bool" != "y" && "$admin_username_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " admin_username_bool
    done

    if [[ "$admin_username_bool" == "y" ]]
    then
        read -p "Enter desired username: " admin_username_new

        while [[ -z "$admin_username_new" ]]
        do
            echo "Username cannot be empty. Please try again."
            read -p "Enter desired username: " admin_username_new
            echo ""
        done

        echo "mgmt_admin_radio=new_admin" >> ftw_config_$timestamp
        echo "mgmt_admin_name=$admin_username_new" >> ftw_config_$timestamp
        echo ""
        read -p "Enter desired password: " -s admin_username_new_pass1
        echo ""
        read -p "Enter desired password again: " -s admin_username_new_pass2
        echo ""

        while [[ "$admin_username_new_pass1" != "$admin_username_new_pass2" ]]
        do
        echo "Passwords do not match! Please try again."
        read -p "Enter desired password: " -s admin_username_new_pass1
        echo ""
        read -p "Enter desired password again: " -s admin_username_new_pass2
        echo ""
        done

        admin_username_new_pass=$admin_username_new_pass1

        echo "mgmt_admin_passwd=$admin_username_new_pass" >> ftw_config_$timestamp
        echo ""
    else
        echo "mgmt_admin_radio=gaia_admin" >> ftw_config_$timestamp
        echo ""
    fi
}

function admin_pass {
    read -p "Change admin password entered during install? Enter y/n: " admin_pass_bool
    echo ""

    while [[ "$admin_pass_bool" != "y" && "$admin_pass_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " admin_pass_bool
    done

    if [[ "$admin_pass_bool" == "y" ]]
    then
        read -p "Enter desired admin password: " -s admin_pass1
        echo ""
        read -p "Enter desired admin password again: " -s admin_pass2
        echo ""

        while [[ -z "$admin_pass1" || -z "$admin_pass2" ]] || [[ "$admin_pass1" != "$admin_pass2" ]]
        do
            echo "Passwords cannot be empty and must match. Please try again."
            read -p "Enter desired admin password: " -s admin_pass1
            echo ""
            read -p "Enter desired admin password again: " -s admin_pass2
            echo ""
        done

        admin_pass=$admin_pass1

        admin_hash=$(cpopenssl passwd -6 $admin_pass)
        echo ""
        echo "The resulting hash is: $admin_hash"
        echo "admin_hash='$admin_hash'" >> ftw_config_$timestamp
        echo ""
    fi
}

function ha_method {
    echo "Will this cluster use ClusterXL or VRRP?"
    echo ""
    echo "(1) ClusterXL"
    echo "(2) VRRP"
    echo ""
    read -p "Enter 1-2: " ha_method
    echo ""

    while [[ $(("$ha_method")) -lt 1 || $(("$ha_method")) -gt 2 ]] || [[ -z "$ha_method" ]]
    do
        echo "Invalid entry. Please try again."
        read -p "Enter 1-2: " ha_method
    done

    if [[ "$ha_method" == "1" ]]
    then
        echo "ClusterXL selected"
        echo "gateway_cluster_member=true" >> ftw_config_$timestamp
        echo ""
    elif [[ "$ha_method" == "2" ]]
    then
        echo "VRRP selected"
        echo "gateway_cluster_member=false" >> ftw_config_$timestamp
        echo ""
    fi
}

function mds_intf {
    echo "Please define the MDS Leading VIP interface. Options are below: "
    echo ""
    list_intfs
    echo ""
    intf_array_len=$(( ${#intf_array[@]} - 1 ))
    read -p "Enter desired interface (0-$intf_array_len): " mds_intf

    while [[ $(("$mds_intf")) -lt 0 || $(("$mds_intf")) -gt $(("$intf_array_len")) ]]
    do
        echo "Invalid entry. Please try again."
        read -p "Enter desired interface (0-$intf_array_len): " mds_intf
        echo ""
    done

    echo "install_mds_interface=${intf_array[$mds_intf]}" >> ftw_config_$timestamp
    echo ""
}

function maas_enroll {
    read -p "Would you like to connect this device to Smart-1 Cloud (auth token required)? Enter y/n: " maas_enroll_bool
    
    while [[ "$maas_enroll_bool" != "y" && "$maas_enroll_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " maas_enroll_bool
    done

    if [[ "$maas_enroll_bool" == "y" ]]
    then
        read -p "Enter your authentication token: " auth_key

        while [[ -z "$auth_key" ]]
        do
            echo "Authentication token must not be empty. Please try again."
            read -p "Enter your authentication token: " auth_key
        done

        echo "maas_authentication_key=$auth_key" >> ftw_config_$timestamp
        echo ""
    elif [[ "$maas_enroll_bool" == "n" ]]
    then
        echo ""
    fi
}

function data_sharing {
    read -p "Change defaults for communicating with User Center? Enter y/n: " uc_choice
    echo ""

    while [[ "$uc_choice" != "y" ]] && [[ "$uc_choice" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " uc_choice
    done

    if [[ "$uc_choice" == "y" ]]
    then
        read -p "Download info from User Center? Enter y/n: " download_info

        while [[ "$download_info" != "y" ]] && [[ "$download_info" != "n" ]]
        do
            echo "Invalid entry. Please enter y for Yes or n for No."
            read -p "Download info from User Center? Enter y/n: " download_info
            echo ""
        done

        read -p "Upload info to User Center? Enter y/n: " upload_info

        while [[ "$upload_info" != "y" ]] && [[ "$upload_info" != "n" ]]
        do
            read -p "Invalid entry. Please enter y/n: " upload_info
        done

        read -p "Upload crash data (which may contain PII)? Enter y/n: " upload_crash_data

        while [[ "$upload_crash_data" != "y" ]] && [[ "$upload_crash_data" != "n" ]]
        do
            read -p "Invalid entry. Please enter y/n: " upload_crash_data
        done

        if [[ "$download_info" == "y" ]]
        then
            echo "download_info=true" >> ftw_config_$timestamp
        elif [[ "$download_info" == "n" ]]
        then
            echo "download_info=false" >> ftw_config_$timestamp
        fi

        if [[ "$upload_info" == "y" ]]
        then
            echo "upload_info=true" >> ftw_config_$timestamp
        elif [[ "$upload_info" == "n" ]]
        then
            echo "upload_info=false" >> ftw_config_$timestamp
        fi

        if [[ "$upload_crash_data" == "y" ]]
        then
            echo "upload_crash_data=true" >> ftw_config_$timestamp
        elif [[ "$upload_crash_data" == "n" ]]
        then
            echo "upload_crash_data=false" >> ftw_config_$timestamp
        fi
    elif [[ "$uc_choice" == "n" ]]
    then
        echo "download_info=true" >> ftw_config_$timestamp
        echo "upload_info=true" >> ftw_config_$timestamp
        echo "upload_crash_data=false" >> ftw_config_$timestamp
    fi
}

function gui_client_acl {
    read -p "Change default web UI access (permits any source)? Enter y/n: " gui_client_acl_bool
    echo ""

    while [[ "$gui_client_acl_bool" != "y" ]] && [[ "$gui_client_acl_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " gui_client_acl_bool
    done

    if [[ "$gui_client_acl_bool" == "y" ]]
    then
        echo "Permit any, specific IP, network, or range of IPs?"
        echo ""
        echo "(1) Any"
        echo "(2) Specific IP"
        echo "(3) Network"
        echo "(4) Range of IPs"
        echo ""
        read -p "Enter 1-4: " gui_client_acl_type
        echo ""

        while [[ $(("$gui_client_acl_type")) -lt 1 || $(("$gui_client_acl_type")) -gt 4 ]] || [[ -z "$gui_client_acl_type" ]]
        do
            echo "Invalid entry. Please try again."
            read -p "Enter 1-4: " gui_client_acl_type
        done

        if [[ "$gui_client_acl_type" == "1" ]]
        then
            echo "Any selected"
            echo "mgmt_gui_clients_radio=any" >> ftw_config_$timestamp
            echo ""
        elif [[ "$gui_client_acl_type" == "2" ]]
        then
            echo "Specific IP selected"
            echo "mgmt_gui_clients_radio=this" >> ftw_config_$timestamp
            read -p "Enter IP address: " gui_client_acl

            while [[ -z "$gui_client_acl" ]]
            do
                echo "IP address cannot be empty. Please try again."
                read -p "Enter IP address: " gui_client_acl
                echo ""
            done

            echo "mgmt_gui_clients_hostname=$gui_client_acl" >> ftw_config_$timestamp
            echo ""
        elif [[ "$gui_client_acl_type" == "3" ]]
        then
            echo "Network selected"
            echo "mgmt_gui_clients_radio=network" >> ftw_config_$timestamp
            read -p "Enter network address (e.g., 10.1.1.0): " gui_client_acl_network

            while [[ -z "$gui_client_acl_network" ]]
            do
                echo "Network address cannot be empty. Please try again."
                read -p "Enter network address (e.g., 10.1.1.0): " gui_client_acl_network
                echo ""
            done

            read -p "Enter subnet mask length in CIDR format (0-32): " gui_client_acl_mask

            while [[ $(("$gui_client_acl_mask")) -lt 0 || $(("$gui_client_acl_mask")) -gt 32 ]]
            do
                echo "Invalid mask length entered. Please try again."
                read -p "Enter subnet mask length in CIDR format (0-32): " gui_client_acl_mask
            done

            echo "mgmt_gui_clients_ip_field=$gui_client_acl_network" >> ftw_config_$timestamp
            echo "mgmt_gui_clients_subnet_field=$gui_client_acl_mask" >> ftw_config_$timestamp
            echo ""
        elif [[ "$gui_client_acl_type" == "4" ]]
        then
            echo "Range of IPs selected"
            echo "mgmt_gui_clients_radio=range" >> ftw_config_$timestamp
            read -p "Enter starting IP: " gui_client_acl_range1

            while [[ -z "$gui_client_acl_range1" ]]
            do
                echo "Starting address cannot be empty. Please try again."
                read -p "Enter starting IP: " gui_client_acl_range1
                echo ""
            done

            read -p "Enter ending IP: " gui_client_acl_range2

            while [[ -z "$gui_client_acl_range2" ]]
            do
                echo "Ending address cannot be empty. Please try again."
                read -p "Enter starting IP: " gui_client_acl_range2
                echo ""
            done

            echo "Range is from $gui_client_acl_range1 to $gui_client_acl_range2"
            echo "mgmt_gui_clients_first_ip_field=$gui_client_acl_range1" >> ftw_config_$timestamp
            echo "mgmt_gui_clients_last_ip_field=$gui_client_acl_range2" >> ftw_config_$timestamp
            echo ""
        fi
    elif [[ "$gui_client_acl_bool" == "n" ]]
    then
        echo "mgmt_gui_clients_radio=any" >> ftw_config_$timestamp
    fi
}

function mds_gui_client_acl {
    read -p "Change default web UI access (permits any source)? Enter y/n: " gui_client_acl_bool
    echo ""

    while [[ "$gui_client_acl_bool" != "y" ]] && [[ "$gui_client_acl_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " gui_client_acl_bool
    done

    if [[ "$gui_client_acl_bool" == "y" ]]
    then
        echo "Permit any or a specific IP?"
        echo ""
        echo "(1) Any"
        echo "(2) Specific IP"
        echo ""
        read -p "Enter 1-2: " gui_client_acl_type
        echo ""

        while [[ $(("$gui_client_acl_type")) -lt 1 || $(("$gui_client_acl_type")) -gt 2 ]] || [[ -z "$gui_client_acl_type" ]]
        do
            echo "Invalid entry. Please try again."
            read -p "Enter 1-2: " gui_client_acl_type
        done

        if [[ "$gui_client_acl_type" == "1" ]]
        then
            echo "Any selected"
            echo "mgmt_gui_clients_radio=any" >> ftw_config_$timestamp
            echo ""
        elif [[ "$gui_client_acl_type" == "2" ]]
        then
            echo "Specific IP selected"
            echo "mgmt_gui_clients_radio=this" >> ftw_config_$timestamp
            read -p "Enter IP address: " gui_client_acl

            while [[ -z "$gui_client_acl" ]]
            do
                echo "IP address cannot be empty. Please try again."
                read -p "Enter IP address: " gui_client_acl
                echo ""
            done

            echo "mgmt_gui_clients_hostname=$gui_client_acl" >> ftw_config_$timestamp
            echo ""
        fi
    elif [[ "$gui_client_acl_bool" == "n" ]]
    then
        echo "mgmt_gui_clients_radio=any" >> ftw_config_$timestamp
    fi
}

function reboot_if_required {
    read -p "Should the device reboot (if required) when config is complete? Enter y/n: " reboot_bool

    while [[ "$reboot_bool" != "y" ]] && [[ "$reboot_bool" != "n" ]]
    do
        read -p "Invalid entry. Please enter y/n: " reboot_bool
    done

    if [[ "$reboot_bool" == "y" ]]
    then
        echo "reboot_if_required=true" >> ftw_config_$timestamp
    elif [[ "$reboot_bool" == "n" ]]
    then
        echo "reboot_if_required=false" >> ftw_config_$timestamp
    fi
}


# Management workflow

# Please note "install_security_managment" is purposefully misspelled. Check Point's
# key variable is misspelled, so we have to use that if we care about things working!

function mgmt_workflow {
    echo "Is this a Primary, Secondary, or Dedicated/Separate SmartEvent or Logging server?"
    echo ""
    echo "(1) Primary"
    echo "(2) Secondary"
    echo "(3) Dedicated SmartEvent/Logging"
    echo ""
    read -p "Enter 1-3: " mgmt_type
    echo ""

    while [[ $(("$mgmt_type")) -lt 1 || $(("$mgmt_type")) -gt 3 ]] || [[ -z "$mgmt_type" ]]
    do
        echo "Invalid entry. Please try again."
        read -p "Enter 1-3: " mgmt_type
    done

    if [[ "$mgmt_type" == "1" ]]
    then
        echo "Primary selected"
        echo "install_security_managment=true" >> ftw_config_$timestamp
        echo "install_mgmt_primary=true" >> ftw_config_$timestamp
        echo ""
        mgmt_username_pass
        gui_client_acl
        data_sharing
        reboot_if_required
    elif [[ "$mgmt_type" == "2" ]]
    then
        echo "Secondary selected"
        echo "install_security_managment=true" >> ftw_config_$timestamp
        echo "install_mgmt_secondary=true" >> ftw_config_$timestamp
        echo ""
        admin_pass
        gui_client_acl
        sic_key
        data_sharing
        reboot_if_required
    elif [[ "$mgmt_type" == "3" ]]
    then
        echo "Dedicated SmartEvent/Logging selected"
        echo "install_security_managment=true" >> ftw_config_$timestamp
        echo ""
        mgmt_username_pass
        gui_client_acl
        sic_key
        data_sharing
        reboot_if_required
    fi
}


# Security Gateway workflow

function sg_workflow {
    echo "Is this a single gateway or cluster member?"
    echo ""
    echo "(1) Single Gateway"
    echo "(2) Cluster Member"
    echo ""
    read -p "Enter 1-2: " gw_type
    echo ""

    while [[ $(("$gw_type")) -lt 1 || $(("$gw_type")) -gt 2 ]] || [[ -z "$gw_type" ]]
    do
        echo "Invalid entry. Please try again."
        read -p "Enter 1-2: " gw_type
    done

    if [[ "$gw_type" == "1" ]]
    then
        echo "Single Gateway selected"
        echo "install_security_gw=true" >> ftw_config_$timestamp
        echo ""
        read -p "Using a dynamically-assigned IP (DAIP) (default is no)? Enter y/n: " daip_bool

        while [[ "$daip_bool" != "y" ]] && [[ "$daip_bool" != "n" ]]
        do
            read -p "Invalid entry. Please enter y/n: " daip_bool
        done

        if [[ "$daip_bool" == "y" ]]
        then
            echo "gateway_daip=true" >> ftw_config_$timestamp
        elif [[ "$daip_bool" == "n" ]]
        then
            echo "gateway_daip=false" >> ftw_config_$timestamp
        fi

        admin_pass
        sic_key
        maas_enroll
        data_sharing
        reboot_if_required
    elif [[ "$gw_type" == "2" ]]
    then
        echo "Cluster Member selected"
        echo "install_security_gw=true" >> ftw_config_$timestamp
        echo "gateway_cluster_member=true" >> ftw_config_$timestamp
        echo ""
        admin_pass
        ha_method
        sic_key
        maas_enroll
        data_sharing
        reboot_if_required
    fi
}


# Standalone workflow

function standalone_workflow {
    echo "Is this a single gateway or cluster member?"
    echo ""
    echo "(1) Single Gateway"
    echo "(2) Cluster Member"
    echo ""
    read -p "Enter 1-2: " gw_type
    echo ""

    while [[ $(("$gw_type")) -lt 1 || $(("$gw_type")) -gt 2 ]] || [[ -z "$gw_type" ]]
    do
        echo "Invalid entry. Please try again."
        read -p "Enter 1-2: " gw_type
    done

    if [[ "$gw_type" == "1" ]]
    then
        echo "Single Gateway selected"
        echo "install_security_gw=true" >> ftw_config_$timestamp
        echo ""
        echo "Will the combined management be primary or secondary?"
        echo ""
        echo "(1) Primary"
        echo "(2) Secondary"
        echo ""
        read -p "Enter 1-2: " standalone_mgmt_type

        while [[ $(("$standalone_mgmt_type")) -lt 1 || $(("$standalone_mgmt_type")) -gt 2 ]] || [[ -z "$standalone_mgmt_type" ]]
        do
            echo "Invalid entry. Please try again."
            read -p "Enter 1-2: " standalone_mgmt_type
        done

        if [[ "$standalone_mgmt_type" == "1" ]]
        then
            echo "Primary selected"
            echo "install_security_managment=true" >> ftw_config_$timestamp
            echo "install_mgmt_primary=true" >> ftw_config_$timestamp
            echo ""
            mgmt_username_pass
            sic_key
            gui_client_acl
            data_sharing
            reboot_if_required
        elif [[ "$standalone_mgmt_type" == "2" ]]
        then
            echo "Secondary selected"
            echo "install_security_managment=true" >> ftw_config_$timestamp
            echo "install_mgmt_secondary=true" >> ftw_config_$timestamp
            echo ""
            admin_pass
            sic_key
            gui_client_acl
            data_sharing
            reboot_if_required
        fi
    elif  [[ "$gw_type" = "2" ]]
    then
        echo "Cluster Member selected"
        echo "install_security_gw=true" >> ftw_config_$timestamp
        echo "gateway_cluster_member=true" >> ftw_config_$timestamp
        echo ""
        echo "Will the combined management be primary or secondary?"
        echo ""
        echo "(1) Primary"
        echo "(2) Secondary"
        echo ""
        read -p "Enter 1-2: " standalone_mgmt_type

        while [[ $(("$standalone_mgmt_type")) -lt 1 || $(("$standalone_mgmt_type")) -gt 2 ]] || [[ -z "$standalone_mgmt_type" ]]
        do
            echo "Invalid entry. Please try again."
            read -p "Enter 1-2: " standalone_mgmt_type
        done

        if [[ "$standalone_mgmt_type" == "1" ]]
        then
            echo "Primary selected"
            echo "install_mgmt_primary=true" >> ftw_config_$timestamp
            echo ""
            mgmt_username_pass
            ha_method
            sic_key
            gui_client_acl
            data_sharing
            reboot_if_required
        elif [[ "$standalone_mgmt_type" == "2" ]]
        then
            echo "Secondary selected"
            echo "install_mgmt_secondary=true" >> ftw_config_$timestamp
            echo ""
            admin_pass
            ha_method
            sic_key
            data_sharing
            reboot_if_required
        fi
    fi
}


# MDS workflow

function mds_workflow {
    echo "Is this a Primary, Secondary, or Dedicated/Separate Logging server?"
    echo ""
    echo "(1) Primary"
    echo "(2) Secondary"
    echo "(3) Dedicated Logging"
    echo ""
    read -p "Enter 1-3: " mds_type
    echo ""

    while [[ $(("$mds_type")) -lt 1 || $(("$mds_type")) -gt 3 ]] || [[ -z "$mds_type" ]]
    do
        echo "Invalid entry. Please try again."
        read -p "Enter 1-3: " mds_type
    done

    if [[ "$mds_type" == "1" ]]
    then
        echo "Primary selected"
        echo "install_mds_primary=true" >> ftw_config_$timestamp
        echo ""
        mgmt_username_pass
        mds_intf
        mds_gui_client_acl
        data_sharing
        reboot_if_required
    elif [[ "$mds_type" == "2" ]]
    then
        echo "Secondary selected"
        echo "install_mds_secondary=true" >> ftw_config_$timestamp
        echo ""
        admin_pass
        sic_key
        mds_intf
        mds_gui_client_acl
        reboot_if_required
    elif [[ "$mds_type" == "3" ]]
    then
        echo "Dedicated Logging selected"
        echo "install_mlm=true" >> ftw_config_$timestamp
        echo ""
        admin_pass
        sic_key
        mds_intf
        mds_gui_client_acl
        reboot_if_required
    fi
}


# Standard questions out of the way... on to install types

echo "Are you installing Management, Security Gateway, Standalone (Combined), or MDS?"
echo ""
echo "(1) Management"
echo "(2) Security Gateway"
echo "(3) Standalone"
echo "(4) MDS"
echo ""
read -p "Enter 1-4: " install_type
echo ""

while [[ $(("$install_type")) -lt 1 || $(("$install_type")) -gt 4 ]] || [[ -z "$install_type" ]]
do
    echo "Invalid entry. Please try again."
    read -p "Enter 1-4: " install_type
done

if [[ "$install_type" == "1" ]]
then
    echo "Proceeding with Management install..."
    echo ""
    mgmt_workflow
elif [[ "$install_type" == "2" ]]
then
    echo "Proceeding with Security Gateway install..."
    echo ""
    sg_workflow
elif [[ "$install_type" == "3" ]]
then
    echo "Proceeding with Standalone install..."
    echo ""
    standalone_workflow
elif [[ "$install_type" == "4" ]]
then
    echo "Proceeding with MDS install..."
    echo ""
    mds_workflow
fi


# Final validation

echo "That's it! Checking generated config values..."
echo ""
config_check_result=$(config_system --dry-run -f ftw_config_$timestamp)
echo ""

if [[ "$config_check_result" =~ "Failed" ]]
then
    echo "Validation failed :("
    echo "Please run this command for more details:"
    echo ""
    echo "config_system --dry-run -f ftw_config_$timestamp"
    exit 1
else
    echo "Config validated successfully!"
    echo ""
fi


# Apply for real

read -p "Proceed with applying config? Enter y/n: " proceed_bool

while [[ "$proceed_bool" != "y" ]] && [[ "$proceed_bool" != "n" ]]
do
    read -p "Invalid entry. Please enter y/n: " proceed_bool
done

if [[ "$proceed_bool" == "y" ]]
then
    echo "Applying config now... please stand by."
    echo ""
    config_system -f ftw_config_$timestamp

elif [[ "$proceed_bool" == "n" ]]
then
    echo ""
    echo "Config apply canceled."
    echo ""
    echo "To run manually, issue this command from Expert mode:"
    echo ""
    echo "config_system -f ftw_config_$timestamp"
fi

exit 0