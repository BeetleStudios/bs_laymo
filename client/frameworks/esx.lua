local esxStatus = GetResourceState('es_extended')

if esxStatus ~= 'started' and esxStatus ~= 'starting' then return end

RegisterNetEvent("esx:onPlayerLogout", function()
    CancelRide()
end)
