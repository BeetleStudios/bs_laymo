-- Framework: Config.Framework — 'qbx' (Qbox), 'qb' (qb-core), 'esx' (ESX Legacy), 'ox' (ox_core)
local FRAMEWORK = (Config and Config.Framework) or 'qbx'
if FRAMEWORK == 'ox_core' then
    FRAMEWORK = 'ox'
end
if FRAMEWORK ~= 'qb' and FRAMEWORK ~= 'esx' and FRAMEWORK ~= 'ox' then
    FRAMEWORK = 'qbx'
end

local ESX

local function EnsureESX()
    if ESX then
        return ESX
    end
    if FRAMEWORK ~= 'esx' or GetResourceState('es_extended') ~= 'started' then
        return nil
    end
    pcall(function()
        ESX = exports['es_extended']:getSharedObject()
    end)
    return ESX
end

local oxCore = (FRAMEWORK == 'ox') and exports.ox_core or nil

local QBCore

local function QbGetCore()
    if QBCore then
        return QBCore
    end
    if GetResourceState('qb-core') ~= 'started' then
        return nil
    end
    local ok, core = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok and core then
        QBCore = core
    end
    return QBCore
end

local function FrameworkGetWalletPlayer(source)
    if not source then
        return nil
    end
    if FRAMEWORK == 'qb' then
        local core = QbGetCore()
        if not core or not core.Functions then
            return nil
        end
        return core.Functions.GetPlayer(source)
    end
    if FRAMEWORK == 'qbx' then
        if GetResourceState('qbx_core') ~= 'started' then
            return nil
        end
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(source)
        end)
        return (ok and player) and player or nil
    end
    return nil
end

local function OxGetCharId(source)
    if not oxCore then
        return nil
    end
    local ok, data = pcall(function()
        return oxCore:GetPlayer(source)
    end)
    if not ok or not data then
        return nil
    end
    return data.charId
end

local function OxGetAccountId(source)
    local charId = OxGetCharId(source)
    if not charId then
        return nil
    end
    local ok, acc = pcall(function()
        return oxCore:GetCharacterAccount(charId)
    end)
    if not ok or not acc then
        return nil
    end
    return acc.accountId
end

local function FrameworkGetCash(source)
    if FRAMEWORK == 'ox' then
        return 0
    end
    if FRAMEWORK == 'esx' then
        local ex = EnsureESX()
        if not ex then
            return 0
        end
        local xPlayer = ex.GetPlayerFromId(source)
        if not xPlayer then
            return 0
        end
        local acc = xPlayer.getAccount('money')
        return (acc and acc.money) and acc.money or 0
    end
    local player = FrameworkGetWalletPlayer(source)
    if not player or not player.Functions or not player.Functions.GetMoney then
        return 0
    end
    return player.Functions.GetMoney('cash') or 0
end

local function FrameworkGetBank(source)
    if FRAMEWORK == 'ox' then
        local accountId = OxGetAccountId(source)
        if not accountId then
            return 0
        end
        local ok, balance = pcall(function()
            return oxCore:CallAccount(accountId, 'get', 'balance')
        end)
        return (ok and balance) and (tonumber(balance) or 0) or 0
    end
    if FRAMEWORK == 'esx' then
        local ex = EnsureESX()
        if not ex then
            return 0
        end
        local xPlayer = ex.GetPlayerFromId(source)
        if not xPlayer then
            return 0
        end
        local acc = xPlayer.getAccount('bank')
        return (acc and acc.money) and acc.money or 0
    end
    local player = FrameworkGetWalletPlayer(source)
    if not player or not player.Functions or not player.Functions.GetMoney then
        return 0
    end
    return player.Functions.GetMoney('bank') or 0
end

local function FrameworkChargeLaymoFare(source, amount)
    if not amount or amount <= 0 then
        return false
    end
    if FRAMEWORK == 'ox' then
        local accountId = OxGetAccountId(source)
        if not accountId then
            return false
        end
        local ok, res = pcall(function()
            return oxCore:CallAccount(accountId, 'removeBalance', {
                amount = amount,
                message = 'laymo-fare',
            })
        end)
        return ok and res and res.success == true
    end
    if FRAMEWORK == 'esx' then
        local ex = EnsureESX()
        if not ex then
            return false
        end
        local xPlayer = ex.GetPlayerFromId(source)
        if not xPlayer then
            return false
        end
        local cashAcc = xPlayer.getAccount('money')
        local cash = (cashAcc and cashAcc.money) or 0
        if cash >= amount then
            xPlayer.removeAccountMoney('money', amount, 'laymo-fare')
            return true
        end
        xPlayer.removeAccountMoney('bank', amount, 'laymo-fare')
        return true
    end
    local player = FrameworkGetWalletPlayer(source)
    if not player or not player.Functions or not player.Functions.RemoveMoney or not player.Functions.GetMoney then
        return false
    end
    local cash = player.Functions.GetMoney('cash') or 0
    if cash >= amount then
        player.Functions.RemoveMoney('cash', amount, 'laymo-fare')
        return true
    end
    player.Functions.RemoveMoney('bank', amount, 'laymo-fare')
    return true
end

local function FrameworkGetCharacterId(source)
    if FRAMEWORK == 'esx' then
        local ex = EnsureESX()
        if not ex then
            return nil
        end
        local xPlayer = ex.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end
    if FRAMEWORK == 'ox' then
        return OxGetCharId(source)
    end
    local player = FrameworkGetWalletPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

