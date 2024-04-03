# NAS Setup

## ZFS

### Enable NFS shares

```sh
sudo zfs set \
    sharenfs="no_subtree_check,all_squash,anonuid=1000,anongid=1000,rw=@192.168.178.0/24" \
    tank/media
sudo zfs set \
    sharenfs="no_subtree_check,all_squash,anonuid=1000,anongid=1000,rw=@192.168.178.0/24" \
    tank/backup
sudo zfs set \
    sharenfs="no_subtree_check,all_squash,anonuid=1000,anongid=1000,rw=@192.168.178.0/24" \
    tank/photos
```

```sh
sudo zfs set \
    sharenfs="no_subtree_check,all_squash,anonuid=1000,anongid=1000,rw=@192.168.178.0/24" \
    spool/paperless
sudo zfs set \
    sharenfs="no_subtree_check,all_squash,anonuid=1000,anongid=1000,rw=@192.168.178.0/24" \
    spool/openhab
sudo zfs set \
    sharenfs="no_subtree_check,all_squash,anonuid=1000,anongid=1000,rw=@192.168.178.0/24" \
    spool/audiobooks
sudo zfs set \
    sharenfs="no_subtree_check,all_squash,anonuid=1000,anongid=1000,rw=@192.168.178.0/24" \
    spool/ebooks
```
