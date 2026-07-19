---
title: stardust serve
description: Preview a built site locally without watching or rebuilding.
---

# stardust serve

Serve an already-built site from the output directory. Unlike `stardust dev`,
nothing is watched or rebuilt — you see exactly what `stardust build` produced.

```bash
stardust build
stardust serve
```

## Usage

```bash
stardust serve [dir] [options]
```

With no directory argument, serves `build.outDir` from your config (default `dist`).

```bash
stardust serve build/v2 --port 5000
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `[dir]` | Directory to serve | `build.outDir` or `dist` |
| `-c, --config` | Path to config file | `stardust.yaml` |
| `-p, --port` | Port to serve on | `4000` |
| `--host` | Host to bind to | `localhost` |
