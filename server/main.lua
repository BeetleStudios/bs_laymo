local QBX = exports.qbx_core

local function GiveRideKeysToPlayer(targetSrc, vehicle)
    if not targetSrc or not vehicle or not DoesEntityExist(vehicle) then
        return
    end

    if GetResourceState("qbx_vehiclekeys") == "started" then
        pcall(function()
            exports.qbx_vehiclekeys:GiveKeys(targetSrc, vehicle, true)
        end)
    elseif GetResourceState("qb-vehiclekeys") == "started" then
        pcall(function()
            exports["qb-vehiclekeys"]:GiveKeys(targetSrc, vehicle, true)
        end)
    end
end

-- Check player balance
RegisterNetEvent("laymo:checkBalance", function(requestId, amount)
    local src = source
    local player = QBX:GetPlayer(src)
    
    if not player then
        TriggerClientEvent("laymo:checkBalance:response:" .. requestId, src, false)
        return
    end
    
    local cash = player.Functions.GetMoney("cash")
    local bank = player.Functions.GetMoney("bank")
    
    local canAfford = (cash >= amount) or (bank >= amount)
    TriggerClientEvent("laymo:checkBalance:response:" .. requestId, src, canAfford)
end)

-- Give player keys to the ride vehicle (so they can enter) - works with qbx_vehiclekeys
RegisterNetEvent("laymo:giveRideKeys", function(vehicleNetId)
    local src = source
    if not vehicleNetId then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    GiveRideKeysToPlayer(src, vehicle)
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
                    GiveRideKeysToPlayer(playerId, vehicle)
                    TriggerClientEvent("laymo:partyBoardingPrompt", playerId, vehicleNetId, src, maxRadius)
                end
            end
        end
    end
end)

-- Charge player for ride
RegisterNetEvent("laymo:chargePlayer", function(amount)
    local src = source
    local player = QBX:GetPlayer(src)
    
    if not player then return end
    
    local cash = player.Functions.GetMoney("cash")
    
    if cash >= amount then
        player.Functions.RemoveMoney("cash", amount, "laymo-fare")
    else
        player.Functions.RemoveMoney("bank", amount, "laymo-fare")
    end
    
    -- Log the ride
    LogRide(src, amount)
    
    -- Notify
    if Config.Debug then
        print(string.format("[Laymo] Player %s charged $%d for ride", GetPlayerName(src), amount))
    end
end)

-- Log ride to database (optional - requires oxmysql)
function LogRide(src, amount)
    local player = QBX:GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
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
    local player = QBX:GetPlayer(src)
    
    if not player then
        TriggerClientEvent("laymo:getRideHistory:response:" .. requestId, src, {})
        return
    end
    
    -- For now, return empty history
    -- You can implement database storage if needed
    TriggerClientEvent("laymo:getRideHistory:response:" .. requestId, src, {})
end)

-- Admin command to set surge pricing
RegisterCommand("laymo:surge", function(source, args, rawCommand)
    if source ~= 0 then
        local player = QBX:GetPlayer(source)
        if not player then return end

        -- Prefer qbx permission check, fall back to ACE for stricter compatibility.
        local hasAdminPerm = false
        if QBX.HasPermission then
            hasAdminPerm = QBX:HasPermission(source, "admin")
        end
        if not hasAdminPerm then
            hasAdminPerm = IsPlayerAceAllowed(source, "command.laymo.surge")
        end

        if not hasAdminPerm then
            return
        end
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
