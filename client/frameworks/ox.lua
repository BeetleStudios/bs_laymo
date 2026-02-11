local oxStatus = GetResourceState('ox_core')

if oxStatus ~= 'started' and oxStatus ~= 'starting' then return end

RegisterNetEvent("ox:playerLogout", function()
    CancelRide()
end)
