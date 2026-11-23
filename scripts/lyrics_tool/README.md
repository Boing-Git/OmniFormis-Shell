# lyrics-fetcher

A small CLI that fetches song lyrics given an **artist** and **title** —
both plain text and synced (LRC, timestamped) lyrics where available —
with fallback across sources, local caching, and clipboard/save support.

## How it picks a source

1. **LRCLIB** — free, no key needed. Tried first. The only source here
   that can return **synced (LRC)** lyrics; it also has plain lyrics for
   most tracks that have them.
2. **lyrics.ovh** — free, no key needed. Plain lyrics only.
3. **Genius** — much better coverage/accuracy, but needs a free API token.
   Plain lyrics only. Only used if `GENIUS_ACCESS_TOKEN` is set.

Only LRCLIB provides synced lyrics — if a track isn't on LRCLIB with a
synced version, you'll get plain lyrics only, even if lyrics.ovh or Genius
have it.

Results are cached in `~/.cache/lyrics-fetcher/` for 30 days, so repeat
lookups are instant and offline-friendly.

## Install

The Nix module installs it as `lyrics-fetcher` (nix/lyrics-fetcher.nix). Without Nix:

```bash
cargo build --release
./target/release/lyrics-fetcher "Radiohead" "Karma Police"
```

To enable the Genius fallback, also install the optional extra:
```bash
pipx install ".[genius]"
```

## Usage

```bash
lyrics-fetch "Daft Punk" "One More Time"                         # shows plain + synced if available
lyrics-fetch "Bon Iver" "Holocene" --copy                        # copies plain lyrics to clipboard
lyrics-fetch "Bon Iver" "Holocene" --copy-lrc                    # copies synced (LRC) lyrics
lyrics-fetch "Bon Iver" "Holocene" --save song.txt --save-lrc song.lrc
lyrics-fetch "Artist" "Song (Live)"                               # noisy suffixes are auto-stripped
lyrics-fetch "Artist" "Song" --no-clean                           # disable that stripping
lyrics-fetch "Artist" "Song" --source lrclib                      # force one source
lyrics-fetch "Artist" "Song" --no-cache                           # force a fresh fetch
lyrics-fetch --clear-cache
```

## Get a Genius token (optional, recommended)

1. Go to https://genius.com/api-clients and create a client.
2. Generate a "Client Access Token".
3. `export GENIUS_ACCESS_TOKEN="your-token-here"` (add it to your shell rc
   or a NixOS/home-manager secrets setup).

## Notes

- Title cleanup strips things like `(Remastered 2011)`, `- Live`,
  `(feat. X)` before querying, since those often cause exact-match misses.
- Clipboard support tries `wl-copy` first (Wayland/Hyprland), then falls
  back to `xclip`.
- lyrics.ovh coverage/formatting can be inconsistent for less popular
  tracks — the Genius fallback fixes most of those misses.
- Synced (LRC) lyrics are community-contributed on LRCLIB, so coverage is
  good for popular tracks but not universal — expect gaps on obscure or
  very new releases.
