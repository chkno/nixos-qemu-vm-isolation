Isolate NixOS QEMU VMs from each other and from the host by using a
private /nix/store image that contains only the VM's dependencies
(like the installer has) rather than a virtio mount of the host's entire
/nix/store.

**Update:** `virtualisation.useNixStoreImage` exists now!  But it builds
the store image at runtime, rather that at build-time, drastically
increasing VM start-up time.
