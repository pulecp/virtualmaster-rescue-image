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

* editing initrd because (sid distribution of debian was in progress), we need root privileges

        sudo su
        cd binary
        mkdir initrd
        cd initrd
        MY_PWD_INITRD=`pwd`
        INITRD_NAME='initrd.img-3.2.0-4-amd64'
        KERNEL_VERSION='3.2.0-4-amd64'

* unpack initrd (edit ramdisk name by current version in folder)

        zcat ../live/$INITRD_NAME | cpio -i

* copy own boot script `vmrescue` into `./scripts`

        cp ../../../vmrescue ./scripts
        
* minimize initrd to enable boot on 64MB RAM by removing needless kernel modules in following directory (edit name of kernel by current version in path of cd command) you can remove all *.ko* modules in directories without some mentioned below !!!

        cd ./lib/modules/$KERNEL_VERSION/kernel/drivers
        # DO NOT REMOVE
        #       ./cdrom/cdrom.ko
        #       ./block/xen-blkback/xen-blkback.ko
        #       ./block/xen-blkfront.ko
        #       ./block/loop.ko
        # END OF 'DO NOT REMOVE'
        # FOLLOWING COMMAND REMOVE ALL .ko FILES IN CURRENT DIRECTORY AND SUBDIRECTORIES (without specified files after '!')
        find ./ \( -iname "*.ko" ! -iname "cdrom.ko" ! -iname xen-blkback.ko ! -iname xen-blkfront.ko ! -iname loop.ko \) -exec rm -f {} \;


* when you finish editing of initrd go back to root directory initrd which we created (edit ram disk name by current version)

        cd $MY_PWD_INITRD
        find | cpio -H newc -o > ../live/$INITRD_NAME  #you can backup original initrd by rename
        cd ../live
        gzip -9 $INITRD_NAME
        mv $INITRD_NAME.gz $INITRD_NAME

## Editing squash filesystem

* maybe you will need install `squashfs-tools`

        apt-get install squashfs-tools

* now we can unpack squash filesystem and `chroot` into it

        # we should be in ./live/binary/live, still as root
        unsquashfs filesystem.squashfs
        mount -t proc proc squashfs-root/proc
        mount -t devpts devpts squashfs-root/dev/pts
        cp ../../../packages.txt ./squashfs-root
        chroot squashfs-root

* in chrooted system we generate `locales`, and install what we want and clean cache. To compare what is installed in some old system and new (now pure) system try use [[https://github.com/pulecp/dpkg-without-dependencies]]. Suppose we have list of packages in `packages.txt` file

        sed 's/# en_US.UTF-8/en_US.UTF-8/' -i /etc/locale.gen
        locale-gen
        apt-get update
        apt-get -y install `cat packages.txt`
        apt-get clean

* when we finished editing, exit chroot

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
        mkisofs -J -o rescue.iso ./live
    
## Boot on XEN

* now we have prepared all needed. Use `xen_config` file as config file for virtual machine. Please edit right name and path of files.
