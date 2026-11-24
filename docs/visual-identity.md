# play visual identity

`play` is a Linux launcher and system HUD rather than a browser app. Its visual
identity should stay native to the desktop: a compact translucent status
overlay, high-contrast telemetry, and familiar green/yellow/red system states.
The game's own colors are never modified by the launcher.

| Role | Treatment |
| --- | --- |
| Overlay | Translucent dark GTK window |
| FPS and activity | Bright, high-contrast telemetry |
| Status | Green for healthy, yellow for caution, red for errors |
| Game rendering | Unmodified Wine/DXVK application output |

The HUD and launcher behavior are described in [`README.md`](../README.md);
`hud` is the visual implementation entry point. Color behavior can vary with
the desktop theme and MangoHud mode, so exact hex values are intentionally not
claimed here.
