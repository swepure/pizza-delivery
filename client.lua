QBCore = exports['qb-core']:GetCoreObject()

local onJob = false
local currentDelivery = nil
local deliveryCount = 0
local deliveriesCompleted = 0
local deliveriesRequired = 0
local spawnedVehicle = nil
local deliveryBlip = nil
local pizzaBoxProp = nil
local pickedUpPizzas = false
local canDeliver = false

-- Create a blip for the job start location
CreateThread(function()
    local blip = AddBlipForCoord(Config.JobStartLocation)

    SetBlipSprite(blip, 267) -- Set the blip icon (267 is for a pizza slice)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5) -- Set the blip color
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza Delivery Job")
    EndTextCommandSetBlipName(blip)
end)

-- Start Job
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if #(playerCoords - Config.JobStartLocation) < 10.0 then
            DrawMarker(1, Config.JobStartLocation.x, Config.JobStartLocation.y, Config.JobStartLocation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 255, 0, 0, 100, false, false, 2, false, nil, nil, false)
            if #(playerCoords - Config.JobStartLocation) < 2.0 then
                if not onJob then
                    QBCore.Functions.DrawText3D(Config.JobStartLocation.x, Config.JobStartLocation.y, Config.JobStartLocation.z, "~g~[E]~w~ Start Pizza Delivery")
                else
                    QBCore.Functions.DrawText3D(Config.JobStartLocation.x, Config.JobStartLocation.y, Config.JobStartLocation.z, "~g~[E]~w~ End Pizza Delivery")
                end

                if IsControlJustReleased(0, 38) then -- E key
                    if not onJob then
                        StartPizzaDeliveryJob()
                    else
                        EndPizzaDeliveryJob(true)
                    end
                end
            end
        end
    end
end)

-- Start the delivery job
function StartPizzaDeliveryJob()
    onJob = true
    deliveryCount = 0
    deliveriesCompleted = 0
    deliveriesRequired = math.random(Config.MinDeliveries, Config.MaxDeliveries)
    pickedUpPizzas = false
    canDeliver = false
    QBCore.Functions.Notify("You have started a pizza delivery job! Head to the pickup point to collect the pizzas.", "success")

    -- Spawn the delivery vehicle
    local vehicleModel = GetHashKey(Config.VehicleModel)
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(100)
    end

    local playerPed = PlayerPedId()
    local vehicleCoords = Config.ParkingLotLocation
    local vehicleHeading = Config.VehicleSpawnHeading

    -- Create the vehicle
    spawnedVehicle = CreateVehicle(vehicleModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleHeading, true, false)

    -- Ensure the player is placed in the vehicle
    SetPedIntoVehicle(playerPed, spawnedVehicle, -1)

    -- Set the vehicle as owned by the player (so it doesn't despawn)
    SetVehicleNumberPlateText(spawnedVehicle, "PIZZA"..tostring(math.random(1000, 9999)))
    SetEntityAsMissionEntity(spawnedVehicle, true, true)

    -- Set full fuel tank using qb-legacyfuel
    exports['LegacyFuel']:SetFuel(spawnedVehicle, 100.0)

    -- Give the player keys to the vehicle
    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(spawnedVehicle))

    -- Ensure the vehicle doesn't lock when the player gets out
    SetVehicleDoorsLocked(spawnedVehicle, 1) -- Vehicle stays unlocked

    -- Create a blip for the pickup location with a delivery truck icon
    deliveryBlip = AddBlipForCoord(Config.PizzaPickupLocation.x, Config.PizzaPickupLocation.y, Config.PizzaPickupLocation.z)
    SetBlipSprite(deliveryBlip, 488) -- Delivery truck blip icon
    SetBlipColour(deliveryBlip, 5) -- Yellow color
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 5)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza Pickup Location")
    EndTextCommandSetBlipName(deliveryBlip)
end

