local oxStatus = GetResourceState('ox_core')

if oxStatus ~= 'started' and oxStatus ~= 'starting' then return end

local Ox = require '@ox_core.lib.init'

---Get the player's character identifier
---@param source number
---@return string | nil
function GetIdentifier(source)
    local player = Ox.GetPlayer(source)
    return player?.get('stateId')
end

---Check if player is admin
---@param source number
---@return boolean isAdmin
function IsAdmin(source)
    local player = Ox.GetPlayer(source)

    -- Implement your own check

    return false
end

---Check if a player has sufficient funds
---@param source number
---@param amount number
---@return boolean success
function CanAfford(source, amount)
    local player = Ox.GetPlayer(source)

    if not player then return false end

    local cashAmount = exports.ox_inventory:GetItemCount(source, 'money')

    if cashAmount >= amount then return true end

    local account = player.getAccount()

    if not account then return false end

    local bankBalance = account.get('balance')

    return bankBalance <= amount
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
    local player = Ox.GetPlayer(source)

    if not player then return false end

    local cashAmount = exports.ox_inventory:GetItemCount(source, 'money')

    if cashAmount >= amount then
        local success = exports.ox_inventory:RemoveItem(source, 'money', amount)

        if success then return true end
    end

    local account = player.getAccount()

    if not account then return false end

    local bankBalance = account.get('balance')

    if bankBalance <= amount then
        local response = account.removeBalance({
            amount = amount,
            message = reason,
            overdraw = false,
        })

        if response.success then return true end
    end

    return false
end
