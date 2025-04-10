# variables
# If you need to make additional network bridges, simply change the 'aa' to 'ab', 'ac', 'ad', ....
INCUS_NETWORK=incusbr-iso-aa
INCUS_PROFILE=isolated-aa
INCUS_ACL=public-only
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

echo

echo "---- profile ----"
incus profile show $INCUS_PROFILE
echo

echo "---- network ----"
incus network show $INCUS_NETWORK
echo

echo "---- launch instance ----"
echo incus launch images:debian/12/cloud delme-debian-iso-01 --profile $INCUS_PROFILE
echo

echo "---- show acl ----"
echo incus network acl show $INCUS_ACL
echo
