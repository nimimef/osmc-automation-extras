# OSMC Automation extras

*Install utility for OSMC, SabNZBd+, Transmission, CouchPotato & SickRage on a raspberry pi 1 or 2*

## Create OSMC image

Copy paste the following command to your osx terminal:
```sh
curl -O https://raw.githubusercontent.com/nimimef/osmc-automation-extras/master/osmc-installer-utility.sh && bash osmc-installer-utility.sh; rm osmc-installer-utility.sh
```

## Follow the instructions

```sh
****************************************************************************************************
This utility will download the official OSMC image and install it to your target device (eg. sdcard).
Make sure the target device is NOT CONNECTED before continuing.
****************************************************************************************************
Is the target device currently removed from your system? (y/n): y

Now please connect the target device and press 'y' to continue or 'n' to stop? (y/n): y

Using: /dev/disk3

Which raspberry pi do you have? (1/2): 2
Downloading image
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  153M  100  153M    0     0  3087k      0  0:00:51  0:00:51 --:--:-- 4872k

Unmount of all volumes on disk3 was successful
Enter your password if asked to access the device
256+0 records in
256+0 records out
268435456 bytes transferred in 2.606957 secs (102968887 bytes/sec)
Disk /dev/disk3 ejected

You can safely remove the device and plug it into your Raspberry Pi
```

## Wait for the install on you Raspberry Pi to finish and then ssh into it

Default password is 'osmc'
```sh
ssh osmc@192.168.1.234
```

When you're successfully logged in download the install script
```sh
curl -O https://raw.githubusercontent.com/nimimef/osmc-automation-extras/master/osmc-install-extras.sh
```

Edit defaults if you like (optional):
```sh
nano osmc-install-extras.sh
```
```
USERNAME="osmc"
PASSWORD="osmc"

COUNTRY="Central Europe"
TIMEZONE="Europe/Amsterdam"
TIMEZONECOUNTRY="Netherlands"

PORT_MARASCHINO=7000
PORT_COUCHPOTATO=9001
PORT_SICKRAGE=9002
PORT_SABNZBD=9003
PORT_TRANSMISSION=8004
PORT_KODI=8888
```
Hit Ctrl+X, Y and Enter to save and exit.

Optionally you should format your usb storage device to ext4 for best results

When you're ready, run the installer
```sh
bash osmc-install-extras.sh
```

