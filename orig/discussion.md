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

## Specific Goals for the Server

- I want to ensure no one can gain access to the server from the public interface. Said another way, we only want to access the server through the netbird interface. I am concerned that we need to know the name of the public interface to appropriately block traffic. How do we dynamically get the public interface name?

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

Please attempt to create the next version of this file.

## Simple Version

Below is a proposed solution. It has a problem in that it drops just about everything. For example, when I create a new incus container, it cannot get an ipv4 or ipv6 ip address.

```nft
table inet chuck-stack {
    chain input {
        type filter hook input priority filter; policy drop;

        # Allow loopback
        iifname "lo" accept

        # Allow established connections
        ct state related,established accept

        # Allow Netbird interface
        iifname "wt0" accept

        # Everything else is dropped by the policy
    }
}

# Add any additional custom rules below as needed
# to add: sudo nft -f chuck-stack-2.conf
# to drop: sudo nft delete table inet chuck-stack
```

## Duplicate Version

Below is a proposed solution. It has a problem in that is duplicates logic from the other rules.

```nft
#!/usr/sbin/nft -f

table inet chuck-stack {
    chain input {
        type filter hook input priority filter; policy drop;

        # Allow loopback
        iifname "lo" accept

        # Allow established connections
        ct state related,established accept

        # Allow Netbird interface
        iifname "wt0" accept

        # Allow Incus bridge interface traffic
        iifname "incusbr0" accept

        # Allow DHCPv4 and DHCPv6 client traffic
        udp sport { 67, 547 } udp dport { 68, 546 } accept

        # Allow DNS responses
        udp sport 53 accept
        tcp sport 53 accept

        # Allow ICMPv4 for basic network functionality
        ip protocol icmp icmp type {
            echo-request,
            echo-reply,
            destination-unreachable,
            time-exceeded,
            parameter-problem
        } accept

        # Allow ICMPv6 for basic network functionality
        ip6 nexthdr icmpv6 icmpv6 type {
            echo-request,
            echo-reply,
            destination-unreachable,
            packet-too-big,
            time-exceeded,
            parameter-problem,
            nd-router-solicit,
            nd-router-advert,
            nd-neighbor-solicit,
            nd-neighbor-advert,
            mld2-listener-report
        } accept
    }

    chain forward {
        type filter hook forward priority filter; policy drop;

        # Allow established connections
        ct state related,established accept

        # Allow traffic through Incus bridge
        iifname "incusbr0" accept
        oifname "incusbr0" accept

        # Allow Netbird forwarding (managed by Netbird's own rules)
        iifname "wt0" accept
        oifname "wt0" accept
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }
}
```

## Goal Restated

We simply want to block public traffic so that the only way into the server is via the existing netbird rules.