-- Process pizza pickup
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if onJob and not pickedUpPizzas and #(playerCoords - Config.PizzaPickupLocation) < 10.0 then
            DrawMarker(1, Config.PizzaPickupLocation.x, Config.PizzaPickupLocation.y, Config.PizzaPickupLocation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 255, 255, 0, 100, false, false, 2, false, nil, nil, false)
            if #(playerCoords - Config.PizzaPickupLocation) < 2.0 then
                QBCore.Functions.DrawText3D(Config.PizzaPickupLocation.x, Config.PizzaPickupLocation.y, Config.PizzaPickupLocation.z, "~g~[E]~w~ Collect Pizzas")
                if IsControlJustReleased(0, 38) then -- E key
                    PickUpPizzas()
                end
            end
        end
    end
end)

-- Pick up pizzas
function PickUpPizzas()
    pickedUpPizzas = true
    QBCore.Functions.Notify("Pizzas collected! Now start your deliveries.", "success")

    -- Remove pickup blip
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end

    -- Proceed with setting the first delivery location
    SetDeliveryLocation()
end

-- Set a random delivery location
function SetDeliveryLocation()
    if deliveriesCompleted >= deliveriesRequired then
        DriveBackToReturnPoint()
        return
    end

    currentDelivery = Config.DeliveryLocations[math.random(1, #Config.DeliveryLocations)]

    -- Remove existing blip if any
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end

    -- Add a blip at the delivery location with a delivery truck icon
    deliveryBlip = AddBlipForCoord(currentDelivery.x, currentDelivery.y, currentDelivery.z)
    SetBlipSprite(deliveryBlip, 488) -- Delivery truck blip icon
    SetBlipColour(deliveryBlip, 5) -- Yellow color for delivery route
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 5)

    canDeliver = true
    QBCore.Functions.Notify("Deliver the pizza to the marked location. Deliveries: " .. deliveriesCompleted .. "/" .. deliveriesRequired, "success")
end

-- Delivery process
CreateThread(function()
    while true do
        Wait(0)
        if onJob and currentDelivery and canDeliver then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if #(playerCoords - currentDelivery) < 10.0 then
                DrawMarker(1, currentDelivery.x, currentDelivery.y, currentDelivery.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 0, 255, 0, 100, false, false, 2, false, nil, nil, false)
                if #(playerCoords - currentDelivery) < 2.0 then
                    QBCore.Functions.DrawText3D(currentDelivery.x, currentDelivery.y, currentDelivery.z, "~g~[E]~w~ Deliver Pizza")
                    if IsControlJustReleased(0, 38) then -- E key
                        if IsPedOnFoot(playerPed) then -- Ensure the player is on foot
                            HandPizzaToNPC()
                        else
                            QBCore.Functions.Notify("You must get out of the vehicle to deliver the pizza!", "error")
                        end
                    end
                end
            end
        end
    end
end)

-- Hand the pizza to the NPC
function HandPizzaToNPC()
    if not canDeliver then return end -- Prevent spamming deliveries

    canDeliver = false -- Disable further interaction for this delivery

    local pedModel = `a_m_y_hipster_01` -- Model of NPC to spawn (can be changed)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(100)
    end

    -- Adjust the NPC's position to ensure it spawns on the ground
    local _, groundZ = GetGroundZFor_3dCoord(currentDelivery.x, currentDelivery.y, currentDelivery.z, 0)

    local npc = CreatePed(4, pedModel, currentDelivery.x, currentDelivery.y, groundZ, 0.0, false, true)
    TaskStartScenarioInPlace(npc, "PROP_HUMAN_BUM_BIN", 0, true)

    -- Give the player a pizza box prop
    local playerPed = PlayerPedId()
    local pizzaBoxModel = `prop_pizza_box_02` -- Model of the pizza box
    RequestModel(pizzaBoxModel)
    while not HasModelLoaded(pizzaBoxModel) do
        Wait(100)
    end

    pizzaBoxProp = CreateObject(pizzaBoxModel, GetEntityCoords(playerPed), true, false, false)
    AttachEntityToEntity(pizzaBoxProp, playerPed, GetPedBoneIndex(playerPed, 57005), 0.18, 0.02, 0.02, -70.0, 290.0, 0.0, true, true, false, true, 1, true)

    -- Play the animation
    RequestAnimDict("mp_common")
    while not HasAnimDictLoaded("mp_common") do
        Wait(100)
    end

    TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, 3000, 49, 0, false, false, false)
    Wait(2000) -- Wait for the animation to play

    -- Delete the pizza box prop after giving it to the NPC
    DeleteObject(pizzaBoxProp)

    -- Simulate the NPC receiving the pizza
    Wait(1000)

    local distance = #(GetEntityCoords(playerPed) - Config.JobStartLocation)
    local payment = CalculatePayment(distance)

    TriggerServerEvent('qb-pizzadelivery:giveMoney', payment)
    QBCore.Functions.Notify("You received $" .. payment .. " for the delivery.", "success")

    DeleteEntity(npc)
    deliveriesCompleted = deliveriesCompleted + 1

    -- Remove delivery blip after delivery
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end

    -- Set the next delivery location or return point
    if deliveriesCompleted < deliveriesRequired then
        SetDeliveryLocation()
    else
        DriveBackToReturnPoint()
    end
