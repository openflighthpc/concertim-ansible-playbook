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

To determine the "vanilla encryption key" you will need the vanilla `DISKPASS`
which can be obtained by following the instructions in
docs/vanilla-passwords.md

Once you have the `DISKPASS` you can determine the "root partition encryption
key" by running:

```
echo -n $( echo "${DISKPASS}" | cut -c 1-8 ) | md5sum | cut -f1 -d' '
```

# Config pack encryption key

The config pack encryption key is installed when the "first-time setup wizard"
is ran.  It is replaced with the "vanilla encryption key" when a factory reset
is performed.

To determine the config pack encryption key, first determine the
`disk_password` and then use that to determine the encryption key.

The `disk_password` can be determined by following the process below.

1. locate you config pack, e.g., `AFC01.tgz`.
2. extract `./security-pack.tgz` from your config pack.
3. extract `./security.yml` from `security-pack.tgz`.
4. the `disk_password` is the `disk_password` entry in `./security.yml`.

Once you have the `disk_password` you can determine the "root partition
encryption key" by running:

```
echo -n $( echo "${disk_password}" | cut -c 1-8 ) | md5sum | cut -f1 -d' '
```
