local QBX = exports.qbx_core
local PlayerData = {}
local currentRide = nil
local rideVehicle = nil
local rideDriver = nil
local driverBlip = nil
local rideState = "idle" -- idle, waiting, arriving, pickup, riding, completed, cancelled

-- Initialize
CreateThread(function()
    while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end
    
    local added, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = Config.AppIdentifier,
        name = Config.AppName,
        description = Config.AppDescription,
        developer = Config.AppDeveloper,
        defaultApp = true,
        size = Config.AppSize,
        
        images = {
            "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/dist/screenshot-light.png",
            "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/dist/screenshot-dark.png"
        },
        
        ui = GetCurrentResourceName() .. "/ui/dist/index.html",
        -- ui = "http://localhost:3000", -- Uncomment for development
        
        icon = "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/dist/icon.png",
        fixBlur = true
    })
    
    if not added then
        print("^1[Laymo] Could not add app: " .. tostring(errorMessage))
    else
        print("^2[Laymo] App registered successfully")
    end
end)

-- Re-add app if lb-phone restarts
AddEventHandler("onResourceStart", function(resource)
    if resource == "lb-phone" then
        Wait(1000)
        exports["lb-phone"]:AddCustomApp({
            identifier = Config.AppIdentifier,
            name = Config.AppName,
            description = Config.AppDescription,
            developer = Config.AppDeveloper,
            defaultApp = true,
            size = Config.AppSize,
            images = {
                "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/dist/screenshot-light.png",
                "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/dist/screenshot-dark.png"
            },
            ui = GetCurrentResourceName() .. "/ui/dist/index.html",
            icon = "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/dist/icon.png",
            fixBlur = true
        })
    end
end)

-- Player data management
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    PlayerData = QBX:GetPlayerData()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    PlayerData = {}
    CancelRide()
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        PlayerData = QBX:GetPlayerData() or {}
    end
end)

-- Helper Functions
local function Notify(message, type)
    if Config.UseOxLib then
        lib.notify({
            title = "Laymo",
            description = message,
            type = type or "info"
        })
    else
        exports["lb-phone"]:SendNotification({
            app = Config.AppIdentifier,
            title = "Laymo",
            content = message
        })
    end
end

local function CalculateDistance(coords1, coords2)
    return #(vector3(coords1.x, coords1.y, coords1.z) - vector3(coords2.x, coords2.y, coords2.z))
end

local function CalculatePrice(distance, tier)
    local miles = distance / 1609.34
    local tierMultiplier = Config.TierPricing[tier] or 1.0
    local price = (Config.BasePrice + (miles * Config.PricePerMile)) * tierMultiplier * Config.SurgeMultiplier
    return math.max(math.floor(price), Config.MinimumFare)
end

