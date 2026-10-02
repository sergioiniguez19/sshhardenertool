# SSH Hardener

SSH Hardener is a Bash utility that deploys a hardened OpenSSH server configuration on Linux. It installs the OpenSSH server package on a limited set of distributions when needed, backs up the current configuration, installs the project's configuration, and checks its syntax.


## Security settings

The supplied profile in `conf/sshd_config` configures:

- SSH port `22` by default
- CTR ciphers: `aes256-ctr`, `aes192-ctr`, and `aes128-ctr`
- `LoginGraceTime 30` and `MaxAuthTries 3`
- Root login disabled
- Public-key authentication enabled; password, empty-password, and keyboard-interactive authentication disabled
- Agent forwarding, TCP forwarding, and X11 forwarding disabled
- Client keepalive settings: `ClientAliveInterval 300` and `ClientAliveCountMax 0`
- The SFTP subsystem set to `internal-sftp`

## Requirements

- Linux with Bash
- Root privileges (`sudo` or a root shell)
- Run the script from the project directory, which contains `conf/sshd_config`
- OpenSSH server (`sshd`); if it is missing, the script attempts installation on Debian/Ubuntu, Fedora/RHEL/CentOS, and Arch Linux

The host needs the relevant package manager and, when installing OpenSSH, package repository access. Other distributions are not automatically supported by the installer.

## Usage

From the project directory, make the script executable and run it as root:

```bash
chmod +x main.sh
sudo ./main.sh
```

To use a different port (the script accepts values from `1` through `65534`):

```bash
# SSH Hardener

SSH Hardener is a Bash tool for deploying a hardened OpenSSH server configuration on Linux. It checks for OpenSSH, backs up the current configuration, validates the new configuration, and restarts the SSH service.

## Security profile

The configuration in `conf/sshd_config` applies these settings:

- Port `22` by default
- CTR ciphers: `aes256-ctr`, `aes192-ctr`, and `aes128-ctr`
- Root login disabled; public-key authentication enabled
- Password, empty-password, and keyboard-interactive authentication disabled
- Maximum authentication attempts set to `3`; login grace time set to `30` seconds
- Agent, TCP, and X11 forwarding disabled
- Client keepalive interval set to `300` seconds
- SFTP provided by `internal-sftp`

## Requirements

- Linux and Bash
- Root privileges
- OpenSSH server; when missing, the script attempts to install it on Debian/Ubuntu, Fedora/RHEL/CentOS, or Arch Linux
- Run the script from the project directory so it can access `conf/sshd_config`

## Usage

Run the default configuration:

```bash
chmod +x main.sh
sudo ./main.sh
```

Set a custom SSH port:

```bash
sudo ./main.sh -p 2222
```

Display command-line options:

```bash
sudo ./main.sh -h
```

| Option | Description |
| --- | --- |
| `-h` | Display help |
| `-p PORT` | Set the SSH listening port |

## Deployment process

1. Checks root privileges and verifies that OpenSSH is installed, attempting installation on supported distributions if needed.
2. Checks whether the active SSH configuration already matches the hardening profile.
3. Saves the current configuration to `/etc/ssh/sshd_config.d/00.previous_config`.
4. Deploys `conf/sshd_config` as `/etc/ssh/sshd_config`.
5. Validates the configuration with `sshd -t`. If validation fails, it attempts to restore the backup and aborts.
6. Restarts the SSH service using `systemctl` or `service`, trying the service names `sshd` and `ssh`.
