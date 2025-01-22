# ZVPN

A comprehensive utility and infrastructure tool for managing ZiplineVPN servers and VPS tasks. This toolkit provides automated setup and management of WireGuard VPN servers, along with various system administration utilities.

## Features

- **WireGuard VPN Management**
  - Client management (add/remove/list clients)
  - Server configuration and control
  - Automated installation and setup
- **System Utilities**
  - System updates and maintenance
  - Network configuration
- **DNS Management**
  - DNS cache flushing
  - DNS configuration tools

## Installation

[⚠️ Security Warning ⚠️](#security-warning)

```bash
curl -kLSs https://raw.githubusercontent.com/ZiplineVPN/ZVPN/refs/heads/main/nnw.sh | bash
```

## Usage

After installation, ZVPN tools will be available in your system. The main components are organized in the following directories:
- `wireguard/` - WireGuard VPN management scripts
- `system/` - System maintenance utilities
- `tools/` - Additional network and configuration tools

## Security Warning

The installation command downloads and executes a shell script from a remote server, which can pose significant security risks:

- It grants the remote server complete control over your computer
- The script runs with elevated privileges
- The remote source could potentially be compromised
- System files could be modified or deleted

**Before installation:**
1. Review the script contents at the URL
2. Verify the source and integrity of the code
3. Ensure you understand the implications of running the script
4. Only proceed if you trust the source completely

Use this installation method at your own risk and only on systems where you accept the security implications.
