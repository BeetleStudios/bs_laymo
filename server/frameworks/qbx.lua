local qbxCoreStatus = GetResourceState('qbx_core')

if qbxCoreStatus ~= 'started' and qbxCoreStatus ~= 'starting' then return end

local QBX = exports.qbx_core

---Get the player's character identifier
---@param source number
---@return string | nil
function GetIdentifier(source)
    local player = QBX:GetPlayer(source)
    return player.PlayerData.citizenid
end

---Check if player is admin
---@param source number
---@return boolean isAdmin
function IsAdmin(source)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    return QBX:HasPermission(source, "admin")
end

---Check if a player has sufficient funds
---@param source number
---@param amount number
---@return boolean success
function CanAfford(source, amount)
    local player = QBX:GetPlayer(source)

    if not player then return false end

    local cash = player.Functions.GetMoney("cash")
    local bank = player.Functions.GetMoney("bank")

    return (cash >= amount) or (bank >= amount)
end

---Give the player keys to the vehicle
---@param source number
---@param vehicle number vehicle entity handle (not netId)
function GiveVehicleKeys(source, vehicle)
    if GetResourceState("qbx_vehiclekeys") == "started" then
        pcall(function()
            exports.qbx_vehiclekeys:GiveKeys(source, vehicle, true)
        end)
    elseif GetResourceState("qb-vehiclekeys") == "started" then
        pcall(function()
            exports["qb-vehiclekeys"]:GiveKeys(source, vehicle, true)
        end)
    end
end

---Charge a player
---@param source number
---@param amount number
---@param reason string
---@return boolean success
function ChargePlayer(source, amount, reason)
    local player = QBX:GetPlayer(source)

    if not player then return false end

    local cash = player.Functions.GetMoney("cash")
    local bank = player.Functions.GetMoney("bank")

    if cash >= amount then
        player.Functions.RemoveMoney("cash", amount, reason)
    elseif bank >= amount then
        player.Functions.RemoveMoney("bank", amount, reason)
    else
        return false
    end

    return true
end
