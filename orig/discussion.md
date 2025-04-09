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
- I want to create a separate table, such as `table inet chuck-stack` where we specify our rules. This separation ensures that our configurations don't interfere with those implemented by Netbird and Incus.
- I hope to maintain my nftables configurations in a plain text file using the nftables syntax and manage it through a version control system (like `git`). This script should contain all our custom rules within the `table inet chuck-stack` section. However, this might not be possible since some of the interface names are dynamic.
- We plan to apply our configuration script using the `nft -f <filename>` command. This should help in maintaining a version-controlled, reproducible, and declarative setup.

## Specific Goals for the Server

- I want to ensure no one can gain access to the server from the public interface. Said another way, we only want to access the server through the netbird interface.

## Action Needed

Please attempt to create the first version of this file.

## Proposed Solutions

Below is the proposed solution:

```nft
# Define the custom table
table inet chuck-stack {
    # Define a chain to handle traffic coming into the server via NF_INET_PRE_ROUTING
    chain input {
        type filter hook input priority filter; policy drop;

        # Allow traffic on the loopback interface
        iifname "lo" accept

        # Allow related and established sessions
        ct state related,established accept

        # Allow traffic from the Netbird interface (e.g., wt0)
        iifname "wt0" accept
    }

    # Define a chain to manage forwarding traffic
    chain forward {
        type filter hook forward priority filter; policy drop;

        # Allow forwarding traffic that is related or established
        ct state related,established accept

        # Allow traffic from or to the Netbird interface
        iifname "wt0" accept
        oifname "wt0" accept
    }

    # Define a chain to handle outgoing traffic
    chain output {
        type filter hook output priority filter; policy accept;

        # Generally allow outgoing traffic (custom restrictions can be added as needed)
        # Additional outgoing restrictions can be configured here
    }
}

# Add any additional custom rules below as needed
```
