
# variables
INCUS_NETWORK=incusbr-iso
INCUS_PROFILE=isolated
INCUS_ACL=public-only

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

# Create and configure an incus acl and apply it to our isolated network bridge
incus network acl rule add $INCUS_ACL ingress action=allow
incus network acl rule add $INCUS_ACL egress action=allow
#incus network acl rule add $INCUS_ACL egress action=allow destination=$INCUS_ISO_DNS/32
#incus network acl rule add $INCUS_ACL egress action=allow destination=$INCUS_ISO_DNS/32 protocol=udp destination_port=53
#incus network acl rule add $INCUS_ACL egress action=allow destination=$INCUS_ISO_DNS/32 protocol=tcp destination_port=53

# Block private networks
incus network acl rule add $INCUS_ACL egress action=reject destination=10.0.0.0/8
incus network acl rule add $INCUS_ACL egress action=reject destination=192.168.0.0/16
incus network acl rule add $INCUS_ACL egress action=reject destination=172.16.0.0/12

incus network set $INCUS_NETWORK security.acls=$INCUS_ACL
incus profile device set $INCUS_PROFILE eth0 security.acls=$INCUS_ACL
incus profile show $INCUS_PROFILE

# Allow $INCUS_NETWORK interface
#sudo iptables -A INPUT -i $INCUS_NETWORK -j ACCEPT
#sudo iptables -A OUTPUT -o $INCUS_NETWORK -j ACCEPT
#sudo ip6tables -A INPUT -i $INCUS_NETWORK -j ACCEPT
#sudo ip6tables -A OUTPUT -o $INCUS_NETWORK -j ACCEPT

# NAT and forwarding rules
#sudo iptables -t nat -A POSTROUTING -s $INCUS_ISO_SUBNET -o $MAIN_INTERFACE -j MASQUERADE
#sudo iptables -A FORWARD -i $INCUS_NETWORK -o $MAIN_INTERFACE -j ACCEPT
#sudo iptables -A FORWARD -i $MAIN_INTERFACE -o $INCUS_NETWORK -j ACCEPT
#sudo ip6tables -t nat -A POSTROUTING -s $INCUS_ISO_SUBNET_V6 -o $MAIN_INTERFACE -j MASQUERADE
#sudo ip6tables -A FORWARD -i $INCUS_NETWORK -o $MAIN_INTERFACE -j ACCEPT
#sudo ip6tables -A FORWARD -i $MAIN_INTERFACE -o $INCUS_NETWORK -j ACCEPT

## lauch instances in this isolated bridge
#incus launch images:debian/12/cloud delme-debian-isolated-01 --profile isolated
## show acl
#incus network acl show public-only