local function GetRandomVehicle(tier, partySize)
    partySize = partySize or 0
    local minSeats = 1 + partySize -- player + party members
    local vehicles = {}
    for _, v in ipairs(Config.Vehicles) do
        local seats = v.seats or 3
        if (not tier or v.tier == tier) and seats >= minSeats then
            table.insert(vehicles, v)
        end
    end
    if #vehicles == 0 then
        for _, v in ipairs(Config.Vehicles) do
            if not tier or v.tier == tier then
                table.insert(vehicles, v)
            end
        end
    end
    return vehicles[math.random(#vehicles)]
end

local function GetRandomDriverModel()
    return Config.DriverModels[math.random(#Config.DriverModels)]
end

local function CreateDriverBlip(entity)
    if driverBlip then
        RemoveBlip(driverBlip)
    end
    
    if Config.ShowDriverBlip then
        driverBlip = AddBlipForEntity(entity)
        SetBlipSprite(driverBlip, Config.DriverBlipSprite)
        SetBlipColour(driverBlip, Config.DriverBlipColor)
        SetBlipScale(driverBlip, Config.DriverBlipScale)
        SetBlipAsShortRange(driverBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Laymo Driver")
        EndTextCommandSetBlipName(driverBlip)
    end
end

local function RemoveDriverBlip()
    if driverBlip then
        RemoveBlip(driverBlip)
        driverBlip = nil
    end
end

local function CleanupRide()
    RemoveDriverBlip()
    
    if rideDriver and DoesEntityExist(rideDriver) then
        DeleteEntity(rideDriver)
        rideDriver = nil
    end
    
    if rideVehicle and DoesEntityExist(rideVehicle) then
        DeleteEntity(rideVehicle)
        rideVehicle = nil
    end
    
    currentRide = nil
    rideState = "idle"
end

function CancelRide()
    if rideState ~= "idle" then
        CleanupRide()
        Notify("Ride cancelled", "error")
        SendAppMessage({ type = "rideUpdate", state = "cancelled" })
    end
end

-- Player requested to end ride during trip: NPC pulls over, player gets out, partial fare charged
function RequestPullOver()
    if rideState ~= "riding" or not currentRide or not DoesEntityExist(rideVehicle) then
        return
    end
    rideState = "pulling_over"

    CreateThread(function()
        ClearPedTasks(rideDriver)
        TaskVehicleTempAction(rideDriver, rideVehicle, 1, 8000) -- Brake
        Notify("Pulling over - you can get out when we've stopped", "info")
        SendAppMessage({ type = "rideUpdate", state = "pulling_over" })

        -- Wait for vehicle to stop (or max 5 seconds)
        local waitCount = 0
        while GetEntitySpeed(rideVehicle) > 1.0 and waitCount < 50 do
            Wait(100)
            waitCount = waitCount + 1
        end
        Wait(500)

        Notify("You can get out now", "success")

        -- Distance traveled (vehicle position where we stopped)
        local vehCoords = GetEntityCoords(rideVehicle)
        local destVec = vector3(currentRide.destination.x, currentRide.destination.y, currentRide.destination.z)
        local distToDest = #(vehCoords - destVec)
        local traveled = math.max(0, currentRide.distance - distToDest)
        local partialPrice = CalculatePrice(traveled, currentRide.vehicle.tier)

        -- Wait for player to exit
        local playerPed = PlayerPedId()
        while DoesEntityExist(rideVehicle) and IsPedInVehicle(playerPed, rideVehicle, false) do
            Wait(500)
        end

        if partialPrice > 0 then
            TriggerServerEvent("laymo:chargePlayer", partialPrice)
            Notify("Ride ended. Charged: $" .. partialPrice, "info")
        else
            Notify("Ride ended", "info")
        end

        SendAppMessage({
            type = "rideUpdate",
            state = "cancelled",
            message = "Ride ended early",
            price = partialPrice
        })
        CleanupRide()
    end)
end

-- Find a position on the road/street nearest to the given coords (e.g. player on sidewalk).
-- If targetCoords is given, prefers a curb-side position on the side of the street closer to target (so we don't stop in the middle).
local function FindRoadPositionNearCoords(coords, targetCoords)
    local x, y, z = coords.x, coords.y, coords.z
    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
    if not foundGround then
        groundZ = z
    end
    local success, outPos, outHeading = GetClosestVehicleNodeWithHeading(x, y, groundZ, 1, 3.0, 0)
    if not success or not outPos then
        -- Fallback: try points around to find a road node
        for _, offset in ipairs({ {5, 0}, {-5, 0}, {0, 5}, {0, -5}, {8, 0}, {-8, 0}, {10, 0}, {0, 10} }) do
            local tx, ty = x + offset[1], y + offset[2]
            local ok, pos, head = GetClosestVehicleNodeWithHeading(tx, ty, groundZ, 1, 3.0, 0)
            if ok and pos then
                outPos, outHeading = pos, (head or 0.0)
                success = true
                break
            end
        end
    end
    if not success or not outPos then
        return nil
    end

    -- Prefer a curb-side position: offset perpendicular to the road and snap back to a lane on that side (avoids stopping in the middle of the street)
    local curbOffset = (type(Config.CurbOffsetMeters) == "number" and Config.CurbOffsetMeters > 0) and Config.CurbOffsetMeters or 0
    local target = targetCoords or coords
    local tx, ty, tz = target.x, target.y, target.z

    if curbOffset > 0 and outHeading then
        local h = math.rad(outHeading)
        -- Perpendicular to road direction (GTA: 0 = North/+Y). Right side: add (cos(h)*d, sin(h)*d)
        local rightX = outPos.x + math.cos(h) * curbOffset
        local rightY = outPos.y + math.sin(h) * curbOffset
        local leftX = outPos.x - math.cos(h) * curbOffset
        local leftY = outPos.y - math.sin(h) * curbOffset

        local rightOk, rightPos = GetClosestVehicleNodeWithHeading(rightX, rightY, outPos.z, 1, 3.0, 0)
        local leftOk, leftPos = GetClosestVehicleNodeWithHeading(leftX, leftY, outPos.z, 1, 3.0, 0)

        if rightOk and rightPos and leftOk and leftPos then
            local distRight = #(vector3(rightPos.x, rightPos.y, rightPos.z) - vector3(tx, ty, tz))
            local distLeft = #(vector3(leftPos.x, leftPos.y, leftPos.z) - vector3(tx, ty, tz))
            -- Pick the side closer to the target (player or destination) so we stop at the curb they're on
            if distRight <= distLeft then
                return { x = rightPos.x, y = rightPos.y, z = rightPos.z }
            else
                return { x = leftPos.x, y = leftPos.y, z = leftPos.z }
            end
        elseif rightOk and rightPos then
            return { x = rightPos.x, y = rightPos.y, z = rightPos.z }
        elseif leftOk and leftPos then
            return { x = leftPos.x, y = leftPos.y, z = leftPos.z }
        end
    end

    return { x = outPos.x, y = outPos.y, z = outPos.z }
end

local function FindSpawnPoint(playerCoords)
    local attempts = 0
    local spawnCoords = nil
    
    while attempts < 20 and not spawnCoords do
        local angle = math.random() * 2 * math.pi
        local distance = math.random(Config.MinPickupDistance, Config.PickupDistance)
        local testX = playerCoords.x + math.cos(angle) * distance
        local testY = playerCoords.y + math.sin(angle) * distance
        
        local foundGround, groundZ = GetGroundZFor_3dCoord(testX, testY, playerCoords.z + 50.0, false)
        if foundGround then
            local nodeCoords = vector3(testX, testY, groundZ)
            local success, outPos, outHeading = GetClosestVehicleNodeWithHeading(testX, testY, groundZ, 1, 3.0, 0)
            if success then
                spawnCoords = { x = outPos.x, y = outPos.y, z = outPos.z, heading = outHeading }
            end
        end
        attempts = attempts + 1
    end
    
    return spawnCoords
end

-- Spawn the ride vehicle and driver
local function SpawnRideVehicle(vehicleData, pickupCoords, destinationCoords)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Find spawn point
    local spawnPoint = FindSpawnPoint(playerCoords)
    if not spawnPoint then
        Notify("Could not find a suitable pickup location", "error")
        return false
    end
    
    -- Load vehicle model
    local vehicleHash = joaat(vehicleData.model)
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Wait(10)
    end
    
    -- Load driver model
    local driverHash = joaat(GetRandomDriverModel())
    RequestModel(driverHash)
    while not HasModelLoaded(driverHash) do
        Wait(10)
    end
    
    -- Create vehicle (don't set as mission entity so player can enter normally)
    rideVehicle = CreateVehicle(vehicleHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.heading, true, false)
    SetVehicleOnGroundProperly(rideVehicle)
    SetVehicleEngineOn(rideVehicle, true, true, false)
    SetVehicleDoorsLocked(rideVehicle, 1) -- 1 = unlocked (0 can block entry on some builds)
    SetVehicleDoorsLockedForPlayer(rideVehicle, PlayerId(), false)
    SetVehicleDoorsLockedForAllPlayers(rideVehicle, false)
    SetEntityAsMissionEntity(rideVehicle, false, false)
    
    -- Set vehicle extras (make it look like a taxi/rideshare)
    SetVehicleColours(rideVehicle, 0, 0) -- Black
    SetVehicleNumberPlateText(rideVehicle, Config.VehiclePlate or "LAYMO")
    
    -- Create driver
    rideDriver = CreatePedInsideVehicle(rideVehicle, 26, driverHash, -1, true, false)
    SetEntityAsMissionEntity(rideDriver, true, true)
    SetBlockingOfNonTemporaryEvents(rideDriver, true)
    SetPedCanBeDraggedOut(rideDriver, false)
    SetPedCanBeKnockedOffVehicle(rideDriver, 1)
    SetPedConfigFlag(rideDriver, 32, false) -- Can't be pulled out
    
    -- Release models
    SetModelAsNoLongerNeeded(vehicleHash)
    SetModelAsNoLongerNeeded(driverHash)
    
    -- Create blip
    CreateDriverBlip(rideVehicle)
    
    return true
end

-- Get speed and driving style for current ride (normal vs "in a hurry")
local function GetRideDriveParams()
    if currentRide and currentRide.inAHurry then
        return Config.MaxSpeedRushed or 38.0, Config.DrivingStyleRushed or 786468
    end
    return Config.MaxSpeed, Config.DrivingStyle
end

-- Request a ride
function RequestRide(pickupCoords, destinationCoords, tier, inAHurry, partySize)
    if rideState ~= "idle" then
        Notify("You already have an active ride", "error")
        return
    end

    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        Notify("Please exit your current vehicle first", "error")
        return
    end

    partySize = partySize or 0

    -- Get vehicle for this tier with enough seats for player + party
    local vehicleData = GetRandomVehicle(tier, partySize)
    local distance = CalculateDistance(pickupCoords, destinationCoords)
    local price = CalculatePrice(distance, vehicleData.tier)
    
    -- Check if player can afford
    TriggerServerCallback("laymo:checkBalance", function(canAfford)
        if not canAfford then
            Notify("Insufficient funds", "error")
            SendAppMessage({ type = "rideUpdate", state = "error", message = "Insufficient funds" })
            return
        end
        
        currentRide = {
            pickup = pickupCoords,
            destination = destinationCoords,
            vehicle = vehicleData,
            price = price,
            distance = distance,
            startTime = GetGameTimer(),
            inAHurry = inAHurry == true,
            partySize = partySize
        }

        rideState = "waiting"
        
        -- Spawn vehicle
        if SpawnRideVehicle(vehicleData, pickupCoords, destinationCoords) then
            rideState = "arriving"
            
            -- Send ETA to app
            local vehCoords = GetEntityCoords(rideVehicle)
            local etaDistance = CalculateDistance(vehCoords, pickupCoords)
            local eta = math.ceil(etaDistance / 15) -- Rough ETA in seconds
            
            SendAppMessage({
                type = "rideUpdate",
                state = "arriving",
                vehicle = vehicleData.name,
                tier = vehicleData.tier,
                price = price,
                eta = eta,
                driverName = GetRandomDriverName(),
                partySize = currentRide.partySize or 0
            })
            
            Notify("Your Laymo is on the way!", "success")
            
            -- Start autopilot to pickup
            StartPickupAutopilot(pickupCoords, destinationCoords)
        else
            rideState = "idle"
            currentRide = nil
            SendAppMessage({ type = "rideUpdate", state = "error", message = "Could not dispatch vehicle" })
        end
    end, price)
end

function GetRandomDriverName()
    local firstNames = {"Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Quinn", "Avery", "Skyler", "Jamie"}
    local lastInitials = {"A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "R", "S", "T", "W"}
    return firstNames[math.random(#firstNames)] .. " " .. lastInitials[math.random(#lastInitials)] .. "."
end

-- Autopilot to pickup location (stops on the street at the curb, not on the sidewalk)
function StartPickupAutopilot(pickupCoords, destinationCoords)
    CreateThread(function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        -- Stop on the road/street at the curb nearest the player (not in the middle of the lane)
        local stopOnStreet = FindRoadPositionNearCoords(playerCoords, playerCoords)
        if not stopOnStreet then
            stopOnStreet = pickupCoords
        end
        local stopVec = vector3(stopOnStreet.x, stopOnStreet.y, stopOnStreet.z)

        local stopRadius = (type(Config.StopRadius) == "number" and Config.StopRadius > 0) and Config.StopRadius or 5.0
        -- Drive to the curb position; use rushed speed/style if "in a hurry"
        local driveSpeed, driveStyle = GetRideDriveParams()
        TaskVehicleDriveToCoordLongrange(rideDriver, rideVehicle, stopOnStreet.x, stopOnStreet.y, stopOnStreet.z, driveSpeed, driveStyle, stopRadius)

        local waitStartTime = GetGameTimer()
        local arrivedAtPickup = false
        local pickupApproachTier = "far"

        while rideState == "arriving" do
            Wait(500)

            if not DoesEntityExist(rideVehicle) or not DoesEntityExist(rideDriver) then
                CancelRide()
                return
            end

            local vehCoords = GetEntityCoords(rideVehicle)
            local distToStop = #(vehCoords - stopVec)

            -- Slow down when approaching pickup (same idea as destination)
            local d1 = Config.ApproachSlowDistance1 or 80.0
            local d2 = Config.ApproachSlowDistance2 or 45.0
            local d3 = Config.ApproachSlowDistance3 or 28.0
            local s1 = Config.ApproachSpeed1 or 14.0
            local s2 = Config.ApproachSpeed2 or 8.0
            local s3 = Config.ApproachSpeed3 or 4.0
            if distToStop < d3 and pickupApproachTier ~= "crawl" then
                pickupApproachTier = "crawl"
                ClearPedTasks(rideDriver)
                TaskVehicleDriveToCoordLongrange(rideDriver, rideVehicle, stopOnStreet.x, stopOnStreet.y, stopOnStreet.z, s3, driveStyle, stopRadius)
            elseif distToStop < d2 and pickupApproachTier ~= "near" and pickupApproachTier ~= "crawl" then
                pickupApproachTier = "near"
                ClearPedTasks(rideDriver)
                TaskVehicleDriveToCoordLongrange(rideDriver, rideVehicle, stopOnStreet.x, stopOnStreet.y, stopOnStreet.z, s2, driveStyle, stopRadius)
            elseif distToStop < d1 and pickupApproachTier == "far" then
                pickupApproachTier = "mid"
                ClearPedTasks(rideDriver)
                TaskVehicleDriveToCoordLongrange(rideDriver, rideVehicle, stopOnStreet.x, stopOnStreet.y, stopOnStreet.z, s1, driveStyle, stopRadius)
            end

            -- Update app with current distance/ETA
            local eta = math.ceil(distToStop / 15)
            SendAppMessage({
                type = "etaUpdate",
                eta = eta,
                distance = math.floor(distToStop)
            })

            if distToStop < 15.0 and not arrivedAtPickup then
                arrivedAtPickup = true
                rideState = "pickup"

                -- Stop the vehicle on the street
                ClearPedTasks(rideDriver)
                TaskVehicleTempAction(rideDriver, rideVehicle, 1, 2000) -- Brake

                -- Give player keys so they can enter (qb-vehiclekeys / qbx_vehiclekeys)
                local netId = NetworkGetNetworkIdFromEntity(rideVehicle)
                if netId and netId ~= 0 then
                    TriggerServerEvent("laymo:giveRideKeys", netId)
                end
                -- Ensure doors stay enterable
                SetVehicleDoorsLocked(rideVehicle, 1) -- 1 = unlocked
                SetVehicleDoorsLockedForPlayer(rideVehicle, PlayerId(), false)
                SetVehicleDoorsLockedForAllPlayers(rideVehicle, false)

                Notify("Your Laymo has arrived! Enter the vehicle.", "success")
                SendAppMessage({ type = "rideUpdate", state = "arrived" })

                -- Wait for player to enter
                WaitForPlayerEntry(destinationCoords)
                return
            end

            -- Timeout check
            if (GetGameTimer() - waitStartTime) > (Config.MaxWaitTime * 1000) then
                CancelRide()
                Notify("Ride cancelled - vehicle took too long", "error")
                return
            end
        end
    end)
end

-- Wait for player to enter vehicle
function WaitForPlayerEntry(destinationCoords)
    CreateThread(function()
        local waitStart = GetGameTimer()
        local enterRadius = 4.0

        while rideState == "pickup" do
            Wait(0)

            local playerPed = PlayerPedId()

            if not DoesEntityExist(rideVehicle) then
                CancelRide()
                return
            end

            -- Check if player entered the vehicle (normal entry or warp)
            if IsPedInVehicle(playerPed, rideVehicle, false) then
                rideState = "riding"
                Notify("Heading to your destination!", "success")
                SendAppMessage({ type = "rideUpdate", state = "riding" })
                StartDestinationAutopilot(destinationCoords)
                return
            end

            -- When close to vehicle: show prompt and allow warp-in if they press E (bypasses any entry block)
            local playerCoords = GetEntityCoords(playerPed)
            local vehCoords = GetEntityCoords(rideVehicle)
            local dist = #(playerCoords - vehCoords)
            if dist <= enterRadius then
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentString("Press ~INPUT_CONTEXT~ to enter Laymo")
                EndTextCommandDisplayHelp(0, false, false, -1)
                if IsControlJustPressed(0, 51) then -- INPUT_CONTEXT (E)
                    TaskWarpPedIntoVehicle(playerPed, rideVehicle, -2) -- -2 = front passenger
                end
            end

            -- Timeout check
            if (GetGameTimer() - waitStart) > (Config.PickupTimeout * 1000) then
                CancelRide()
                Notify("Ride cancelled - you didn't enter the vehicle in time", "error")
                SendAppMessage({ type = "rideUpdate", state = "cancelled", message = "Pickup timeout" })
                return
            end
        end
    end)
end

-- Autopilot to destination (driver slows when approaching; destination resolved to street)
function StartDestinationAutopilot(destinationCoords)
    CreateThread(function()
        -- Resolve destination to the nearest street/road at the curb (side of road toward destination, not middle of lane)
        local stopOnStreet = FindRoadPositionNearCoords(destinationCoords, destinationCoords)
        if not stopOnStreet then
            stopOnStreet = destinationCoords
        end
        local destVec = vector3(stopOnStreet.x, stopOnStreet.y, stopOnStreet.z)

        local stopRadius = (type(Config.StopRadius) == "number" and Config.StopRadius > 0) and Config.StopRadius or 5.0
        -- Drive to curb position at full cruise speed; we will slow in the loop as we get close
        local driveSpeed, driveStyle = GetRideDriveParams()
        TaskVehicleDriveToCoordLongrange(rideDriver, rideVehicle, stopOnStreet.x, stopOnStreet.y, stopOnStreet.z, driveSpeed, driveStyle, stopRadius)

        local approachTier = "far" -- far -> mid -> near -> crawl -> stop

        while rideState == "riding" do
            Wait(500)

            if not DoesEntityExist(rideVehicle) or not DoesEntityExist(rideDriver) then
                -- Vehicle destroyed during ride
                Notify("Ride ended unexpectedly", "error")
                rideState = "idle"
                currentRide = nil
                return
            end

            local vehCoords = GetEntityCoords(rideVehicle)
            local distToDest = #(vehCoords - destVec)

            -- Approach slowing: re-issue drive task with lower speed as we get close
            local d1 = Config.ApproachSlowDistance1 or 80.0
            local d2 = Config.ApproachSlowDistance2 or 45.0
            local d3 = Config.ApproachSlowDistance3 or 28.0
            local s1 = Config.ApproachSpeed1 or 14.0
            local s2 = Config.ApproachSpeed2 or 8.0
            local s3 = Config.ApproachSpeed3 or 4.0

            if distToDest < d3 and approachTier ~= "crawl" then
                approachTier = "crawl"
                ClearPedTasks(rideDriver)
                TaskVehicleDriveToCoordLongrange(rideDriver, rideVehicle, stopOnStreet.x, stopOnStreet.y, stopOnStreet.z, s3, driveStyle, stopRadius)
            elseif distToDest < d2 and approachTier == "near" then
                -- already slowed to near; crawl handled above
            elseif distToDest < d2 and approachTier ~= "near" and approachTier ~= "crawl" then
                approachTier = "near"
                ClearPedTasks(rideDriver)
                TaskVehicleDriveToCoordLongrange(rideDriver, rideVehicle, stopOnStreet.x, stopOnStreet.y, stopOnStreet.z, s2, driveStyle, stopRadius)
            elseif distToDest < d1 and approachTier == "far" then
                approachTier = "mid"
                ClearPedTasks(rideDriver)
                TaskVehicleDriveToCoordLongrange(rideDriver, rideVehicle, stopOnStreet.x, stopOnStreet.y, stopOnStreet.z, s1, driveStyle, stopRadius)
            end

            -- Update app with progress
            local eta = math.ceil(distToDest / 15)
            local progress = math.floor((1 - (distToDest / currentRide.distance)) * 100)
            SendAppMessage({
                type = "tripProgress",
                eta = eta,
                distance = math.floor(distToDest),
                progress = math.min(progress, 100)
            })

            -- Check if player exited vehicle early
            local playerPed = PlayerPedId()
            if not IsPedInVehicle(playerPed, rideVehicle, false) then
                -- Player exited early - charge partial fare
                local traveled = currentRide.distance - distToDest
                local partialPrice = CalculatePrice(traveled, currentRide.vehicle.tier)

                TriggerServerEvent("laymo:chargePlayer", partialPrice)

                Notify("Ride ended early. Charged: $" .. partialPrice, "info")
                SendAppMessage({
                    type = "rideUpdate",
                    state = "completed",
                    price = partialPrice,
                    early = true
                })

                -- Cleanup after a delay
                Wait(5000)
                CleanupRide()
                return
            end

            -- Arrived at destination
            if distToDest < Config.StopDistance then
                -- Stop vehicle
                ClearPedTasks(rideDriver)
                TaskVehicleTempAction(rideDriver, rideVehicle, 1, 3000) -- Brake
                
                Wait(2000)
                
                -- Charge player
                TriggerServerEvent("laymo:chargePlayer", currentRide.price)
                
                rideState = "completed"
                Notify("You have arrived! Fare: $" .. currentRide.price, "success")
                SendAppMessage({ 
                    type = "rideUpdate", 
                    state = "completed",
                    price = currentRide.price
                })
                
                -- Let player exit
                Wait(3000)
                
                -- Cleanup after player exits
                local playerPed = PlayerPedId()
                local waitExit = 0
                while IsPedInVehicle(playerPed, rideVehicle, false) and waitExit < 30 do
                    Wait(1000)
                    waitExit = waitExit + 1
                end
                
                Wait(3000)
                CleanupRide()
                return
            end
        end
    end)
end

-- Server callback helper
function TriggerServerCallback(name, cb, ...)
    local requestId = math.random(1, 999999)
    
    RegisterNetEvent(name .. ":response:" .. requestId, function(...)
        cb(...)
    end)
    
    TriggerServerEvent(name, requestId, ...)
end

-- Send message to app UI
function SendAppMessage(data)
    exports["lb-phone"]:SendCustomAppMessage(Config.AppIdentifier, data)
end

-- Get current ride state for app
function GetRideState()
    return {
        state = rideState,
        ride = currentRide
    }
end

-- Exports
exports("RequestRide", RequestRide)
exports("CancelRide", CancelRide)
exports("GetRideState", GetRideState)
