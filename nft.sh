#!/bin/bash
# Install nftables
DEBIAN_FRONTEND=noninteractive sudo apt-get install nftables -y

# Enable and start nftables service
sudo systemctl enable nftables
sudo systemctl start nftables

# Set my IP if you wish to allow ssh from it - uncomment this and below statements if needed
#MY_IP_ADDRESS=x.x.x.x
#MY_IP6_ADDRESS=x:x:x:x

# Find my IP addresses
##curl -4 ifconfig.me #ip-v4
##curl -6 ifconfig.me #ip-v6

# Variables - these should not change
NETBIRD_NETWORK=wt0
INCUS_NETWORK=incusbr0
NFT_TABLE=filter

# Get network interface details
MAIN_INTERFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\S+')
INCUS_SUBNET=$(ip -4 addr show $INCUS_NETWORK | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
INCUS_SUBNET_V6=$(ip -6 addr show $INCUS_NETWORK | grep -oP '(?<=inet6\s)[0-9a-f:]+/\d+' | grep -v '^fe80')

# Check to ensure all interfaces exist
for interface in "$NETBIRD_NETWORK" "$INCUS_NETWORK" "$MAIN_INTERFACE"; do
    if ! ip link show "$interface" >/dev/null 2>&1; then
        echo
        echo "ERROR: Interface $interface not found - stopping!!!"
        echo
        exit 1
    fi
done

# Create nftables rules
sudo nft flush ruleset

sudo nft -f - <<EOF
table inet ${NFT_TABLE} {
    chain input {
        type filter hook input priority 0; policy drop;

        # Allow loopback
        iifname "lo" accept

        # Allow established and related connections
        ct state established,related accept

        # Allow NetBird network
        iifname "${NETBIRD_NETWORK}" accept

        # Allow Incus network
        iifname "${INCUS_NETWORK}" accept

        # Allow SSH from specific IP (uncomment and modify as needed)
        #ip saddr ${MY_IP_ADDRESS} tcp dport 22 accept
        #ip6 saddr ${MY_IP6_ADDRESS} tcp dport 22 accept

        # Allow SSH from anywhere (uncomment if needed)
        #tcp dport 22 accept

        #log prefix "nftables-input-dropped: " flags all counter drop
        log prefix "nftables-input-dropped: " drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow forwarding between Incus and main interface
        iifname "${INCUS_NETWORK}" oifname "${MAIN_INTERFACE}" accept
        iifname "${MAIN_INTERFACE}" oifname "${INCUS_NETWORK}" accept

        #log prefix "nftables-forward-dropped: " flags all counter drop
        log prefix "nftables-forward-dropped: " drop
    }

    chain output {
        type filter hook output priority 0; policy accept;

        # Allow loopback
        oifname "lo" accept

        # Allow established and related connections
        ct state established,related accept

        # Allow NetBird network
        oifname "${NETBIRD_NETWORK}" accept

        # Allow Incus network
        oifname "${INCUS_NETWORK}" accept

        # Allow SSH output
        tcp sport 22 accept
    }
}

table ip nat {
    chain postrouting {
        type nat hook postrouting priority 100;

        # NAT for IPv4
        ip saddr ${INCUS_SUBNET} oifname "${MAIN_INTERFACE}" masquerade
    }
}

table ip6 nat {
    chain postrouting {
        type nat hook postrouting priority 100;

        # NAT for IPv6
        ip6 saddr ${INCUS_SUBNET_V6} oifname "${MAIN_INTERFACE}" masquerade
    }
}
EOF

# Save the nftables rules
sudo nft list ruleset | sudo tee /etc/nftables.conf

