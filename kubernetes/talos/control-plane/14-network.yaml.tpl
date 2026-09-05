---
apiVersion: v1alpha1
kind: LinkAliasConfig
name: bond0-m0
selector:
  match: glob("{{ .Node.Data.mac }}", mac(link.hardware_addr)) && glob("{{ .Node.Data.driver }}", link.driver)
---
apiVersion: v1alpha1
kind: BondConfig
name: bond0
links:
  - bond0-m0
bondMode: active-backup
mtu: 1500
---
apiVersion: v1alpha1
kind: DHCPv4Config
name: bond0
---
apiVersion: v1alpha1
kind: Layer2VIPConfig
name: 192.168.20.9
link: bond0
---
apiVersion: v1alpha1
kind: VLANConfig
name: bond0.30
vlanID: 30
parent: bond0
mtu: 1500
---
apiVersion: v1alpha1
kind: VLANConfig
name: bond0.70
vlanID: 70
parent: bond0
mtu: 1500