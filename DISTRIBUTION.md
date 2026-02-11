# Distributing Laymo (no Node.js for end users)

End users who install this resource **do not need Node.js**. They only need to drop the folder in and add one line to `server.cfg`.

## For you (the person distributing)

Build the UI **once** on a machine where Node.js is installed, then ship the folder including the built files.

### Option A: Run the build script (easiest)

- **Windows:** Double-click `build.bat` or run it from a terminal in the `bs_laymo` folder.
- **Linux/macOS:** Run `./build.sh` from the `bs_laymo` folder (may need `chmod +x build.sh` first).

This runs `npm install` and `npm run build` in the `ui` folder and creates `ui/dist`.

### Option B: Run commands manually

```bash
cd bs_laymo/ui
npm install
npm run build
```

### After building

1. Zip the **entire** `bs_laymo` folder (including `ui/dist`, `client`, `server`, `config.lua`, `fxmanifest.lua`, `icon.png`, etc.).
2. Share that zip (e.g. Tebex, GitHub release, Discord).

Anyone who downloads it can install without Node.

---

## For end users (server owners)

1. Download the Laymo zip from you.
2. Extract it to `resources/` so you have `resources/bs_laymo/` with `ui/dist` inside it.
3. In `server.cfg` add:
   ```cfg
   ensure ox_lib
   ensure qbx_core
   ensure lb-phone
   ensure bs_laymo
   ```
4. Start or restart the server.

No Node.js, no npm, no build step.

---

## If you change the UI later

After editing anything in `ui/src/`, run the build again (Option A or B above), then re-zip and redistribute so your zip still contains an up-to-date `ui/dist`.
