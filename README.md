Isolate NixOS QEMU VMs from each other and from the host by using a
squashfs for the VM's /nix/store that contains only the VM's dependencies
(like the installer has) rather than a virtio mount of the host's entire
/nix/store.

**Update:** `virtualisation.useNixStoreImage` exists now!  But it doesn't
work!  :(  See the note in `checks/mount-grep.nix`
