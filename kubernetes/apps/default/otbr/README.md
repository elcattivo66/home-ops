# OpenThread Border Router

Dieser Ordner enthält das Deployment des OpenThread Border Routers (OTBR) als Container im Cluster, der die SLZB Ultima als Remote-RCP (Radio Co-Processor) über das Netzwerk nutzt.

## Architektur

```
SLZB Ultima (Remote-RCP, 192.168.30.140:6638)
  └─> OTBR Container (otbr.default.svc, 192.168.30.248:8081)
        ├─ Thread-Netzwerk: ha-thread-9a25
        ├─ MeshLocalPrefix: fd07:1779:251c:d0ad::/64
        └─ OTBR REST API + Web-UI
              └─ matter-server (192.168.30.254:5580)
                    └─ Home Assistant (Matter-Integration)
```

## Komponenten

| Komponente | Details |
|---|---|
| **Image** | `ghcr.io/ownbee/hass-otbr-docker` |
| **Radio** | SLZB Ultima als Remote-RCP via `NETWORK_DEVICE: 192.168.30.140:6638` |
| **REST API** | Port `8081` (`https://otbr.elcattivo.de`) |
| **Web-UI** | Port `7586` (`https://otbr-web.elcattivo.de`) |
| **Persistenz** | kopiur-Backup: PVC `otbr` → `/data` (Thread-Dataset) |

## UniFi Konfiguration

Für die Matter-over-Thread-Kommissionierung über das Handy (BLE-Phase) muss der UniFi-Router eine statische IPv6-Route zum Thread-Mesh-Prefix haben:

- **Destination:** `fd07:1779:251c:d0ad::/64`
- **Gateway / Next Hop:** `fd00:30::248` (OTBR-Pod, IoT-VLAN)
- **Interface:** IoT (VLAN 30)

> **Hinweis:** Thread-Geräte erhalten bei der Kommissionierung IPv6-Adressen in beliebigen ULA-Prefixen (z.B. `fd5c:...`, `fd35:...`), nicht nur im Mesh-Local-Prefix. Die `fc00::/7`-Route im matter-server-Pod (Init-Container) deckt das gesamte Thread-ULA-Spektrum ab; die UniFi-Route deckt das Mesh-Local-Prefix für das kommissionierende Handy ab.

## Thread-Dataset

Das aktive Thread-Dataset (TLV) wird im OTBR unter `/data/thread/` persistiert. Das kopiur-Backup sichert den PVC, damit das Thread-Netzwerk Pod-Neustarts übersteht.

## Troubleshooting

- **Commissioner rejected:** Der REST-Commissioner (`node/commissioner/state`) muss deaktiviert sein, damit matter.js selbst die Commissioner-Rolle übernehmen kann.
- **BoundsExceeded (2) bei der Kommissionierung:** Das Gerät hat ein altes/partielles Thread-Dataset gespeichert — einen Werksreset des Geräts durchführen.
- **BLE-Kommissionierung:** Die matter-server Web-UI im Chrome-Browser nutzen (Web Bluetooth via `/ble`-Proxy); die HA App nutzt ein anderes BLE-Protokoll.
