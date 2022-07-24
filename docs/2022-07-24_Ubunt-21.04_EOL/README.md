## Ubuntu 21.04 End of Life Upgrade

### Problem

Upon running `sudo apt update` prior to installing upgrades or additional packages, presented with the following output:

```
Get:1 http://packages.cloud.google.com/apt kubernetes-xenial InRelease [9383 B]
Ign:2 http://ports.ubuntu.com/ubuntu-ports hirsute InRelease
Ign:3 http://ports.ubuntu.com/ubuntu-ports hirsute-updates InRelease
Ign:4 http://ports.ubuntu.com/ubuntu-ports hirsute-backports InRelease
Ign:5 http://ports.ubuntu.com/ubuntu-ports hirsute-security InRelease
Err:6 http://ports.ubuntu.com/ubuntu-ports hirsute Release
  404  Not Found [IP: 185.125.190.36 80]
Err:7 http://ports.ubuntu.com/ubuntu-ports hirsute-updates Release
  404  Not Found [IP: 185.125.190.36 80]
Err:8 http://ports.ubuntu.com/ubuntu-ports hirsute-backports Release
  404  Not Found [IP: 185.125.190.36 80]
Err:9 http://ports.ubuntu.com/ubuntu-ports hirsute-security Release
  404  Not Found [IP: 185.125.190.36 80]
Reading package lists... Done
E: The repository 'http://ports.ubuntu.com/ubuntu-ports hirsute Release' no longer has a Release file.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
E: The repository 'http://ports.ubuntu.com/ubuntu-ports hirsute-updates Release' no longer has a Release file.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
E: The repository 'http://ports.ubuntu.com/ubuntu-ports hirsute-backports Release' no longer has a Release file.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
E: The repository 'http://ports.ubuntu.com/ubuntu-ports hirsute-security Release' no longer has a Release file.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
```

The error is reporting that the [repository](http://ports.ubuntu.com/ubuntu-ports/) is not available for the currently installed version of Ubuntu and prevents the system from updating, upgrading and even installing software packages.

#### Solution

Update the repository information in /etc/apt/sources.list to http://old-releases.ubuntu.com/ubuntu/. A sample is given [here](./samples/sources.list).

```bash
sudo sed -i 's|http://ports.ubuntu.com/ubuntu-ports/|http://old-releases.ubuntu.com/ubuntu/|g' /etc/apt/sources.list
sudo apt update
```

### Root Cause

Ubuntu 21.04 went end of life (EOL) on [January 20, 2022][ref1]. Ubuntu 21.10 also went EOL on [July 14, 2022][ref2]. Since 21.10 is the upgrade path for 21.04 and it is now EOL, the upgrade is no longer supported and thus not permitted by the release upgrade tool `do-release-upgrade`.

#### Solution

Run the [EOL upgrade script](../scripts/eolupgrade.sh) to update sources.list, install any available updates, and [bypass the unsupported upgrade logic][ref3].

```bash
curl -OL https://raw.githubusercontent.com/jrhorner1/gitops/main/scripts/eolupgrade.sh
chmod +x eolupgrade.sh
./eolupgrade.sh
tmux new -s release-upgrade
sudo do-release-upgrade
```

This will upgrade to the next release in the upgrade path, 21.10, code name "impish". When the upgrade script has completed, press 'x' to exit the script. Checking the release should reflect the new code name.

```bash
cat /etc/*release
```


Reboot and install the `ubuntu-server` (or `ubuntu-server-raspi`) package as `ubuntu-minimal` is no longer available in 22.04 and will present an error when attempting the release upgrade. Kick off the release upgrade once the meta-package is installed.

```bash
sudo apt install ubuntu-server-raspi
sudo do-release-upgrade
```

When the upgrade finishes, reboot and verify the release version/code name.

### Prevention

Ubuntu 22.04 is a long term support (LTS) release and will recieve support until [April 2027][ref4]. The issue should not present itself as long as an upgrade to a non-LTS release is NOT performed.

### Resources

* [Ubuntu Releases Wiki](https://wiki.ubuntu.com/Releases?_ga=2.68724113.1007593536.1658597507-1342059548.1658451533)
* [Upgrade from 20.04 LTS or 21.10 to 22.04 LTS](https://help.ubuntu.com/community/JammyUpgrades#Ubuntu_Servers)

[ref1]: https://lists.ubuntu.com/archives/ubuntu-announce/2022-January/000276.html
[ref2]: https://lists.ubuntu.com/archives/ubuntu-announce/2022-July/000281.html
[ref3]: https://www.reddit.com/r/Ubuntu/comments/w3iair/comment/igwbypp/?context=1
[ref4]: https://discourse.ubuntu.com/t/jammy-jellyfish-release-notes/24668
