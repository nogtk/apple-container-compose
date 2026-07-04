# apple-container-compose

A small Compose-style runner for Apple's `container` CLI, written in Swift.
It reads `compose.yaml` and executes command sequences such as `container network create`, `container volume create`, and `container run`.

## Requirements

- macOS
- Swift 6+
- Apple `container` CLI

Apple `container` requires an Apple silicon Mac and macOS 26 or later.

## Usage

Run it directly from the repository:

```bash
swift run ap-compose up --dry-run
swift run ap-compose up
swift run ap-compose down
swift run ap-compose config
```

After installation, you can run it without `swift run`:

```bash
ap-compose up --dry-run
ap-compose up
ap-compose down
ap-compose config
```

Use a different compose file:

```bash
swift run ap-compose up -f compose.example.yaml --dry-run
ap-compose up -f compose.example.yaml --dry-run
```

## Install

```bash
git clone https://github.com/nogtk/apple-container-compose.git
cd apple-container-compose
swift build -c release
install -m 755 .build/release/ap-compose /usr/local/bin/ap-compose
```

To install into the Homebrew PATH on Apple silicon Macs:

```bash
install -m 755 .build/release/ap-compose /opt/homebrew/bin/ap-compose
```

## YAML

Supported fields:

- `project` or `name`
- `services.<name>.image`
- `services.<name>.ports`
- `services.<name>.environment`
- `services.<name>.volumes`
- `services.<name>.networks`
- `services.<name>.depends_on`
- `services.<name>.command`
- `volumes.<name>.size`
- `networks.<name>.internal`

`depends_on` controls start and stop order. Health-check waiting is not implemented yet.
