The root partition of the MIA is encrypted.  Once the safe bootloader has been
successfully installed, the root partition will be automatically decrypted
during boot.  There may be a need to manually decrypt it other than that.
E.g., when bootstrapping the MIA or debugging some aspect of the bootstrapping
process.

There are three variants of the encryption key that could be active: 1) the
default encryption key; 2) the vanilla encryption key; 3) the config-pack
encryption key.


# Default encryption key

The default encryption key is installed during the initial stages of
bootstrapping the appliance.  It is replaced by the vanilla encryption key
when the `safe.postdeploy.sh` is ran.

The default encryption key can be determined by running the following on your
laptop:

```
cat filesystems/MIA-6-4-0-DEV/system/etc/keys/rootfs.key
```

# Vanilla encryption key

The vanilla encryption key is installed when the `safe.postdeploy.sh` is ran
and also when a factory reset is completed.  It is replaced with the
"config-pack encryption key" when the "first-time setup wizard" is completed.

To determine the "vanilla encryption key" you will need the MAC address of the
first network interface of the virutal machine, e.g., `08:00:27:F0:F3:CF`.
Once you have the MAC address, run the following to obtain the "vanilla
passwords pool index".

These commands are to be ran on your laptop.

```
MAC_ADDRESS=<mac address of VM's first network interface>
printf %02d $(expr $(printf '%d' 0x`md5sum <(echo ${MAC_ADDRESS} | tr 'A-Z' 'a-z') | cut -c1-2`) % 20) ; echo
```

This will give you an index in the range `00-19`.

Once you have the "vanilla passwords pool index", the "disk password seed" can
be found by running:

```
index=<the index determined above>
cat filesystems/MIA-6-4-0-DEV/system/data/private/share/vanilla/${index}.vars
```

Once you have the "disk password seed" you can determine the "root partition
encryption key" by running:

```
seed=<disk password seed>
echo -n $( echo "${seed}" | cut -c 1-8 ) | md5sum | cut -f1 -d' '
```

# Config pack encryption key

The config pack encryption key is installed when the "first-time setup wizard"
is ran.  It is replaced with the "vanilla encryption key" when a factory reset
is performed.

To determine the config pack encryption key, first determine the "disk
password seed" and then use that to determine the encryption key.

The "disk password seed" can be determined by following the process below.

1. locate you config pack, e.g., `AFC01.tgz`.
2. extract `./security-pack.tgz` from your config pack.
3. extract `./security.yml` from `security-pack.tgz`.
4. the "disk password seed" is the `disk_password` entry in `./security.yml`.

Once you have the "disk password seed" you can determine the "root partition
encryption key" by running:

```
seed=<disk password seed>
echo -n $( echo "${seed}" | cut -c 1-8 ) | md5sum | cut -f1 -d' '
```
