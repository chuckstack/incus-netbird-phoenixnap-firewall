# Variables - these should not change
NETBIRD_NETWORK=wt0
INCUS_NETWORK=incusbr0

# Get network interface details
MAIN_INTERFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\S+')
INCUS_SUBNET=$(ip -4 addr show $INCUS_NETWORK | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
INCUS_SUBNET_V6=$(ip -6 addr show $INCUS_NETWORK | grep -oP '(?<=inet6\s)[0-9a-f:]+/\d+' | grep -v '^fe80')


for interface in "$NETBIRD_NETWORK" "$INCUS_NETWORK" "$MAIN_INTERFACE"; do
    if ! ip link show "$interface" >/dev/null 2>&1; then
        echo "Interface $interface not found"
        exit 1
    fi
done
