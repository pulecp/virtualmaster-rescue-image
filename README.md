rescue-image
============

Creating minimal rescue image from debian. Following tutorial is tested on Ubuntu 12.04.

## Debian live image

* install `live-build` on your system (older package was named live-magic)

        apt-get install live-build

* run `live_build_script.sh` (you can edit it by yourself) from live directory

        mkdir live
        cd live
        . ../live_build_script.sh
    
* now all needed is in `./binary` folder

## Editing initrd

* editing initrd because sid distribution of debian was in progress

        cd binary
        mkdir initrd
        cd initrd
        MY_PWD_INITRD=`pwd`

* unpack initrd (edit ramdisk name by current version in folder)

        zcat ../initrd.img-3.2.0-4-amd64 | cpio -i

* copy own boot script `vmrescue` into `./scripts`

        cp ../../vmrescue ./scripts
        
* minimize initrd to enable boot on 64MB RAM by removing needless kernel modules in following directory (edit name of kernel by current version in path of cd command) you can remove all *.ko* modules in directories without some mentioned below !!!

        cd /lib/modules/3.2.0-4-amd64/kernel/drivers
        # DO NOT REMOVE
        ./cdrom/cdrom.ko
        ./block/xen-blkback/xen-blkback.ko
        ./block/xen-blkfront.ko
        ./block/loop.ko
        # END OF 'DO NOT REMOVE'
        # FOLLOWING COMMAND REMOVE ALL .ko FILES IN CURRENT DIRECTORY AND SUBDIRECTORIES
        find ./ \( -iname "*.ko" ! -iname "cdrom.ko" ! -iname xen-blkback.ko ! -iname xen-blkfront.ko ! -iname loop.ko \) -exec rm -f {} \;


* when you finish editing of initrd go back to root directory initrd which we created (edit ram disk name by current version)

        cd $MY_PWD_INITRD
        rm root/.bash_history
        find | cpio -H newc -o > ../initrd.img-3.2.0-4-amd64  #you can backup original initrd by rename
        cd ..
        gzip -9 initrd.img-3.2.0-4-amd64
        mv initrd.img-3.2.0-4-amd64.gz initrd.img-3.2.0-4-amd64

## Editing squash filesystem

* maybe you will need install `squashfs-tools`

        apt-get install squashfs-tools

* now we can unpack squash filesystem and `chroot` into it

        cd binary
        unsquashfs filesystem.squashfs
        mount -t proc proc squashfs-root/proc
        mount -t devpts devpts squashfs-root/dev/pts
        cp packages.txt ./squashfs-root
        chroot squashfs-root

* in chrooted system we generate `locales`, and install what we want and clean cache. To compare what is installed in some old system and new (now pure) system try use [[https://github.com/pulecp/dpkg-without-dependencies]]. Suppose we have list of packages in `packages.txt` file

        sed 's/# en_US.UTF-8/en_US.UTF-8/' -i /etc/locale.gen
        locale-gen
        apt-get update
        apt-get -y install `cat packages.txt`
        apt-get clean

* when we finished editing, remove bash history and exit chroot

        rm ~/.bash_history
        exit

* pack squash filesystem, directory or files after option *-e* will be ommited

        umount ./squashfs-root/proc
        umount ./squashfs-root/dev/pts
        rm filesystem.squashfs	#you can backup it by rename it
        mksquashfs squashfs-root filesystem.squashfs -e boot -e usr/share/doc -e usr/share/man
        rm -rf squashfs-root

## Creating iso image

* if you followed previous steps, you have to keep tree structure of directory. So leave in directory with `filesystem.squashfs`, create folder named `live` and put into it `filesystem.squashfs`. Then create iso image bootable by xen.
    
        mkdir live
        mv filesystem.squashfs live
        mkisofs -J -o rescue.iso
    
## Boot on XEN

* now we have prepared all needed. Use `xen_config` file as config file for virtual machine. Please edit right name and path of files.
