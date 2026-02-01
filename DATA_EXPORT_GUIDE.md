# Godot HTML Data Export Guide (Host Messaging)

This guide standardizes how our Godot games export run results to a shared host
environment. Use this in any new project so the host can consume data in a
consistent way.

## Overview

We send events from the game to the host using `window.parent.postMessage` from
the HTML5 export. Messages are only sent on web builds.

## Crocoverse Terminal Contract (Required)

All games embedded in the Crocoverse Terminal must emit the canonical payload:

```
{
  "type": "game_event",
  "event": "collectibles" | "game_over",
  "game_id": "snake_godot" | "pimpa_raka" | "<new_game_id>",
  "time_seconds": 12.3,
  "metrics": { ... }
}
```

For this project:
- `game_id`: `pimpa_raka`
- `metrics`: `{ "gems": <number>, "diamonds": <number> }`

Core payload fields:
- `type`: message category (string)
- `event`: event name (string)
- `game_id`: game identifier (string)
- `time_seconds`: run duration in seconds (float)
- `metrics`: free-form object with game-specific stats
- `session_id` or `run_id`: optional identifiers for host-side tracking

Recommended message categories:
- `game_event` (use `event` to indicate what happened)
- `telemetry` (optional, non-terminal updates)

## Godot Project Setup

### 1) Add a data export helper (autoload recommended)

Add these methods to a singleton (e.g., `GameManager`, `RunTracker`, or
`DataExport` autoload). This template takes a generic payload:

```
func send_event_to_host(event: String, metrics: Dictionary, time_seconds: float) -> void:
	if not OS.has_feature("web"):
		return
	var payload = {
		"type": "game_event",
		"event": event,
		"game_id": "your_game_id",
		"time_seconds": time_seconds,
		"metrics": metrics
	}
	var json = JSON.stringify(payload)
	var js = "window.parent.postMessage(" + json + ", window.location.origin);"
	JavaScriptBridge.eval(js)
```

Optional: gate duplicate sends by tracking a `has_sent` flag per run.

### 2) Track run time

Record the run start time at the beginning of a session (e.g., game start or
after reset), then compute elapsed seconds when sending the payload:

```
var run_start_ms: int = 0

func reset_run() -> void:
	run_start_ms = Time.get_ticks_msec()

func get_run_elapsed_seconds() -> float:
	if run_start_ms <= 0:
		return 0.0
	return max(0.0, (Time.get_ticks_msec() - run_start_ms) / 1000.0)
```

### 3) Call on run end (terminal event)

Trigger the export when the run ends:

```
func on_run_finished():
	var metrics = {
		"score": score,
		"coins": coins,
		"deaths": deaths
	}
	send_event_to_host("game_over", metrics, get_run_elapsed_seconds())
```

### 4) Optional: send on pause/exit

It is safe to call the send helper in pause or menu exits too.

## Web Export Settings (Godot 4.x)

Recommended settings for consistent host communication:

1) **Export preset**: HTML5
2) **Embed PCK**: enabled (keeps game assets in one export)
3) **Threads**: disabled unless you need them and your host supports COOP/COEP
4) **Canvas**: default
5) **Fullscreen**: optional, depending on host layout
6) **Memory**: choose a stable value for your game (e.g., 256 MB)
7) **Compression**: default (or disable if the host handles compression)

If you rely on `JavaScriptBridge`:
- Make sure you are exporting for HTML5 and running inside a browser context.
- Do not call `JavaScriptBridge.eval` on non-web platforms.

## Host Listener (Example)

Minimal example for the host web page:

```
window.addEventListener("message", (event) => {
	if (event.origin !== window.location.origin) return;
	const data = event.data;
	if (!data || typeof data !== "object") return;

	if (data.type === "game_event" && data.event === "game_over") {
		console.log("Run ended:", data.game_id, data.metrics, data.time_seconds);
	}
});
```

## Common Configurations

### Same-origin iframe

`postMessage` targets `window.location.origin`. The host must match the same
origin as the game iframe, or it will reject the message.

### Cross-origin iframe

If your host is cross-origin, replace the target origin with the host’s exact
origin string (e.g., `"https://example.com"`), and update the host to accept it.

### Game-over timing

If you want to show a game-over screen or play audio before the host closes the
game, delay the export and close signal by a short timer (1–3 seconds).

### Multiple game types

Keep `type` and `event` values consistent across projects. Always include
`game_id` so the host can differentiate games.

### Metrics payload shape

Use a `metrics` object for game-specific values. Keep it flat when possible.
Example:

```
var metrics = {
	"score": score,
	"coins": coins,
	"time_bonus": time_bonus
}
```

## Troubleshooting

**Parse error about preload**  
If a texture or resource is not imported yet, `preload` can fail at parse time.
Use `load()` in `_ready()` instead to avoid startup errors.

**No messages received**  
- Confirm the game runs in HTML5.
- Ensure the host and iframe are same-origin (or use explicit origin).
- Verify the browser console for errors.

**Messages received twice**  
Use a `has_sent` flag so each run sends at most one terminal message.