local function FrameworkHasAdminPermission(source)
    if FRAMEWORK == 'qbx' then
        local ok, has = pcall(function()
            return exports.qbx_core:HasPermission(source, 'admin')
        end)
        if ok and has then
            return true
        end
    elseif FRAMEWORK == 'qb' then
        local core = QbGetCore()
        if core and core.Functions then
            if core.Functions.HasPermission then
                local ok, has = pcall(function()
                    return core.Functions.HasPermission(source, 'admin')
                end)
                if ok and has then
                    return true
                end
            end
        end
    elseif FRAMEWORK == 'esx' then
        local ex = EnsureESX()
        local xPlayer = ex and ex.GetPlayerFromId(source)
        if xPlayer and xPlayer.getGroup then
            local group = xPlayer.getGroup()
            if group == 'admin' or group == 'superadmin' then
                return true
            end
        end
    end
    return IsPlayerAceAllowed(source, 'command.laymo.surge')
end

local function GiveRideKeysToPlayer(targetSrc, vehicle)
    if not targetSrc or not vehicle or not DoesEntityExist(vehicle) then
        return
    end

    if GetResourceState('qbx_vehiclekeys') == 'started' then
        pcall(function()
            exports.qbx_vehiclekeys:GiveKeys(targetSrc, vehicle, true)
        end)
    elseif GetResourceState('qb-vehiclekeys') == 'started' then
        pcall(function()
            exports['qb-vehiclekeys']:GiveKeys(targetSrc, vehicle, true)
        end)
    end
end

-- Check player balance
RegisterNetEvent('laymo:checkBalance', function(requestId, amount)
    local src = source
    local cash = FrameworkGetCash(src)
    local bank = FrameworkGetBank(src)
    local canAfford = (cash >= amount) or (bank >= amount)
    TriggerClientEvent('laymo:checkBalance:response:' .. requestId, src, canAfford)
end)

RegisterNetEvent('laymo:giveRideKeys', function(vehicleNetId)
    local src = source
    if not vehicleNetId then
        return
    end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end
    GiveRideKeysToPlayer(src, vehicle)
end)

RegisterNetEvent('laymo:giveRideKeysNearby', function(vehicleNetId, radius)
    local src = source
    if not vehicleNetId then
        return
    end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end

    local requesterPed = GetPlayerPed(src)
    if requesterPed == 0 then
        return
    end

    local rideCoords = GetEntityCoords(vehicle)
    local requesterCoords = GetEntityCoords(requesterPed)
    local maxRadius = math.min(math.max(tonumber(radius) or 12.0, 5.0), 25.0)

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
                    TriggerClientEvent('laymo:partyBoardingPrompt', playerId, vehicleNetId, src, maxRadius)
                end
            end
        end
    end
end)

RegisterNetEvent('laymo:chargePlayer', function(amount)
    local src = source
    if FRAMEWORK == 'ox' then
        if not OxGetCharId(src) then
            return
        end
    elseif FRAMEWORK == 'esx' then
        local ex = EnsureESX()
        if not ex or not ex.GetPlayerFromId(src) then
            return
        end
    else
        if not FrameworkGetWalletPlayer(src) then
            return
        end
    end
    local charged = FrameworkChargeLaymoFare(src, amount)
    if charged then
        LogRide(src, amount)
    end
    if Config.Debug and charged then
        print(string.format('[Laymo] Player %s charged $%d for ride', GetPlayerName(src), amount))
    end
end)

function LogRide(src, amount)
    local cid = FrameworkGetCharacterId(src)
    if not cid then
        return
    end
    --[[
    MySQL.insert('INSERT INTO autoride_history (citizenid, amount, timestamp) VALUES (?, ?, NOW())', {
        cid,
        amount
    })
    ]]
end

RegisterNetEvent('laymo:submitRating', function(stars)
    local src = source
    if type(stars) ~= 'number' or stars < 1 or stars > 5 then
        return
    end
    if Config.Debug then
        print(string.format('[Laymo] Player %s rated ride: %d stars', GetPlayerName(src), stars))
    end
end)

RegisterNetEvent('laymo:getRideHistory', function(requestId)
    local src = source
    TriggerClientEvent('laymo:getRideHistory:response:' .. requestId, src, {})
end)

RegisterCommand('laymo:surge', function(source, args, rawCommand)
    if source ~= 0 then
        if not FrameworkHasAdminPermission(source) then
            return
        end
    end

    local multiplier = tonumber(args[1])
    if multiplier and multiplier >= 1.0 and multiplier <= 5.0 then
        Config.SurgeMultiplier = multiplier
        print(string.format('[Laymo] Surge pricing set to %.1fx', multiplier))
        TriggerClientEvent('laymo:surgeUpdate', -1, multiplier)
    end
end, true)

CreateThread(function()
    print('^2[Laymo] ^7Autonomous Ride Service loaded (framework: ' .. tostring(FRAMEWORK) .. ')')
    print('^2[Laymo] ^7Version: 1.0.0')
    local res = ({
        qbx = 'qbx_core',
        qb = 'qb-core',
        esx = 'es_extended',
        ox = 'ox_core',
    })[FRAMEWORK]
    if res and GetResourceState(res) ~= 'started' then
        print(('^3[Laymo] ^7Config.Framework is %s but ^1%s^7 is not started — money checks may fail.'):format(FRAMEWORK, res))
    end
end)
