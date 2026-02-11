Config = {}

-- App Settings
Config.AppIdentifier = "laymo"
Config.AppName = "Laymo"
Config.AppDescription = "Autonomous ride service - Your personal self-driving taxi"
Config.AppDeveloper = "Laymo Inc."
Config.AppSize = 45000 -- KB
Config.AppPrice = 0 -- Set to > 0 to charge for the app

-- Pricing
Config.BasePrice = 50 -- Base fare
Config.PricePerMile = 5 -- Price per mile (1 mile = 1609.34 meters)
Config.SurgeMultiplier = 1.0 -- Surge pricing multiplier (1.0 = no surge)
Config.MinimumFare = 25 -- Minimum fare

-- Party: max number of additional passengers (besides the person who ordered). 0 = just you.
Config.MaxPartySize = 3

-- Vehicle Options (spawn randomly from this list)
-- seats = max passengers (excluding driver); vehicle must have seats >= 1 + party size (you + party)
Config.Vehicles = {
    { model = "dilettante", name = "Laymo Eco", tier = "economy", seats = 3 },
    { model = "asea", name = "Laymo Standard", tier = "standard", seats = 3 },
    { model = "stanier", name = "Laymo Standard", tier = "standard", seats = 3 },
    { model = "oracle", name = "Laymo Comfort", tier = "comfort", seats = 3 },
    { model = "tailgater", name = "Laymo Comfort", tier = "comfort", seats = 3 },
    { model = "schafter2", name = "Laymo Premium", tier = "premium", seats = 3 },
    { model = "oracle2", name = "Laymo Premium", tier = "premium", seats = 3 },
    { model = "minivan", name = "Laymo XL", tier = "standard", seats = 5 }, -- for larger parties
}

-- Tier Pricing Multipliers
Config.TierPricing = {
    economy = 0.8,
    standard = 1.0,
    comfort = 1.5,
    premium = 2.0
}

-- Driver Settings
Config.DriverModels = {
    "a_m_m_business_01",
    "a_m_y_business_01",
    "a_f_y_business_01",
    "a_f_m_business_02",
    "a_m_y_smartcaspat_01",
}

-- Preset / popular destinations (show in app as quick-select)
-- icon: plane, hospital, sun, anchor, home, briefcase, dice, or MapPin for generic
Config.PopularDestinations = {
    { id = "airport",    name = "Los Santos Airport",   icon = "plane",    coords = { x = -1035.11,  y = -2722.87, z = 13.65 } },
    { id = "hospital",   name = "LS Hospital",          icon = "hospital", coords = { x = -249.93, y = -597.67, z = 33.86 } },
    { id = "beach",      name = "Vespucci Beach",       icon = "sun",     coords = { x = -1198.24, y = -1531.66, z = 4.37 } },
    { id = "casino",     name = "Diamond Casino",       icon = "dice",    coords = { x = 917.49, y = 48.97, z = 80.9 } },
    { id = "pier",       name = "Del Perro Pier",       icon = "anchor",  coords = { x = -1637.15, y = -989.21, z = 13.02 } },
}

-- Autopilot Settings
Config.DrivingStyle = 786603 -- Normal driving (follows traffic laws)
-- Alternative driving styles:
-- 786468 = Rushed (ignores lights)
-- 1074528293 = Aggressive
-- 786603 = Normal

Config.MaxSpeed = 25.0 -- Max speed in m/s (~56 mph / ~90 km/h)

-- "In a hurry" driving (when user says they're in a hurry)
Config.DrivingStyleRushed = 786468   -- Rushed, less cautious
Config.MaxSpeedRushed = 38.0         -- Higher speed in m/s (~85 mph)
Config.StopDistance = 15.0 -- Distance to destination before stopping
Config.StopRadius = 5.0    -- How close the driver aims to the stop point (m). Smaller = more precise, less "middle of street".
Config.CurbOffsetMeters = 4.0 -- Offset toward curb when finding stop position so driver stops at side of road, not center.

-- Approach slowing: driver reduces speed as they get close (avoids high-speed arrival / ejection)
Config.ApproachSlowDistance1 = 80.0  -- Start slowing at this distance (m)
Config.ApproachSpeed1 = 14.0        -- Speed in m/s when within Distance1
Config.ApproachSlowDistance2 = 45.0 -- Slow more at this distance (m)
Config.ApproachSpeed2 = 8.0         -- Speed in m/s when within Distance2
Config.ApproachSlowDistance3 = 28.0 -- Final approach (m)
Config.ApproachSpeed3 = 4.0        -- Crawl speed in m/s when within Distance3

Config.PickupDistance = 50.0 -- Max distance to spawn vehicle for pickup
Config.MinPickupDistance = 20.0 -- Minimum distance to spawn vehicle

-- Waiting Settings
Config.MaxWaitTime = 300 -- Maximum wait time in seconds (5 minutes)
Config.PickupTimeout = 120 -- Time before ride is cancelled if player doesn't enter (2 minutes)

-- Blip Settings
Config.ShowDriverBlip = true
Config.DriverBlipSprite = 225 -- Taxi icon
Config.DriverBlipColor = 5 -- Yellow
Config.DriverBlipScale = 0.8

-- Notifications
Config.UseOxLib = true -- Set to false to use default notifications

-- Debug
Config.VehiclePlate = "LAYMO"

-- Debug
Config.Debug = false
