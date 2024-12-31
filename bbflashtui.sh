#!/bin/bash

# Function to display the main menu
main_menu() {
    dialog --clear --backtitle "BeagleBone Black Arch Installer" \
    --title "Main Menu" \
    --menu "Choose an option:" 15 50 4 \
    1 "Prepare microSD" \
    2 "Exit" 2>tempfile

    menu_item=$(<tempfile)
    rm -f tempfile

    case $menu_item in
        1) prepare_microSD ;;
        2) exit 0 ;;
        *) exit 1 ;;
    esac
}

# Function to prepare microSD
prepare_microSD() {
    dialog --clear --backtitle "BeagleBone Black Arch Installer" \
    --title "Prepare microSD" \
    --msgbox "Press OK to start preparing the microSD card." 10 40

    username="$(who am i | awk '{print $1}')"
    if [[ $USER -eq root ]]; then
        fuser -k /home/$username/mnt 2>/dev/null
        umount -f /home/$username/mnt 2>/dev/null
        umount -f /dev/sdd 2>/dev/null

        rm -r /home/$username/mnt 2>/dev/null
        mkdir /home/$username/mnt 2>/dev/null
        dd if=/dev/zero of=/dev/sdd bs=1M count=8 2>/dev/null
        sfdisk -f --delete /dev/sdd >/dev/null

        dialog --infobox "Partitions deleted" 3 30
        sleep 1

        echo -e 'start=2048 size=+ type=L\n' | sfdisk --no-reread /dev/sdd >/dev/null
        dialog --infobox "Creating new partition" 3 30
        sleep 1

        mkfs.ext4 /dev/sdd1 >/dev/null 2>/dev/null
        mount /dev/sdd1 /home/$username/mnt

        dialog --infobox "Extracting tarball to microSD" 3 40
        bsdtar -xpf ArchLinuxARM-am33x-latest.tar.gz -C mnt >/dev/null

        dialog --infobox "Syncing" 3 20
        sync >/dev/null

        dd if=mnt/boot/MLO of=/dev/sdd count=1 seek=1 conv=notrunc bs=128k >/dev/null 2>/dev/null
        dd if=mnt/boot/u-boot.img of=/dev/sdd count=2 seek=1 conv=notrunc bs=384k >/dev/null 2>/dev/null

        cp /home/$username/ArchLinuxARM-am33x-latest.tar.gz /home/$username/mnt/home/alarm/
        cp /home/$username/bbb_eMMC.sh /home/$username/mnt/home/alarm
        sync

        umount mnt
        sync

        dialog --msgbox "DONE! Remove the microSD & insert it into the BeagleBone Black. Hold the button near the microSD slot while you apply power. Let go once all lights begin flashing." 10 50
    else
        dialog --msgbox "Must be ran as root!" 5 20
        exit 1
    fi
}

# Main loop
while true; do
    main_menu
done
