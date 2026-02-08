# Package Manager Configuration

The install scripts use a shared package layer in `lib/package-manager.sh`.

## Config File

Edit `configs/package-managers.conf`.

## Source Priority

Defaults:
- CLI: `brew -> os`
- GUI: `flatpak -> brew -> os`
- System: `os`

`os` maps to:
- Fedora classic: `dnf`
- Fedora Atomic: `rpm-ostree`

## Per-Package Overrides

Use `PM_ORDER_OVERRIDE` for exceptions.

Example:

```bash
PM_ORDER_OVERRIDE[tailscale]="os"
```

## Alias Maps

Use aliases to map a logical key to manager-specific names:
- `PM_ALIAS_BREW[...]`
- `PM_ALIAS_OS[...]`
- `PM_ALIAS_FLATPAK[...]`

Use `__skip__` to disable a manager for a package.

## Reboot Behavior

When `rpm-ostree` layers packages, each script prints a reboot-required summary at script end.
