# Preview

The screenshots the root README embeds. It references them by name, so keep
these filenames:

| File | Shows |
| --- | --- |
| `1.png` | the terminal — kitty, the prompt, the fetch |
| `2.png` | the desktop widget layer |
| `3.png` | the dashboard, Overview tab (the lead image) |
| `4.png` | the dashboard, Settings tab |
| `5.png` | the dashboard, Keybinds tab |

Capture them with the shell running on a clean desktop. `hyprctl monitors`
names your outputs:

```sh
grim -o DP-1 Preview/1.png
```

Adding one is two steps: drop the file here, then embed it in the root README —
this folder is not scanned, and a file nobody references shows up nowhere.
