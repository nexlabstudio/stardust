---
title: stardust clean
description: Delete build output, dev output, and caches.
---

# stardust clean

Remove everything Stardust generated: the build output (`build.outDir`), the
dev server output (`.stardust/`), and caches (`.dart_tool/stardust/`).

```bash
stardust clean
```

The output directory is only deleted when it carries the `.stardust-build`
marker from a previous build — a directory Stardust didn't create is skipped
with a warning, never deleted.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `-c, --config` | Path to config file | `stardust.yaml` |
