# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**gkpv** (gk photo viewer) is a zero-dependency, single-file photo browser (`gkpv.html`) that runs entirely in the browser. No build step, no server, no external assets.

## Development

To test changes, open `gkpv.html` directly in a Chromium-based browser (Chrome, Edge, Brave). The app uses the File System Access API, which is not available in Firefox or Safari.

## Architecture

Everything lives in `gkpv.html` — inline `<style>`, HTML markup, and a `<script>` block. Key sections:

- **CSS custom properties** (`:root`) control theming and thumbnail sizes (`--thumb-sm/md/lg`)
- **UI states**: landing screen (`#landing`), toolbar + gallery (`#toolbar`, `#gallery`), lightbox overlay (`#lightbox`)
- **File system access**: `window.showDirectoryPicker()` returns a `FileSystemDirectoryHandle`; directory contents are iterated with async `for await` on the handle
- **Navigation state**: `rootHandle` (root directory), `currentPath` (array of subdirectory segments), `currentImages` (flat array for lightbox navigation)
- **Image display**: files are converted to object URLs via `URL.createObjectURL()` for both thumbnails and lightbox
- **Thumbnail grid**: CSS Grid with `auto-fill` + `minmax(var(--thumb-size), 1fr)`; size toggled by swapping the `--thumb-size` custom property

## Constraints

- Must remain a single self-contained HTML file — no external dependencies, no separate CSS/JS files
- All styling inline in `<style>`, all logic inline in `<script>`
- Supported image extensions are defined in the `IMAGE_EXTS` Set
