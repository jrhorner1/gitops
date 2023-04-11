#  

## Raspberry Pi 4 SSD preparation script for USB boot  

### How to  

The first thing you need is a MicroSD card setup with Raspberry Pi OS. Raspberry Pi Foundation provides a tool to make this step easy so, go grab the [imager](https://downloads.raspberrypi.org/imager/), flash your SD card, then come back here. RasPiOS arm64 images are located [here](https://downloads.raspberrypi.org/raspios_lite_arm64/images/).

Update the eeprom on your Pi 4 to the latest version and configure the boot order:

```bash
cd ssd_prep/
sudo ./rpi-eeprom.sh
```

Plug in your SSD and run the script:

```bash
sudo ./ssd_prep.sh
```

Thats it. Your SSD is prepped and ready to go. Reboot your Pi and it should boot from the SSD.  

## Optional Features

### Hostname configuration

Specify the hostname as an environment variable when running the script:

```bash
sudo HOSTNAME="myhostname.example.com" ./ssd_prep.sh
```

This sets your hostname in `/etc/hostname` and adds it to the localhost entry in `/etc/hosts`.

### Static IP configuration

Specify the IP configuration as environment variables when running the script:

```bash
sudo IP=192.168.1.100 CIDR=24 GATEWAY=192.168.1.1 DNS_SEARCH="example.com" DNS_ADDRS="1.1.1.1, 1.0.0.1" ./ssd_prep.sh
```

This will disable DHCP configuration and setup a static IP using `/etc/network/interfaces`.  

### SSH Authorized Keys

Specify an existing authorized_keys file to copy to the ssd:

```bash
sudo AUTH_KEYS=~/.ssh/authorized_keys ./ssd_prep.sh
```

## Script variables

|Variable|Value|Description|
|---|---|---|
|TARGETDEV|/dev/sda|Device path for your SSD.|
|RASPIOS_URL|<https://downloads.raspberrypi.org/raspios_lite_arm64/images>|Raspberry Pi OS Lite archive URL.|
|RASPIOS_DIR|raspios_lite_arm64-2023-02-22|Archive folder containing the desired Raspberry Pi OS image. Usually contains a different date than the image.|
|RASPIOS_IMG|2023-02-21-raspios-bullseye-arm64-lite.img|Raspberry Pi OS Lite image filename.|
|MNTBOOT|/mnt/boot|Path to mount your boot partition to.|
|MNTROOT|/mnt|Path to mount your root partition to.|
|HOSTNAME| |No default value is set.|
|IP| |No default value is set.|
|CIDR|24|The standard subnet size for class C private networks with 254 usable addresses.|
|GATEWAY| |This uses a sed command to set the gateway to the first address in the IP's subnet, ie. if your IP is 192.168.1.54 the gateway will be 192.168.1.1. Note: does not work if the CIDR isn't 24.|
|DNS_SEARCH| |By default, this will determine if a domain is appended to your hostname and if so, set that as the value. Otherwise it is not set.|
|DNS_ADDRS| |This uses a sed command to pull your nameservers from `/etc/resolv.conf` in Raspberry Pi OS which would have been set by DHCP by default.|
|AUTH_KEYS| |Path to an existing [authorized_keys](https://www.ssh.com/academy/ssh/authorized-key) file.|
