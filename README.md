# OmniFormis Shell

A Hyprland + Quickshell desktop configuration.

## Installation

### One line install

```bash
curl -fsSL https://raw.githubusercontent.com/Boing-Git/OmniFormis-Shell/main/bootstrap.sh | bash
```

`bootstrap.sh` fetches the repository into `~/Dotfiles` and hands over to
`install.sh`. Options after `bash -s --` are passed through:

```bash
curl -fsSL https://raw.githubusercontent.com/Boing-Git/OmniFormis-Shell/main/bootstrap.sh | bash -s -- --non-interactive
curl -fsSL https://raw.githubusercontent.com/Boing-Git/OmniFormis-Shell/main/bootstrap.sh | bash -s -- --dry-run
```

| Variable | Default | Purpose |
| --- | --- | --- |
| `OMNIFORMIS_DIR` | `~/Dotfiles` | Where the repository is checked out |
| `OMNIFORMIS_REPO_URL` | this repository | Repository to clone |
| `OMNIFORMIS_REF` | default branch | Branch or tag to check out |
| `OMNIFORMIS_UPDATE` | `0` | `1` fast-forwards an existing checkout |
| `OMNIFORMIS_ALLOW_ROOT` | `0` | `1` skips the "do not run as root" guard |

### Install from a checkout

```bash
git clone https://github.com/Boing-Git/OmniFormis-Shell.git
cd OmniFormis-Shell
./install.sh --non-interactive
```

`./install.sh --help` lists every option, including `--dry-run`.

## Repository Structure

The repository is organized as follows:
- `install.sh`: Main installer script.
- `install/lib/`: Library of functions used by the installer.
- `scripts/`: Utility scripts (e.g., uninstaller).
- `docs/`: Documentation.

## Contributing

This project uses a dotfiles-based approach to manage system configuration. Contributions are welcome via pull requests.

## License

MIT