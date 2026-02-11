-- Enhanced autopilot functions for AutoRide
-- Based on Bucko_autopilot with improvements for NPC driving

local isAutopilotActive = false

-- Driving style flags reference:
-- 786468 = Rushed (ignores lights)  
-- 786603 = Normal (follows traffic)
-- 1074528293 = Aggressive
-- 2883621 = Avoid highways

-- Enhanced drive to coordinate function
function DriveToCoordinate(ped, vehicle, destination, speed, drivingStyle)
    if not DoesEntityExist(ped) or not DoesEntityExist(vehicle) then
        return false
    end
    
    isAutopilotActive = true
    
    -- Use the enhanced driving task
    TaskVehicleDriveToCoordLongrange(
        ped, 
        vehicle, 
        destination.x, 
        destination.y, 
        destination.z, 
        speed or Config.MaxSpeed, 
        drivingStyle or Config.DrivingStyle, 
        10.0 -- Target radius
    )
    
    return true
end

-- Stop autopilot
function StopAutopilot(ped, vehicle)
    if not DoesEntityExist(ped) then return end
    
    ClearPedTasks(ped)
    
    if DoesEntityExist(vehicle) then
        SetVehicleHandbrake(vehicle, true)
        TaskVehicleTempAction(ped, vehicle, 1, 2000) -- Brake
        Wait(500)
        SetVehicleHandbrake(vehicle, false)
    end
    
    isAutopilotActive = false
end

-- Check if vehicle is stuck and needs rerouting
function CheckIfStuck(vehicle, lastPos, threshold)
    if not DoesEntityExist(vehicle) then return false end
    
    local currentPos = GetEntityCoords(vehicle)
    local distance = #(currentPos - lastPos)
    
    return distance < (threshold or 1.0)
end

-- Reroute if stuck
function AttemptReroute(ped, vehicle, destination)
    if not DoesEntityExist(ped) or not DoesEntityExist(vehicle) then return end
    
    -- Clear current tasks
    ClearPedTasks(ped)
    
    -- Small reverse
    TaskVehicleTempAction(ped, vehicle, 28, 2000) -- Reverse
    Wait(2000)
    
    -- Try a different approach
    local vehCoords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    
    -- Find alternative route point
    local altX = vehCoords.x + math.cos(math.rad(heading + 45)) * 20
    local altY = vehCoords.y + math.sin(math.rad(heading + 45)) * 20
    
    -- Drive to alternative point first
    TaskVehicleDriveToCoord(ped, vehicle, altX, altY, vehCoords.z, Config.MaxSpeed * 0.7, 1.0, GetEntityModel(vehicle), Config.DrivingStyle, 5.0, true)
    Wait(3000)
    
    -- Resume to destination
    TaskVehicleDriveToCoordLongrange(ped, vehicle, destination.x, destination.y, destination.z, Config.MaxSpeed, Config.DrivingStyle, 10.0)
end

-- Monitor autopilot with stuck detection
function MonitorAutopilot(ped, vehicle, destination, onArrival, arrivalDistance)
    local stuckCount = 0
    local lastPos = GetEntityCoords(vehicle)
    local checkInterval = 3000
    local destVec = vector3(destination.x, destination.y, destination.z)
    
    CreateThread(function()
        while isAutopilotActive and DoesEntityExist(vehicle) and DoesEntityExist(ped) do
            Wait(checkInterval)
            
            local currentPos = GetEntityCoords(vehicle)
            local distToDest = #(currentPos - destVec)
            
            -- Check if arrived
            if distToDest < (arrivalDistance or Config.StopDistance) then
                isAutopilotActive = false
                StopAutopilot(ped, vehicle)
                if onArrival then
                    onArrival()
                end
                return
            end
            
            -- Check if stuck
            if CheckIfStuck(vehicle, lastPos, 2.0) then
                stuckCount = stuckCount + 1
                if stuckCount >= 3 then
                    if Config.Debug then
                        print("[Laymo] Vehicle stuck, attempting reroute")
                    end
                    AttemptReroute(ped, vehicle, destination)
                    stuckCount = 0
                end
            else
                stuckCount = 0
            end
            
            lastPos = currentPos
        end
    end)
end

-- Get nearest road node
function GetNearestRoadNode(coords)
    local found, outPos = GetClosestVehicleNode(coords.x, coords.y, coords.z, 1, 3.0, 0)
    if found then
        return outPos
    end
    return coords
end

-- Get road heading at position
function GetRoadHeadingAt(coords)
    local found, outPos, outHeading = GetClosestVehicleNodeWithHeading(coords.x, coords.y, coords.z, 1, 3.0, 0)
    if found then
        return outHeading
    end
    return 0.0
end

-- Exports
exports("DriveToCoordinate", DriveToCoordinate)
exports("StopAutopilot", StopAutopilot)
exports("MonitorAutopilot", MonitorAutopilot)
exports("GetNearestRoadNode", GetNearestRoadNode)
exports("GetRoadHeadingAt", GetRoadHeadingAt)
