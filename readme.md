# Summary

This is the repository behind the <https://chuck-stack.org> instructions for creating an Incus + Netbird + PhoenixNAP hybrid cloud services. It represents the most up-to-date detals from the following articles:

- [chuck-stack Incus + Netbird + PhoenixNAP](https://www.chuck-stack.org/ls/blog-incus-netbird-phoenixnap.html)
- [chuck-stack Isolated Network Bridge](https://www.chuck-stack.org/ls/blog-incus-netbird-phoenixnap-isolated.html)

This repository creates an alternative to AWS EC2 with the advantage that you can use the same technology everywhere. This gives you the following advantages:

- You minimize the number of experts because you use Incus and Linux everywhere (cloud, on-premise, desktop).
- You simply your network because you use Netbird to connect the cloud + offices + remote workers (same technology everywhere).

We love this solution because:

- Bare metal EC2 solutions are between 1/3 and 1/6 the cost of AWS EC2 solutions.
- We use well understood and open source technologies.

## Getting Started

We recommend you use [PhoenixNAP](https://phoenixnap.com/bare-metal-cloud) as your bare metal cloud provider.

We assume that Incus will run on a Debian (or derivative like Ubuntu) server for the following reasons:

- The Incus project most commonly installs Incus on Debian-based instances.
- Many bare-metal service providers offer Debian servers as a default option.

### Assumptions

We assume the following:

- You have already fired up a test server in your bare metal cloud provider.
- You ran `ip a` to see the network interfaces that are provided to your machine by default.
- Your bare metal cloud provider does not implement any firewall rules by default.
- Your bare metal cloud provider supports `cloud-init` to configure your server by default.

### Create Temporary Firewall

Copy and paste the [cloud-init](./cloud-init.md) #cloud-config text into the appropriate text box when launching your new server. Note to follow the indicated directions/actions.

This will create a temporary nftables firewall to protect your server until you are ready to move forward.

## Install Incus and Netbird

Details discussed here: <https://www.chuck-stack.org/ls/blog-incus-netbird-phoenixnap.html>

## Lock It Down

After you have:
- installed Netbird and Incus
- confirmed you can ssh using Netbird url
- given your user a password so that you have backup option via a web terminal/console

... perform the following to remove the chuck-stack-temp and deploy the final [chuck-stack firewall rules](./chuck-stack.conf).

```bash
sudo nft delete table inet chuck-stack-temp # delete temp rules
sudo nft -f ./chuck-stack.conf # make new rules active immediately
sudo cp ./chuck-stack.conf /etc/nftables.conf # make new rules persist
```

Notes:

- We went to great effort to document the [chuck-stack.conf](./chuck-stack.conf) configuration file
- The above bash commands assume you used the cloud-init script to create the chuck-stack-temp firewall rule
- As a result, you are ok with replacing the current nftables.conf with the contents in chuck-stack.conf
- You should NOT restart the nftables service because incus and netbird do not automatically restart the rules immediately

## Instructions

To learn more, see the following tutorial and discussion: [Hybrid Cloud Strategy: Incus + Netbird + PhoenixNAP](https://www.chuck-stack.org/ls/blog-incus-netbird-phoenixnap.html)

## Notes and TODOs

- The nftables rules are hard-coded to block the following public interfaces: bond0* and enp1s0f*.
  - The problem is these values can change from machine to machine and bare-metal provider to provider.
- We need a more comprehensive way to discover interfaces we want to block.
  - One attempt is to use: `MAIN_INTERFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\S+')`
  - The challenge with this approach is that it does not capture all interfaces we wish to block.
