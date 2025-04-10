# Summary

The purpose of this file is to help me configure a new ubuntu server with the following:
- Netbird
- Incus
- custom nftables rules to make the server secure

## Clean State

Before anything was installed, `sudo nft list ruleset` returned and empty string.

## Netbird

Netbird was installed first. The resulting `sudo nft list ruleset` is captured in post-netbird-install.txt

## Incus

Incus was installed after netbird. The resulting `sudo nft list ruleset` is captured in post-incus-install.txt

It is important to note that incus only changes the `table inet incus` section. All other changes are from netbird.

## General nft Goals

- I want avoid modifying the sections pertaining to Netbird (`table ip filter`, `table ip mangle`, `table ip nat`) and Incus (`table inet incus`) unless absolutely necessary.
- I want to avoid making any of the netbird or incus rules more permissive.
- I want to create a separate table, such as `table inet chuck-stack` where we specify our rules. This separation ensures that our configurations don't interfere with those implemented by Netbird and Incus.
- I hope to maintain my nftables configurations in a plain text file using the nftables syntax and manage it through a version control system (like `git`). This script should contain all our custom rules within the `table inet chuck-stack` section. However, this might not be possible since some of the interface names are dynamic.
- We plan to apply our configuration script using the `nft -f <filename>` command. This should help in maintaining a version-controlled, reproducible, and declarative setup.

## Current Interfaces

❯ ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 xdpgeneric qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    prog/xdp id 270
2: enp1s0f0: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 9000 qdisc mq master bond0 state UP mode DEFAULT group default qlen 1000
    link/ether 3c:ec:ef:b1:ff:de brd ff:ff:ff:ff:ff:ff
3: enp1s0f1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 9000 qdisc mq master bond0 state UP mode DEFAULT group default qlen 1000
    link/ether 3c:ec:ef:b1:ff:de brd ff:ff:ff:ff:ff:ff permaddr 3c:ec:ef:b1:ff:df
5: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 9000 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 3c:ec:ef:b1:ff:de brd ff:ff:ff:ff:ff:ff
6: bond0.2@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 3c:ec:ef:b1:ff:de brd ff:ff:ff:ff:ff:ff
7: bond0.5@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 3c:ec:ef:b1:ff:de brd ff:ff:ff:ff:ff:ff
8: wt0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1280 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/none
9: incusbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 10:66:6a:0f:a6:33 brd ff:ff:ff:ff:ff:ff
21: veth67f1bc68@if20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master incusbr0 state UP mode DEFAULT group default qlen 1000
    link/ether ca:7d:42:b0:d1:7e brd ff:ff:ff:ff:ff:ff link-netnsid 0

## Action Needed

Need a way to dynamically find and set the bond0* and enp1s0f* values. These can be different from server to server.

How would you change the current working version to set the bond0* and enp1s0f* values?

## Current Working Version

```nft
#!/usr/sbin/nft -f

# This configuration blocks all incoming traffic except through Netbird
table inet chuck-stack {
    chain input {
        type filter hook input priority 0; policy accept;

        # Allow established connections
        ct state related,established accept

        # Allow loopback
        iifname "lo" accept

        # Allow Netbird interface (redundant since policy is accept, but explicit)
        iifname "wt0" accept

        # Allow incus bridge (redundant since policy is accept, but explicit)
        iifname "incusbr0" accept

        # Drop traffic from bond0 and its VLANs (public interfaces)
        iifname "bond0*" drop

        # Drop traffic from physical interfaces
        iifname "enp1s0f*" drop
    }
}

# Add any additional custom rules below as needed
# to add: sudo nft -f chuck-stack-2.conf
# to drop: sudo nft delete table inet chuck-stack
```
