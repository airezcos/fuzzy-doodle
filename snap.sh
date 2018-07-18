#!/bin/bash

root_dev=/dev/sda2
var_dev=/dev/sdb
root=/btrfs_root/root
var=/btrfs_root/var
subvolume=snapshots

[ "$UID" = 0 ] || exec sudo "$0" "$@"

if [ -s $root ] || [ -s $var ]; then
  echo Mount point is not empty
  exit
fi

makeSnap() {
  mount -o subvolid=5 $root_dev $root
  mount -o subvolid=5 $var_dev $var
  btrfs sub snap $writeable $root/@ $root/$subvolume/$snap_name
  btrfs sub snap $writeable $var/@var $var/$subvolume/$snap_name
}

bootToTest() {
  subvolume=testing
  writeable=
  snap_name=testSnapshot

  while [ "$1" != "" ]; do
    case $1 in
      su*)
        shift
        subvolume=$1
        ;;
      na*)
        shift
        snap_name=$1
        ;;
      *)
        echo invalid argument
    esac
  done

  makeSnap
  btrfs sub set-default $root/$subvolume/$snap_name
  btrfs sub set-default $var/$subvolume/$snap_name
  umount {$root,$var}
  btrfs sub get-default /
  btrfs sub get-default /var

  read -p 'Reboot to testing snapshot? ' reboot_test
  if [ '$reboot_test' = 'y*' ] || [ '$roboot_test' = 'Y*' ]; then
    reboot
  fi
  exit
}

writeable=\-r
snap_name=$(date '+%y-%m-%d_%H-%M')

while [ "$1" != "" ]; do
  case $1 in
    rw)
      writeable=
      ;;
    na*)
      shift
      snap_name=$1
      ;;
    te*)
      bootToTest
      ;;
    m*)
      mount -o subvolid=5 $root_dev $root
      mount -o subvolid=5 $var_dev $var
      echo "'sudo umount /btrfs_root/\{root,var\}' to unmount"
      exit
      ;;
    *)
      echo invalid argument
      exit
  esac
  shift
done

makeSnap

umount {"$root","$var"}

