# pfSense Configure

1. Firewall Setup

    * Interfaces > Assignments > Add the vtnet1 interface<br>
    * Interfaces > Assignemtns > LAN (vtnet1) > Enable: true / IPv4 Configuration Type: DHCP / Click Save / Click Apply Changes
        
    * Firewall > NAT > Outbound / Select `Manual Outbound NAT rule generation` > Create a new rule by clicking `Add` > Interface WAN / Protocol:Any / Source: Network with source network (10.128.0.0/16) / Destination: Any / Address: Interface Address / Click `Save` / Click `Apply Changes`<br>
    * Firewall > Rules > LAN > Action: Pass / Interface: LAN / Protocol:Any / Source: Network, 10.128.0.0/16 / Destination: Any / Click `Save` / Click `Apply Changes`