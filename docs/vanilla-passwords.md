After the appliance has been bootstrapped, but before the first-time setup
wizard is ran, it is configured with vanilla passwords.  The exact passwords
used depend on the MAC address of the first network interface of the VM.

Follow the process below to obtain the vanilla passwords for your appliance.

1. Determine the MAC address of the first network interface of the virutal
   machine, e.g., `08:00:27:F0:F3:CF`.
2. Once you have the MAC address, run the following on your laptop to obtain
   the "vanilla passwords pool index".
   ```
   MAC_ADDRESS=<mac address of VM's first network interface>
   printf %02d $(expr $(printf '%d' 0x`md5sum <(echo ${MAC_ADDRESS} | tr 'A-Z' 'a-z') | cut -c1-2`) % 20) ; echo
   ```
   This will give you an index in the range `00-19`.
3. Once you have the "vanilla passwords pool index", the "vanilla passwords"
   can be found by running:
   ```
   index=<the index determined above>
   cat filesystems/MIA-6-4-0-DEV/system/data/private/share/vanilla/${index}.vars
   ```
