-- =========================================================
--                 TURTLE SUPPLY SYSTEM
--                    CC:Tweaked
-- =========================================================
-- Automatic material restocking for building turtles.
--
-- The chest does NOT use fixed slots. The system searches the
-- whole connected inventory for the exact item name + NBT hash.
--
-- The turtle keeps one item of each material. When a placement
-- would use that last item, the turtle returns to its exact start
-- position, refills the selected slot, and follows the recorded
-- route back to the construction position.
--
-- A wired modem must connect the turtle and storage chest.
-- =========================================================

local supply = {}

local started = false
local replaying = false
local restocking = false
local events = {}

local original = {}
local chest = nil
local chestName = nil
local turtleName = nil
local wiredModem = nil

local THRESHOLD = 1
local RETRY_DELAY = 2

local function sleepSafe(seconds)
    if seconds and seconds > 0 then sleep(seconds) end
end

local function isInventoryPeripheral(name)
    local ok, methods = pcall(peripheral.getMethods, name)
    if not ok or not methods then return false end

    local hasList = false
    local hasPush = false

    for _, method in ipairs(methods) do
        if method == "list" then hasList = true end
        if method == "pushItems" then hasPush = true end
    end

    return hasList and hasPush
end

local function findWiredModem()
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            local modem = peripheral.wrap(name)
            if modem then
                local ok, wireless = pcall(modem.isWireless)
                if ok and wireless == false then return modem end
            end
        end
    end
    return nil
end

local function findChest()
    for _, name in ipairs(peripheral.getNames()) do
        if name ~= peripheral.getName(wiredModem) and isInventoryPeripheral(name) then
            return peripheral.wrap(name), name
        end
    end
    return nil, nil
end

local function findNetwork()
    wiredModem = findWiredModem()
    if not wiredModem then
        error("SUPPLY: Wired modem not found. Connect turtle and chest with networking cable.", 0)
    end

    local ok, name = pcall(wiredModem.getNameLocal)
    if not ok or not name then
        error("SUPPLY: Could not determine turtle network name.", 0)
    end

    turtleName = name
    chest, chestName = findChest()

    if not chest then
        error("SUPPLY: No connected chest/inventory found.", 0)
    end
end

local function sameItem(a, b)
    if not a or not b then return false end
    return a.name == b.name and a.nbt == b.nbt
end

local function findMatchingChestSlot(wanted)
    local list = chest.list()

    for slot, item in pairs(list) do
        if item.name == wanted.name and item.nbt == wanted.nbt then
            return slot
        end
    end

    return nil
end

local function requiredAmount(slot)
    local current = turtle.getItemCount(slot)
    local space = turtle.getItemSpace(slot)
    return current + space, current
end

local function restockSlot(slot)
    if restocking or replaying then return true end

    local wanted = turtle.getItemDetail(slot)
    if not wanted then return true end

    local current = turtle.getItemCount(slot)
    if current > THRESHOLD then return true end

    restocking = true
    local savedEventCount = #events

    print("")
    print("[SUPPLY] LOW MATERIAL")
    print("[SUPPLY] " .. wanted.name)
    print("[SUPPLY] Turtle slot: " .. slot)
    print("[SUPPLY] Returning to start position...")

    replaying = true

    for i = #events, 1, -1 do
        local event = events[i]

        if event == "f" then
            while not original.back() do sleepSafe(0.1) end
        elseif event == "b" then
            while not original.forward() do sleepSafe(0.1) end
        elseif event == "u" then
            while not original.down() do sleepSafe(0.1) end
        elseif event == "d" then
            while not original.up() do sleepSafe(0.1) end
        elseif event == "r" then
            original.turnLeft()
        elseif event == "l" then
            original.turnRight()
        end
    end

    print("[SUPPLY] At start position")
    print("[SUPPLY] Chest: " .. tostring(chestName))

    local maxStack, currentNow = requiredAmount(slot)
    local wantedCount = math.max(0, maxStack - currentNow)

    while turtle.getItemCount(slot) < maxStack do
        local sourceSlot = findMatchingChestSlot(wanted)

        if not sourceSlot then
            print("[SUPPLY] Missing: " .. wanted.name)
            print("[SUPPLY] Put more of this item into the chest.")
            sleepSafe(RETRY_DELAY)
        else
            local need = maxStack - turtle.getItemCount(slot)
            local ok, moved = pcall(chest.pushItems, turtleName, sourceSlot, need, slot)

            if ok and moved and moved > 0 then
                print("[SUPPLY] Loaded " .. moved .. " item(s)")
            else
                print("[SUPPLY] Transfer failed, retrying...")
                sleepSafe(0.5)
            end
        end
    end

    print("[SUPPLY] Slot refilled: " .. turtle.getItemCount(slot))
    print("[SUPPLY] Returning to construction position...")

    for i = 1, savedEventCount do
        local event = events[i]

        if event == "f" then
            while not original.forward() do sleepSafe(0.1) end
        elseif event == "b" then
            while not original.back() do sleepSafe(0.1) end
        elseif event == "u" then
            while not original.up() do sleepSafe(0.1) end
        elseif event == "d" then
            while not original.down() do sleepSafe(0.1) end
        elseif event == "r" then
            original.turnRight()
        elseif event == "l" then
            original.turnLeft()
        end
    end

    replaying = false
    restocking = false

    print("[SUPPLY] Construction position restored")
    print("")
    return true
end

function supply.start()
    if started then return end
    started = true

    findNetwork()

    original.forward = turtle.forward
    original.back = turtle.back
    original.up = turtle.up
    original.down = turtle.down
    original.turnRight = turtle.turnRight
    original.turnLeft = turtle.turnLeft
    original.place = turtle.place
    original.placeDown = turtle.placeDown
    original.placeUp = turtle.placeUp

    turtle.forward = function(...)
        local result = original.forward(...)
        if result and not replaying and not restocking then events[#events + 1] = "f" end
        return result
    end

    turtle.back = function(...)
        local result = original.back(...)
        if result and not replaying and not restocking then events[#events + 1] = "b" end
        return result
    end

    turtle.up = function(...)
        local result = original.up(...)
        if result and not replaying and not restocking then events[#events + 1] = "u" end
        return result
    end

    turtle.down = function(...)
        local result = original.down(...)
        if result and not replaying and not restocking then events[#events + 1] = "d" end
        return result
    end

    turtle.turnRight = function(...)
        local result = original.turnRight(...)
        if not replaying and not restocking then events[#events + 1] = "r" end
        return result
    end

    turtle.turnLeft = function(...)
        local result = original.turnLeft(...)
        if not replaying and not restocking then events[#events + 1] = "l" end
        return result
    end

    turtle.place = function(...)
        local slot = turtle.getSelectedSlot()
        if not replaying and not restocking then restockSlot(slot) end
        return original.place(...)
    end

    turtle.placeDown = function(...)
        local slot = turtle.getSelectedSlot()
        if not replaying and not restocking then restockSlot(slot) end
        return original.placeDown(...)
    end

    turtle.placeUp = function(...)
        local slot = turtle.getSelectedSlot()
        if not replaying and not restocking then restockSlot(slot) end
        return original.placeUp(...)
    end

    print("[SUPPLY] ONLINE")
    print("[SUPPLY] Chest: " .. tostring(chestName))
    print("[SUPPLY] Turtle: " .. tostring(turtleName))
    print("[SUPPLY] Threshold: 1 item")
end

function supply.status()
    return {
        chest = chestName,
        turtle = turtleName,
        events = #events,
        threshold = THRESHOLD
    }
end

return supply
