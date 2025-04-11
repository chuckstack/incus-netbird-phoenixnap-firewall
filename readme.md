# Summary

This is the repository behind the <https://chuck-stack.org> instructions for creating an Incus + Netbird + PhoenixNAP hybrid cloud services.

This repository creates an alternative to AWS EC2 with the advantage that you can use the same technology everywhere. This gives you the following advantages:

- You minimize the number of experts because you use Incus and Linux everywhere (cloud, on-premise, desktop).
- You simply your network because you use Netbird to connect the cloud + offices + remote workers (same technology everywhere).

We love this solution because:

- Bare metal EC2 solutions are between 1/3 and 1/6 the cost of AWS EC2 solutions.
- We use well understood and open source technologies.

## Instructions

To learn more, see the following tutorial and discussion: [Hybrid Cloud Strategy: Incus + Netbird + PhoenixNAP](https://www.chuck-stack.org/ls/blog-incus-netbird-phoenixnap.html)

## Notes and TODOs

- The nftables rules are hard-coded to block the following public interfaces: bond0* and enp1s0f*.
  - The problem is these values can change from machine to machine and bare-metal provider to provider.
- We need a more comprehensive way to discover interfaces we want to block.
  - One attempt is to use: `MAIN_INTERFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\S+')`
  - The challenge with this approach is that it does not capture all interfaces we wish to block.
