local qbCoreStatus = GetResourceState('qb-core')

if qbCoreStatus ~= 'started' and qbCoreStatus ~= 'starting' then return end

error('QB-Core bridge not implemented !')
error('Please add comptability in "server/frameworks/qb.lua')

---Get the player's character identifier
---@param source number
---@return string | nil
function GetIdentifier(source)
    return nil
end

---Check if player is admin
---@param source number
---@return boolean isAdmin
function IsAdmin(source)
    return false
end

---Check if a player has sufficient funds
---@param source number
---@param amount number
---@return boolean success
function CanAfford(source, amount)
    return false
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
    return false
end
