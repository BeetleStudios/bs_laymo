-- NUI Callbacks for AutoRide phone app

-- Get current player location
RegisterNUICallback("getPlayerLocation", function(data, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local streetName, crossingRoad = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetNameStr = GetStreetNameFromHashKey(streetName)
    local crossingRoadStr = GetStreetNameFromHashKey(crossingRoad)
    
    local locationName = streetNameStr
    if crossingRoadStr and crossingRoadStr ~= "" then
        locationName = locationName .. " & " .. crossingRoadStr
    end
    
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        street = locationName
    })
end)

-- Get waypoint location
RegisterNUICallback("getWaypoint", function(data, cb)
    local blip = GetFirstBlipInfoId(8) -- Waypoint blip
    
    if DoesBlipExist(blip) then
        local coords = GetBlipInfoIdCoord(blip)
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 100.0, false)
        
        if found then
            coords = vector3(coords.x, coords.y, groundZ)
        end
        
        local streetName, crossingRoad = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local streetNameStr = GetStreetNameFromHashKey(streetName)
        
        cb({
            exists = true,
            x = coords.x,
            y = coords.y,
            z = coords.z,
            street = streetNameStr
        })
    else
        cb({ exists = false })
    end
end)

-- Request ride from app
RegisterNUICallback("requestRide", function(data, cb)
    local pickup = data.pickup
    local destination = data.destination
    local tier = data.tier or "standard"
    local inAHurry = data.inAHurry == true
    local partySize = tonumber(data.partySize)
    if partySize == nil or partySize < 0 then partySize = 0 end
    partySize = math.min(partySize, Config.MaxPartySize or 3)

    if not pickup or not destination then
        cb({ success = false, error = "Missing pickup or destination" })
        return
    end

    -- Validate coordinates
    if not pickup.x or not pickup.y or not destination.x or not destination.y then
        cb({ success = false, error = "Invalid coordinates" })
        return
    end

    -- Get ground Z if not provided
    if not pickup.z then
        local found, z = GetGroundZFor_3dCoord(pickup.x, pickup.y, 1000.0, false)
        pickup.z = found and z or 30.0
    end

    if not destination.z then
        local found, z = GetGroundZFor_3dCoord(destination.x, destination.y, 1000.0, false)
        destination.z = found and z or 30.0
    end

    RequestRide(pickup, destination, tier, inAHurry, partySize)
    cb({ success = true })
end)

-- Cancel ride from app (before or at pickup)
RegisterNUICallback("cancelRide", function(data, cb)
    CancelRide()
    cb({ success = true })
end)

-- End ride during trip: driver pulls over, player gets out, partial fare charged
RegisterNUICallback("endRide", function(data, cb)
    RequestPullOver()
    cb({ success = true })
end)

-- Get current ride status
RegisterNUICallback("getRideStatus", function(data, cb)
    local status = GetRideState()
    cb(status)
end)

-- Submit ride rating (1-5 stars) after trip completed
RegisterNUICallback("submitRating", function(data, cb)
    local stars = tonumber(data.rating)
    if stars and stars >= 1 and stars <= 5 then
        TriggerServerEvent("laymo:submitRating", stars)
    end
    cb({})
end)

-- Get available vehicle tiers and pricing
RegisterNUICallback("getVehicleTiers", function(data, cb)
    local tiers = {}
    local seenTiers = {}
    
    for _, vehicle in ipairs(Config.Vehicles) do
        if not seenTiers[vehicle.tier] then
            seenTiers[vehicle.tier] = true
            table.insert(tiers, {
                id = vehicle.tier,
                name = vehicle.tier:gsub("^%l", string.upper), -- Capitalize first letter
                multiplier = Config.TierPricing[vehicle.tier] or 1.0
            })
        end
    end
    
    -- Sort by multiplier
    table.sort(tiers, function(a, b) return a.multiplier < b.multiplier end)
    
    cb(tiers)
end)

-- Calculate price estimate
RegisterNUICallback("getPriceEstimate", function(data, cb)
    local pickup = data.pickup
    local destination = data.destination
    local tier = data.tier or "standard"
    
    if not pickup or not destination then
        cb({ error = "Missing coordinates" })
        return
    end
    
    local pickupVec = vector3(pickup.x, pickup.y, pickup.z or 0)
    local destVec = vector3(destination.x, destination.y, destination.z or 0)
    local distance = #(pickupVec - destVec)
    
    local tierMultiplier = Config.TierPricing[tier] or 1.0
    local miles = distance / 1609.34
    local price = (Config.BasePrice + (miles * Config.PricePerMile)) * tierMultiplier * Config.SurgeMultiplier
    price = math.max(math.floor(price), Config.MinimumFare)
    
    local eta = math.ceil(distance / 15) -- Rough ETA
    
    cb({
        price = price,
        distance = math.floor(distance),
        distanceMiles = string.format("%.1f", miles),
        eta = eta,
        surge = Config.SurgeMultiplier > 1.0
    })
end)

-- Set waypoint on map
RegisterNUICallback("setWaypoint", function(data, cb)
    if data.x and data.y then
        SetNewWaypoint(data.x, data.y)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

-- Get saved locations (favorites)
RegisterNUICallback("getSavedLocations", function(data, cb)
    -- This would typically come from a database
    -- For now, return some default locations
    cb({
        {
            id = "home",
            name = "Home",
            icon = "home",
            coords = nil -- User would set this
        },
        {
            id = "work", 
            name = "Work",
            icon = "briefcase",
            coords = nil
        }
    })
end)

-- Get popular destinations (from config)
RegisterNUICallback("getPopularDestinations", function(data, cb)
    cb(Config.PopularDestinations or {})
end)

-- Get app config (e.g. max party size for UI)
RegisterNUICallback("getLaymoConfig", function(data, cb)
    cb({
        maxPartySize = Config.MaxPartySize or 3
    })
end)

-- Get ride history
RegisterNUICallback("getRideHistory", function(data, cb)
    TriggerServerCallback("laymo:getRideHistory", function(history)
        cb(history or {})
    end)
end)