end

-- Drive back to the return point
function DriveBackToReturnPoint()
    QBCore.Functions.Notify("All deliveries completed! Drive back to the return point.", "success")

    -- Add a blip for the return location with a delivery truck icon
    deliveryBlip = AddBlipForCoord(Config.ReturnVehicleLocation.x, Config.ReturnVehicleLocation.y, Config.ReturnVehicleLocation.z)
    SetBlipSprite(deliveryBlip, 488) -- Delivery truck blip icon
    SetBlipColour(deliveryBlip, 5) -- Yellow color for return route
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 5)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Return Vehicle")
    EndTextCommandSetBlipName(deliveryBlip)
end

-- Process vehicle return
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if onJob and deliveriesCompleted >= deliveriesRequired and #(playerCoords - Config.ReturnVehicleLocation) < 10.0 then
            DrawMarker(1, Config.ReturnVehicleLocation.x, Config.ReturnVehicleLocation.y, Config.ReturnVehicleLocation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 255, 255, 0, 100, false, false, 2, false, nil, nil, false)
            if #(playerCoords - Config.ReturnVehicleLocation) < 2.0 then
                QBCore.Functions.DrawText3D(Config.ReturnVehicleLocation.x, Config.ReturnVehicleLocation.y, Config.ReturnVehicleLocation.z, "~g~[E]~w~ Return Vehicle")
                if IsControlJustReleased(0, 38) then -- E key
                    EndPizzaDeliveryJob(false)
                end
            end
        end
    end
end)

-- Calculate payment based on distance and chance for a tip
function CalculatePayment(distance)
    local basePay = math.floor(distance * Config.BasePayMultiplier) -- Payment based on distance
    local tip = 0

    if math.random(1, 100) <= Config.TipChance then
        tip = math.random(Config.TipAmount.min, Config.TipAmount.max) -- Random tip within the configured range
        QBCore.Functions.Notify("You received a tip of $" .. tip .. "!", "success")
    end

    return basePay + tip
end

-- End the job
function EndPizzaDeliveryJob(earlyReturn)
    local totalPay = 0

    if earlyReturn then
        local remainingDeliveries = deliveriesRequired - deliveriesCompleted
        local penaltyFactor = Config.EarlyReturnPenalty
        totalPay = math.floor(remainingDeliveries * Config.BasePayMultiplier * penaltyFactor)
        QBCore.Functions.Notify("You have ended the job early. You received $" .. totalPay .. " for the remaining deliveries.", "error")
    else
        QBCore.Functions.Notify("You have completed all deliveries and returned the vehicle!", "success")
    end

    -- Pay the player for any remaining deliveries if ended early
    if totalPay > 0 then
        TriggerServerEvent('qb-pizzadelivery:giveMoney', totalPay)
    end

    -- Remove keys from the player
    TriggerEvent("vehiclekeys:client:RemoveKeys", QBCore.Functions.GetPlate(spawnedVehicle))

    -- Reset job variables
    onJob = false
    deliveryCount = 0
    deliveriesCompleted = 0
    deliveriesRequired = 0
    currentDelivery = nil
    pickedUpPizzas = false
    canDeliver = false

    -- Remove delivery blip if still active
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end

    -- Delete vehicle
    if DoesEntityExist(spawnedVehicle) then
        DeleteVehicle(spawnedVehicle)
    end

    -- Set cooldown before starting another job
    Wait(Config.JobCooldown)
end