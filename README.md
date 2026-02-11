# Laymo - Autonomous Ride Service for FiveM

A Waymo/Uber-style autonomous ride service app for lb-phone, designed for QBX Core framework servers.
By Seamus McMasters - Beetle Studios

## Features

- **Autonomous Vehicle Pickup**: NPC drivers in vehicles automatically navigate to pick you up
- **Smart Destination Selection**: Use map waypoints or choose from popular destinations
- **Multiple Vehicle Tiers**: Economy, Standard, Comfort, and Premium options
- **Dynamic Pricing**: Distance-based fare calculation with tier multipliers
- **Real-time Tracking**: See your driver's ETA and trip progress
- **Beautiful UI**: Modern, responsive phone app interface
- **QBX Core Integration**: Full compatibility with qbx_core framework

## Dependencies

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [lb-phone](https://lbscripts.com/)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql) (optional, for ride history)

## Installation (for server owners — no Node.js required)

If you received a **pre-built release** (zip from the developer):

1. **Extract** the zip into your server's `resources` folder so you have `resources/bs_laymo/` (with `ui/dist` inside).
2. **Add to `server.cfg`:**
   ```cfg
   ensure ox_lib
   ensure qbx_core
   ensure lb-phone
   ensure bs_laymo
   ```
3. Start or restart your server.

No Node.js or build step needed.

---

## Building the UI (for script developers / distributors only)

If you are **distributing** this resource or you **modified the UI** and need to rebuild:

- **Windows:** Run `build.bat` from the `bs_laymo` folder (requires Node.js installed once).
- **Or manually:** `cd ui` then `npm install` and `npm run build`.

Then zip the entire `bs_laymo` folder (including `ui/dist`) and share it. End users who get that zip do **not** need Node.js. See **DISTRIBUTION.md** for full details.

---

## Configure (Optional)
Edit `config.lua` to customize:
- Pricing (base fare, per-mile rate, minimum fare)
- Vehicle options and tiers
- Driver models
- Autopilot behavior
- Maximum wait times

## Configuration Options

### Pricing
```lua
Config.BasePrice = 50       -- Base fare
Config.PricePerMile = 5     -- Price per mile
Config.SurgeMultiplier = 1.0 -- Surge pricing (1.0 = no surge)
Config.MinimumFare = 25     -- Minimum fare
```

### Vehicle Tiers
```lua
Config.TierPricing = {
    economy = 0.8,   -- 20% cheaper
    standard = 1.0,  -- Base price
    comfort = 1.5,   -- 50% more
    premium = 2.0    -- 100% more
}
```

### Vehicles
Add or modify vehicles in `Config.Vehicles`:
```lua
{ model = "dilettante", name = "Laymo Eco", tier = "economy" },
```

### Autopilot Settings
```lua
Config.DrivingStyle = 786603  -- Normal (follows traffic)
Config.MaxSpeed = 25.0        -- Max speed in m/s
Config.StopDistance = 15.0    -- Arrival threshold
```

## Usage

1. **Open the App**: Access Laymo through lb-phone
2. **Set Pickup**: Tap to use your current location
3. **Choose Destination**: 
   - Select a popular destination
   - Use your map waypoint
4. **Select Tier**: Choose Economy, Standard, Comfort, or Premium
5. **Request Ride**: Confirm your ride request
6. **Wait for Pickup**: An autonomous vehicle will navigate to you
7. **Enter Vehicle**: Get in when the car arrives
8. **Enjoy the Ride**: Relax as the autopilot drives you to your destination
9. **Pay Fare**: Fare is automatically deducted upon arrival

## Admin Commands

### Set Surge Pricing
```
/laymo:surge [multiplier]
```
Example: `/laymo:surge 1.5` sets 50% surge pricing

## Exports

### Client Exports
```lua
-- Request a ride programmatically
exports['bs_laymo']:RequestRide(pickup, destination, tier)

-- Cancel current ride
exports['bs_laymo']:CancelRide()

-- Get current ride state
exports['bs_laymo']:GetRideState()
```

## Development

### UI Development
For hot-reload during UI development:

1. Uncomment the development UI page in `fxmanifest.lua`:
```lua
-- ui_page "ui/dist/index.html"
ui_page "http://localhost:3000"
```

2. Uncomment in `client/main.lua`:
```lua
-- ui = GetCurrentResourceName() .. "/ui/dist/index.html",
ui = "http://localhost:3000",
```

3. Start the dev server:
```bash
cd ui
npm run dev
```

### Debug Mode
Enable debug mode in `config.lua`:
```lua
Config.Debug = true
```

## Troubleshooting

### Vehicle Won't Spawn
- Ensure the vehicle model exists and is loaded
- Check spawn location isn't blocked
- Verify player isn't already in a vehicle

### App Not Showing
- Verify lb-phone is started before this resource
- Check for errors in F8 console
- Ensure `ui/dist` exists (if you built from source, run `build.bat` or `npm run build` in `ui`; if you use a pre-built release, re-download so the zip includes `ui/dist`)

### Phone app icon shows blank / wrong image
- The app icon on the phone comes from **`ui/public/icon.png`**. Replace that file with your Laymo app icon (square PNG, e.g. 256×256 or 512×512), then run **`build.bat`** (or `npm run build` in `ui`) so it’s copied to `ui/dist`; the build also resizes it to 256×256 so the icon matches the size of other apps on the phone desktop. Restart the resource or server.
- The **in-app header logo** (full LAYMO logo) comes from **`ui/public/header-logo.png`**. Replace that file with your header image, then rebuild.

### Payment Issues
- Verify player has sufficient funds
- Check qbx_core is functioning properly

## Credits

- Autopilot logic inspired by Bucko_autopilot
- UI template based on lb-phone-app-template

## License

MIT License - Feel free to modify and use in your server!

## Support

For issues and feature requests, please open an issue on the repository.
