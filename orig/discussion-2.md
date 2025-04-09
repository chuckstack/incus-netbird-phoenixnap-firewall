The current chuck-stack.conf was created as a result of discussion.md. The purpose of discussion-2.md is to improve the current chuck-stack.conf.

Looking at both configurations:

1. Regarding Incus rules vs. chuck-stack rules:
- The Incus rules (in `in.incusbr0`) are more specific, allowing only certain types of traffic (DNS, DHCP, ICMP, etc.)
- The chuck-stack rules are more permissive, with `iifname "incusbr0" accept` allowing all traffic from the incusbr0 interface
- Since both sets of rules are active, the more permissive chuck-stack rules effectively weaken the Incus restrictions by allowing all traffic, not just the specified services

2. Regarding Netbird rules vs. chuck-stack rules:
- The Netbird rules have specific chains for handling related/established connections and specific marking/routing
- The chuck-stack rules are again more permissive, with `iifname "wt0" accept` allowing all traffic from the Netbird interface
- This means the chuck-stack rules do weaken the Netbird security model by bypassing its more granular controls

I want chuck-stack.conf to create as few rules as is possible. Said another way, to not state any rules that do not need to exist. Do not weaken the existing incus or netbird rules. The only goal is to block all outside/public traffic from betting in. The only route into the server should be through netbird.
