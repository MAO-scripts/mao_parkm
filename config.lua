config = {}

config.ESX_version = "old" --  If you are using the newer versions of ESX, set the value as "new", otherwise set it as "old".

config.txt = {
    ["far"] = "Your distance from the parking meter is too far.",
    ["park"] = "The [~g~E~w~] button is used to park the car.",
    ["block"] = "The car spawn location is full.",
    ["get"] = "The [~g~E~w~] button is used to start driving the car.",
    ["full"] = "You have previously parked a car here.",
    ["not_enough_money"] = "You don't have enough money.($_money_).",
    ["aleardy_parked"] = "This car has been already parked.",
    ["takeout"] = "You are out of the parking meter.",
    ["park2"] = "To make a payment, press the [~g~E~w~] button.",
    ["paid"] = " PAID"
}

config.marker_options = {
    type = 1, -- You can see the types of markers on this website.: https://docs.fivem.net/docs/game-references/markers/
    color1 = {r = 0, g = 10, b = 100},-- When the car is not inside the parking meter, the color of the marker changes.
    color2 = {r = 0, g = 200, b = 0},-- The color of the marker changes when the car is inside the parking meter.
    size = {x = 2.0, y = 2.0, z = 1.0} -- marker size.
}

config.blip_options = { -- "You can see the types of Sprite and Blip color inside this website: https://docs.fivem.net/docs/game-references/blips/
    enable = true, -- Let you know if Blip is active or not.
    sprite = 267, -- Blip number
    scale = 0.75, -- Blip size
    colour = 38, -- The color of the Blip when the car is not parked inside the parking meter.
    colour2 = 25, -- The color of the Blip changes when the car is parked inside the parking meter.
    shortrange = true,
    name = "parking meter"
}

-- PARKINGMETER 2
config.objects = {
    `prop_parknmeter_01`,
    `prop_parknmeter_02`
}

config.parkingmeter2 = true -- Is the second parking meter active or not?

config.parkingmeterprice = 50 -- The fee amount for the parking meter

config.object_distance = 1.5 -- The distance from the parking meter

config.show_text = true -- Displaying floating text above the parking meter when a car is parked.

config.use_job = true -- Using the player's job to show floating text.

config.job_name = "police" -- The job name for displaying a floating message.

config.anti_delete = true -- If you set this to "true", parked cars will not be deleted.

config.d_car = false -- If set to true, parked cars will be deleted after parking, and the player can retrieve their car by returning to the parking meter.



-- Don't totch it --
for i=1, #config.objects do
    if type(config.objects[i]) == "string" then
        config.objects[i] = GetHashKey(config.objects[i])
    end
end