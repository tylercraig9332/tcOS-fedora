# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

tcOS-fedora is a collection of automated setup scripts for configuring a Fedora GNOME environment with macOS-like behaviors and developer tooling. The repository orchestrates system updates, package installations, GNOME customization, and development environment setup.

When debugging, try to update these scripts so that they work for future installs
## Architecture

The repository is organized into various directories, each containing modular bash scripts:

### `/system` - System-level Configuration
- `update.sh`: System updates via dnf
- `setup-flatpak.sh`: Flatpak package installation
- `setup-appimage.sh`: AppImage support setup
- `setup-nvim.sh`: Neovim installation with LazyVim starter configuration
- `shell.sh`: Shell customization (zsh/bash and bat installation)

### `/gnome` - GNOME Desktop Customization
- `hotkeys.sh`: Implements macOS-like keyboard shortcuts by cloning and running `petrstepanov/gnome-macos-remap`, swaps Alt/Super keys, and opens Chrome for NordPass extension
- `extensions.sh`: GNOME Extension Manager installation and extension setup based on shell version detection
- `settings.sh`: GNOME settings configuration (e.g., touchpad tap-to-click)
- `just-perfection.sh`: Downloads, installs, and configures the Just Perfection GNOME extension with automatic shell version detection

### `/dev` - Development Environment Setup
- `install-js.sh`: Installs NVM, Node.js LTS, and Bun runtime with shell profile integration

### `/applications` - General Applications (anything with a graphical interface)

### Root Level
- `init.sh`: Main orchestration script that runs all setup scripts in sequence

## Key Patterns

### Shell Version Detection
GNOME extension scripts use this pattern to detect compatible versions:
```bash
SHELL_VERSION=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1-2)
```

### Shell Profile Management
Scripts detect and update the appropriate shell profile (.zshrc, .bashrc, or .profile) to persist environment changes across sessions.

### Session Type Handling
Assume I am always on Wayland

## Running the Setup

To run the complete system setup:
```bash
bash ./init.sh
```

To run individual setup components:
```bash
bash ./system/update.sh
bash ./gnome/hotkeys.sh
... etc
```

## Important Notes

- This project is a work in progress, the goal is to create a declaritve re-usable system. If a bash command is executed on the system to fix an install, ensure it's respective file gets updated to include this command.

