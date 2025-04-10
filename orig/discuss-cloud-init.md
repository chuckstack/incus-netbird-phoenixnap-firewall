# Summary

I need a #cloud-config file that will do the following:

- block all traffic except for one IP <MY_IP> on ssh
- allow for ssh via both IPv4 and IPv6
- use nftables

## Proposed Solution

Please review the proposed solution.

```yaml
#cloud-config

package_update: true
package_upgrade: true

packages:
  - nftables

write_files:
  - path: /etc/chuck-stack-temp.conf
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
          tcp dport 22 ip saddr <MY_IP> accept
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
  - systemctl enable nftables
  - systemctl start nftables
  - nft -f /etc/chuck-stack-temp.conf
  - systemctl restart nftables

final_message: "The system is now configured with nftables firewall allowing SSH only from authorized IP addresses"
```
