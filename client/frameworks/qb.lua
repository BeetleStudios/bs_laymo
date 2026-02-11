local qbCoreStatus = GetResourceState('qb-core')

if qbCoreStatus ~= 'started' and qbCoreStatus ~= 'starting' then return end

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    CancelRide()
end)
