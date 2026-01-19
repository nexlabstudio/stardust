---
title: Installation
description: Install Stardust on macOS, Linux, or Windows using your preferred package manager or binary download.
---

# Installation

Stardust can be installed on macOS, Linux, and Windows. Choose your preferred installation method below.

## macOS

<Tabs>
  <Tab name="Homebrew">
    The recommended way to install Stardust on macOS:

    ```bash
    brew tap nexlabstudio/tap
    brew install stardust
    ```

    To upgrade to the latest version:

    ```bash
    brew upgrade stardust
    ```
  </Tab>
  <Tab name="curl">
    Install using our installer script:

    ```bash
    curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash
    ```

    This installs to `/usr/local/bin` by default. To customize:

    ```bash
    STARDUST_INSTALL_DIR=~/.local/bin curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash
    ```
  </Tab>
</Tabs>

## Linux

<Tabs>
  <Tab name="curl">
    The recommended way to install Stardust on Linux:

    ```bash
    curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash
    ```

    The script automatically detects your architecture (x64 or ARM64).
  </Tab>
  <Tab name="Snap">
    Install from the Snap Store:

    ```bash
    snap install stardust
    ```
  </Tab>
</Tabs>

## Windows

<Tabs>
  <Tab name="Scoop">
    The recommended way to install Stardust on Windows:

    ```powershell
    scoop install https://raw.githubusercontent.com/nexlabstudio/stardust/dev/scoop/stardust.json
    ```
  </Tab>
  <Tab name="Chocolatey">
    Install using Chocolatey:

    ```powershell
    choco install stardust
    ```
  </Tab>
</Tabs>

## Dart/Flutter Developers

If you already have the Dart SDK installed, you can install Stardust as a global package:

```bash
dart pub global activate stardust
```

<Note>
Make sure `~/.pub-cache/bin` is in your PATH.
</Note>

## Manual Download

Download pre-built binaries from the [GitHub Releases](https://github.com/nexlabstudio/stardust/releases) page.

| Platform | Architecture | Download |
|----------|--------------|----------|
| macOS | Apple Silicon (ARM64) | `stardust-darwin-arm64.tar.gz` |
| macOS | Intel (x64) | `stardust-darwin-x64.tar.gz` |
| Linux | x64 | `stardust-linux-x64.tar.gz` |
| Linux | ARM64 | `stardust-linux-arm64.tar.gz` |
| Windows | x64 | `stardust-windows-x64.zip` |

### Manual Installation Steps

<Steps>
  <Step title="Download the archive">
    Download the appropriate archive for your platform from the releases page.
  </Step>
  <Step title="Extract the binary">
    ```bash
    # macOS/Linux
    tar -xzf stardust-*.tar.gz

    # Windows (PowerShell)
    Expand-Archive stardust-*.zip
    ```
  </Step>
  <Step title="Move to PATH">
    Move the `stardust` binary to a directory in your PATH:

    ```bash
    # macOS/Linux
    sudo mv stardust /usr/local/bin/

    # Windows - move to a directory in your PATH
    ```
  </Step>
</Steps>

## Verify Installation

After installation, verify that Stardust is working:

```bash
stardust --version
```

You should see output like:

```
Stardust v0.1.0
```

## Next Steps

<Card title="Quick Start" icon="rocket" href="/quickstart">
  Now that Stardust is installed, create your first documentation site.
</Card>
