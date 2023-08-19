# NAS Setup

## ZFS

### enable NFS shares

```sh
sudo zfs set \
    sharenfs="no_subtree_check,all_squash,anonuid=1000,anongid=1000,rw=@192.168.178.0/24" \
    tank/media
```
