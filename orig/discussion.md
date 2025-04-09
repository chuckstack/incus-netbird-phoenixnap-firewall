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

## Goals

I want to better understand how to manage nftables (nft). Here are my specific goals:

- I want to achieve a near declarative state regarding nft configuration.
- I want to be able to apply my own nft configuration without modifying the netbird or incus nft unless my goals specifically require doing so.
- I think I want to have a script on the server that I can execute that will flush the current rules and recreate them as necessary. I do not know if this goal is possible.
