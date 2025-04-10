#!/bin/bash

# variables
INCUS_NETWORK=incusbr-iso
INCUS_PROFILE=isolated
INCUS_ACL=public-only
NFT_TABLE=incus-iso-network
INCUS_NAME_SERVERS="8.8.8.8,8.8.4.4"

# Create artifacts
incus network create $INCUS_NETWORK
incus profile show default | incus profile create $INCUS_PROFILE
incus profile device set $INCUS_PROFILE eth0 network=$INCUS_NETWORK
incus network acl create $INCUS_ACL

# Get network interface details
MAIN_INTERFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\S+')
echo MAIN_INTERFACE=$MAIN_INTERFACE
INCUS_ISO_SUBNET=$(ip -4 addr show $INCUS_NETWORK | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
echo INCUS_ISO_SUBNET=$INCUS_ISO_SUBNET
INCUS_ISO_SUBNET_V6=$(ip -6 addr show $INCUS_NETWORK | grep -oP '(?<=inet6\s)[0-9a-f:]+/\d+' | grep -v '^fe80')
echo INCUS_ISO_SUBNET_V6=$INCUS_ISO_SUBNET_V6
INCUS_ISO_DNS=${INCUS_ISO_SUBNET%/*}
echo INCUS_ISO_DNS=$INCUS_ISO_DNS

# Check to ensure all interfaces exist
for interface in "$MAIN_INTERFACE"; do
    if ! ip link show "$interface" >/dev/null 2>&1; then
        echo
        echo "ERROR: Interface $interface not found - stopping!!!"
        echo
        exit 1
    fi
done

# Create and configure an incus acl and apply it to our isolated network bridge
incus network acl rule add $INCUS_ACL ingress action=allow
incus network acl rule add $INCUS_ACL egress action=allow

# Block private networks
incus network acl rule add $INCUS_ACL egress action=reject destination=10.0.0.0/8
incus network acl rule add $INCUS_ACL egress action=reject destination=192.168.0.0/16
incus network acl rule add $INCUS_ACL egress action=reject destination=172.16.0.0/12

incus network set $INCUS_NETWORK security.acls=$INCUS_ACL
incus network set $INCUS_NETWORK dns.nameservers=$INCUS_NAME_SERVERS
incus profile device set $INCUS_PROFILE eth0 security.acls=$INCUS_ACL
incus profile show $INCUS_PROFILE

# Create nftables rules
#sudo nft 'add table inet incus' #not needed
sudo nft '
add table inet '$NFT_TABLE' {
    chain input {
        type filter hook input priority 0; policy accept;
        iifname '$INCUS_NETWORK' accept
    }
    chain output {
        type filter hook output priority 0; policy accept;
        oifname '$INCUS_NETWORK' accept
    }
    chain forward {
        type filter hook forward priority 0; policy accept;
        iifname '$INCUS_NETWORK' oifname '$MAIN_INTERFACE' accept
        iifname '$MAIN_INTERFACE' oifname '$INCUS_NETWORK' accept
    }
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        ip saddr '$INCUS_ISO_SUBNET' oifname '$MAIN_INTERFACE' masquerade
        ip6 saddr '$INCUS_ISO_SUBNET_V6' oifname '$MAIN_INTERFACE' masquerade
    }
}'

## lauch instances in this isolated bridge
#incus launch images:debian/12/cloud delme-debian-isolated-01 --profile isolated
## show acl
#incus network acl show public-only

