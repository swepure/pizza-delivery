Config = {}

Config = {}

Config.JobStartLocation = vector3(-553.03, 306.43, 83.28) -- Location to start the job
Config.ParkingLotLocation = vector3(-548.96, 307.23, 83.13) -- Location where the Panto will spawn
Config.VehicleSpawnHeading = 90.0 -- Set a heading for the vehicle
Config.PizzaPickupLocation = vector3(88.34, 284.07, 110.23) -- Location to pick up pizzas before starting deliveries
Config.ReturnVehicleLocation = vector3(-561.2, 302.04, 83.17) -- Location to return the vehicle after all deliveries


Config.DeliveryLocations = {
    vector3(-1442.51, -545.79, 34.74),
    vector3(-185.01, 421.9, 110.5),
    vector3(-88.06, 424.74, 113.2),
    vector3(-333.09, 102.7, 67.62),
    vector3(-596.18, 276.58, 82.18),
    vector3(-686.35, 224.5, 81.96),
    vector3(-819.94, 177.22, 71.66),
    vector3(-834.22, 114.39, 55.31),
    vector3(-832.14, 114.87, 55.4),
    vector3(-879.88, 17.21, 44.5),
    vector3(-929.48, 18.16, 47.85),
    vector3(-449.6, -132.93, 39.08),
    vector3(-599.81, -250.78, 36.3),
    vector3(921.95, -478.24, 61.08),
    vector3(968.77, -502.43, 62.14),
    vector3(1020.98, -414.13, 65.94),
    vector3(1060.48, -378.19, 68.23),
    vector3(1158.72, -328.87, 69.05),
    vector3(1242.03, -566.1, 69.66),
    vector3(1241.03, -602.04, 69.59),
}

Config.VehicleModel = 'panto' -- Model of the delivery vehicle (Panto car)

-- Payment configuration
Config.BasePayMultiplier = 0.2 -- Multiplier for the base pay calculation based on distance
Config.TipChance = 30 -- Percentage chance to receive a tip
Config.TipAmount = {min = 10, max = 50} -- Tip amount range if a tip is given
Config.EarlyReturnPenalty = 0.5 -- Percentage of remaining pay when returning the vehicle early (50% penalty)

Config.JobCooldown = 60000 -- 60 seconds cooldown before starting another job

-- Delivery Count Configuration
Config.MinDeliveries = 5 -- Minimum number of deliveries for a job
Config.MaxDeliveries = 20 -- Maximum number of deliveries for a job
