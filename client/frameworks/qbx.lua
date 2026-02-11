local qbxCoreStatus = GetResourceState('qbx_core')

if qbxCoreStatus ~= 'started' and qbxCoreStatus ~= 'starting' then return end

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    CancelRide()
end)
