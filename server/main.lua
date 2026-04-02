-- Check player balance
RegisterNetEvent("laymo:checkBalance", function(requestId, amount)
    local src = source
    local canAfford = CanAfford(src, amount)

    TriggerClientEvent("laymo:checkBalance:response:" .. requestId, src, canAfford)
end)

-- Give player keys to the ride vehicle (so they can enter) - works with qbx_vehiclekeys
RegisterNetEvent("laymo:giveRideKeys", function(vehicleNetId)
    local src = source
    if not vehicleNetId then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    GiveVehicleKeys(src, vehicle)
end)

-- Give temporary ride keys to players near the Laymo vehicle so party members can board.
RegisterNetEvent("laymo:giveRideKeysNearby", function(vehicleNetId, radius)
    local src = source
    if not vehicleNetId then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local requesterPed = GetPlayerPed(src)
    if requesterPed == 0 then return end

    local rideCoords = GetEntityCoords(vehicle)
    local requesterCoords = GetEntityCoords(requesterPed)
    local maxRadius = math.min(math.max(tonumber(radius) or 12.0, 5.0), 25.0)

    -- Anti-abuse: requester must also be near the ride vehicle.
    if #(requesterCoords - rideCoords) > (maxRadius + 5.0) then
        return
    end

    for _, id in ipairs(GetPlayers()) do
        local playerId = tonumber(id)
        if playerId then
            local ped = GetPlayerPed(playerId)
            if ped ~= 0 then
                local pedCoords = GetEntityCoords(ped)
                if #(pedCoords - rideCoords) <= maxRadius then
                    GiveVehicleKeys(playerId, vehicle)
                    TriggerClientEvent("laymo:partyBoardingPrompt", playerId, vehicleNetId, src, maxRadius)
                end
            end
        end
    end
end)

-- Charge player for ride
RegisterNetEvent("laymo:chargePlayer", function(amount)
    local src = source
    -- handle cases where player has insufficient funds
    local success = ChargePlayer(src, amount, 'laymo-fare')

    -- Log the ride
    LogRide(src, amount)

    -- Notify
    if Config.Debug then
        print(string.format("[Laymo] Player %s charged $%d for ride", GetPlayerName(src), amount))
    end
end)

-- Log ride to database (optional - requires oxmysql)
function LogRide(src, amount)
    local identifier = GetIdentifier(src)

    if not identifier then return end

    -- You can uncomment this if you want to store ride history
    --[[
    MySQL.insert('INSERT INTO autoride_history (citizenid, amount, timestamp) VALUES (?, ?, NOW())', {
        citizenid,
        amount
    })
    ]]
end

-- Submit rating (1-5 stars) after trip - optional: log or store in DB
RegisterNetEvent("laymo:submitRating", function(stars)
    local src = source
    if type(stars) ~= "number" or stars < 1 or stars > 5 then return end
    if Config.Debug then
        print(string.format("[Laymo] Player %s rated ride: %d stars", GetPlayerName(src), stars))
    end
    -- Optional: store in database for analytics
end)

-- Get ride history
RegisterNetEvent("laymo:getRideHistory", function(requestId)
    local src = source
    local identifier = GetIdentifier(src)

    if not identifier then
        TriggerClientEvent("laymo:getRideHistory:response:" .. requestId, src, {})
        return
    end

    -- For now, return empty history
    -- You can implement database storage if needed
    TriggerClientEvent("laymo:getRideHistory:response:" .. requestId, src, {})
end)

-- Admin command to set surge pricing
RegisterCommand("laymo:surge", function(src, args, rawCommand)
    if src ~= 0 and not IsAdmin(src) then
        return
    end

    local multiplier = tonumber(args[1])
    if multiplier and multiplier >= 1.0 and multiplier <= 5.0 then
        Config.SurgeMultiplier = multiplier
        print(string.format("[Laymo] Surge pricing set to %.1fx", multiplier))

        -- Notify all players
        TriggerClientEvent("laymo:surgeUpdate", -1, multiplier)
    end
end, true)

-- Version check on startup
CreateThread(function()
    print("^2[Laymo] ^7Autonomous Ride Service loaded successfully")
    print("^2[Laymo] ^7Version: 1.0.0")
end)
