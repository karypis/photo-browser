# gkpv — gk photo viewer

A lightweight, single-file photo browser that runs entirely in the browser. No server, no dependencies, no build step.

## Features

- **Local folder access** — select any directory on your machine using the browser's File System Access API
- **Thumbnail grid** — responsive grid with three size options (S / M / L)
- **Smart thumbnails** — images are downsized (max 640px) for fast grid rendering instead of loading full-resolution files
- **Persistent caching** — thumbnails are cached in the Origin Private File System (OPFS) so they load instantly on revisit; cache keys include file size and modification time for automatic invalidation
- **Shimmer placeholders** — animated loading indicators while thumbnails generate, with smooth fade-in on completion
- **Lightbox viewer** — click any image to view full-size with keyboard navigation (arrow keys, Esc); full-resolution images are loaded on demand
- **Directory browsing** — navigate into subdirectories with breadcrumb navigation
- **Sorting** — sort by name or date (ascending/descending)
- **Cache management** — Clear Cache button in the toolbar to force thumbnail regeneration

## Usage

Open `gkpv.html` in a Chromium-based browser (Chrome, Edge, Brave) and click **Open Folder** to select a photo directory.

> **Note:** The File System Access API is not supported in Firefox or Safari.

## License

MIT
