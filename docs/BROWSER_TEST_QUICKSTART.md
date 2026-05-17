# Browser Test Quickstart (Web Build)

Use this guide to test the game on a PC browser or on managed devices where app installation is blocked.

## 1) Prerequisites

- Godot 4.x installed (`godot4` or `godot` in PATH)
- Export templates installed for your Godot version

## 2) Build a browser bundle

From repo root:

```bash
./tools/build_web.sh release
```

Outputs:

- `build/web/index.html` (plus `.js`, `.wasm`, `.pck`)
- `build/rift-bestiary-protocol-web-release.zip`

## 3) Test locally on PC

```bash
python3 -m http.server --directory build/web 8060
```

Open:

- `http://localhost:8060`

> Do not open `index.html` directly with `file://`; serve over HTTP.

## 4) Test on a locked-down Android device

Since installs are admin-blocked, host the `build/web` files on a static host and open via browser URL.

Options:

- GitHub Pages
- Netlify
- Cloudflare Pages
- Any static web host

Then open the hosted URL on the managed device.

## 5) CI web builds

Workflow:

- `.github/workflows/web-build.yml`

Run from:

- **Actions -> Web Browser Build -> Run workflow**

Artifact contains the full `build/web` output plus a zipped bundle.

## 6) Auto-deploy to GitHub Pages (recommended for phone testing)

Workflow:

- `.github/workflows/web-pages-deploy.yml`

How to use:

1. In your repo settings, set **Pages -> Build and deployment -> Source** to **GitHub Actions**.
2. Run **Actions -> Web Pages Deploy -> Run workflow** (or push to `main`).
3. Open the deployed Pages URL shown in the workflow deployment summary.

This gives you a public URL you can open directly from your Android browser.
