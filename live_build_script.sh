sudo umount chroot/proc
sudo umount chroot/sys
sudo umount chroot/dev/pts

sudo rm -rf scripts chroot .stage binary binary.img
sudo rm -rf config

sudo lb clean
lb config -b iso -p minimal -a amd64 -d sid --hostname rescue.virtualmaster.cz --bootappend-live "locale=cs_CZ.utf8 noautologin nouser"

sudo lb build
