# z-claude-plugins

A collection of Claude Code plugins for enhanced productivity and automation.

## Plugins

| Plugin | Description |
|--------|-------------|
| [and-then](./and-then) | Sequential task queue that auto-advances when each task completes |

## Installation

### Option 1: Add to plugins.json

Add the plugin paths to your `.claude/plugins.json`:

```json
{
  "plugins": [
    "/path/to/z-claude-plugins/and-then"
  ]
}
```

### Option 2: Symlink

Symlink individual plugins to your `.claude/plugins/` directory:

```bash
ln -s /path/to/z-claude-plugins/and-then ~/.claude/plugins/and-then
```

## Plugin Development

Each plugin follows the standard Claude Code plugin structure:

```
plugin-name/
├── plugin.json      # Plugin manifest
├── commands/        # Slash commands
├── hooks/           # Event hooks (optional)
├── scripts/         # Helper scripts
├── skills/          # Skills (optional)
└── README.md        # Documentation
```

## License

MIT
