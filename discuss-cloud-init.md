# Summary

I need a #cloud-config file that will do the following:

- block all traffic except for one IP <MY_IP> on ssh
- allow for ssh via both IPv4 and IPv6
- use nftables

## Proposed Solution for Initial cloud-init Firewall

```yaml
#cloud-config

package_update: true
#package_upgrade: true

packages:
  - nftables

write_files:
  - path: /etc/nftables.conf
    permissions: '0644'
    content: |
      #!/usr/sbin/nft -f

      # ok to add in addition to any existing rules - worst case scenario that this is more restrictive
      #flush ruleset

      # Created to run one time upon initial boot
      # To be deleted using: sudo nft delete table inet chuck-stack-temp 
      # To find your IPv4: curl -4 ifconfig.me
      # To find your IPv6: curl -6 ifconfig.me


      table inet chuck-stack-temp {
        chain input {
          type filter hook input priority 0; policy drop;

          # Allow established/related connections
          ct state established,related accept

          # Allow loopback traffic
          iif lo accept

          # Allow ICMPv4 for ping and other important ICMP messages
          #ip protocol icmp accept

          # ICMPv6 is important for IPv6 to work correctly
          ip6 nexthdr icmpv6 accept

          # Allow SSH only from specific IPs
          tcp dport 22 ip saddr <MY_IP> accept      # Replace with your IPv4 address
          tcp dport 22 ip6 saddr <MY_IPv6> accept   # Replace with your IPv6 address
        }

        chain forward {
          type filter hook forward priority 0; policy drop;
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }
      }

runcmd:
  - nft -f /etc/nftables.conf
  - systemctl enable nftables

# to show rules: sudo nft list ruleset
# to drop: sudo nft delete table inet chuck-stack-temp
# to show interfaces: ip link show

final_message: "The system is now configured with nftables firewall allowing SSH only from authorized IP addresses"
```

## Change Firewall after Netbird Confirmed

After you have:
- installed Netbird and Incus
- confirmed you can ssh using Netbird url
- given your user a password so that you have backup option via a web terminal/console

... perform the following to remove the chuck-stack-temp and deploy the final chuck-stack firewall rules

```bash
sudo nft delete table inet chuck-stack-temp
sudo nft -f ./chuck-stack.conf
sudo cp ./chuck-stack.conf /etc/nftables.conf
```

Notes:

- the above bash commands assume you used the cloud-init script to create the chuck-stack-temp firewall rule
- as a result, you are ok with replacing the current nftables.conf with the chuck-stack.conf
