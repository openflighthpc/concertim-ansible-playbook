# First time setup wizard

Before the appliance can be used you will need to run the first-time setup
wizard.  To do the appliance will need to have access to USB devices inserted
into your laptop and you will need a configuration pack.

## Ensure Virtual box can access usb devices

On Linux, the user running VirtualBox needs to a member of the `vboxusers`
group to allow VirtualBox access to the laptop's USB devices.

```
sudo adduser $USER vboxusers
```

Log out and in again.  Perhaps even reboot the machine.

On MacOS, you may or may not need some similar configuration.

## Ensure VirtualBox guest additions

Virtual machines need to have had the VirtualBox guest additions installed in
order to be able to access the USB device.  They should have already been
installed as part of the bootstrapping process, if not, follow the
instructions there.

## Run the setup wizard

Prior to the first-time setup wizard being completed, the appliance is only
available on a link local address.  To run the setup wizard follow the process
below on your laptop:

Find link local address of the machine.  On Linux, this can be done with:

```
avahi-browse -d appliance.local --all --terminate --resolve
```

The output of the above will contain a link local address in the format
`169.254.x.y`.  Visit this address in your browser.

Note: the wizard is available over HTTP not HTTPS.  You may need to adjust
your laptop's routes.

Once you have access to the first-time setup wizard:

1. Click "Insert USB key"
2. Insert the USB key containing the appliance config pack into your laptop.
3. Mount the USB key on the VM, by selecting it from the `Devices -> USB`
   menu.  It is probably the `Generic Mass Storage` entry.

### Public network configuration

The "Public interface IP address" should be an address that is on the
VirtualBox network used for the VMs `eth1` network interface.  This is
probably not a public IP address as such.  I have had success using
`172.18.1.99`.  

The "Public network mask" should be the network mask that is configured for
the VirtualBox network used for hte VMs `eth1`.  I have had success using
`255.255.255.0`.

The "Public gateway" should be the IP address of your laptop on the VirtualBox
network used for the VM's `eth1`.  This is probably `172.18.1.1`

Once these details are entered, click "Proceed" and by patient.  Installing
the security pack takes some time.

### Secure appliance interface

Opening the secure appliance interface will fail unless your laptop can
resolve the appliance's command name to its IP address.  The easiest way to
fix this is to add an entry to `/etc/hosts`.  Instructions on what that entry
should be are provided by the first-time setup wizard.  Once you've addressed
the above issue click "retry a connection".

Another reason that this stage could fail is if the SSL certificate is not
trusted by your browser.  This will be the case unless you have previously
trusted it or trusted the signing authority.  If this is the case, the easiest
way to proceed is to click "access appliance directly".

### Create administrator account

1. Optionally change the email.
2. Enter a password.
3. Confirm the password.
4. Click "Proceed".

### Data center configuration

This is a demo appliance.  None of this really matters. Enter what you want
and click "Proceed".

### Hardware setup wizard

Once the first-time setup wizard has completed, you will directed to run the
hardware setup wizard.  Following this wizard will create your first rack
containing a management appliance.

### Unmanaged devices

You will periodically receive a message about unmanaged devices.  This error
can addressed by navigating to "System -> Configuration -> Appliances" and
configuring the `Command` appliance to monitor all devices in the group "Data
center", that is this single device monitors everything.
