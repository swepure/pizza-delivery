QBCore = exports['qb-core']:GetCoreObject()

-- Server-side event to give money
RegisterNetEvent('qb-pizzadelivery:giveMoney', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddMoney('cash', amount)
    end
end)
