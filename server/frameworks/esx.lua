local esxStatus = GetResourceState('es_extended')

if esxStatus ~= 'started' and esxStatus ~= 'starting' then return end

local ESX = exports.es_extended:getSharedObject()

---Get the player's character identifier
---@param source number
---@return string | nil
function GetIdentifier(source)
    local player = ESX.GetPlayerFromId(source)
    return player?.getIdentifier()
end

---Check if player is admin
---@param source number
---@return boolean isAdmin
function IsAdmin(source)
    local player = ESX.GetPlayerFromId(source)
    return player?.getGroup() == "superadmin"
end

---Check if a player has sufficient funds
---@param source number
---@param amount number
---@return boolean success
function CanAfford(source, amount)
    local player = ESX.GetPlayerFromId(source)

    if not player then return false end

    local cashAmount = player.getAccount("money")?.money or 0

    if cashAmount >= amount then return true end

    local bankAmount = player.getAccount("bank")?.money or 0

    return bankAmount >= amount
end

---Give the player keys to the vehicle
---@param source number
---@param vehicle number vehicle entity handle (not netId)
function GiveVehicleKeys(source, vehicle)
end

---Charge a player
---@param source number
---@param amount number
---@param reason string
---@return boolean success
function ChargePlayer(source, amount, reason)
    local player = ESX.GetPlayerFromId(source)

    if not player then return false end

    local cashAmount = player.getAccount("money")?.money or 0

    if cashAmount >= amount then
        player.removeAccountMoney('money', amount, reason)
        return true
    end

    local bankAmount = player.getAccount("mbankoney")?.money or 0

    if bankAmount >= amount then
        player.removeAccountMoney('bank', amount, reason)
        return true
    end

    return false
end
