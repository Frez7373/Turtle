-- =========================================================
--                 TURTLE SUPPLY SYSTEM
--                    CC:Tweaked
-- =========================================================
--
-- Automatic material restocking for building turtles.
--
-- HOW IT WORKS:
-- 1. The turtle remembers every successful movement/turn.
-- 2. When a material slot has 1 item left, the next placement
--    sends the turtle back to its exact starting position.
-- 3. A wired chest network is scanned for the required item.
-- 4. Matching items are pushed directly into the turtle slot.
-- 5. The turtle returns along the exact recorded route.
-- 6. Building continues automatically.
--
-- IMPORTANT:
-- A WIRED MODEM must connect the turtle and the storage chest.
-- Put a wired modem on the turtle and a wired modem on the chest,
-- then connect them with networking cable.
--
-- The chest does NOT use fixed slots. Items may be anywhere inside.
--
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
    if seconds and seconds > 0 then
        sleep(seconds)
    end
end

local function isInventoryPeripheral(name)
    local ok, methods = pcall(peripheral.getMethods, name)
    if not ok or not methods then
        return false
    end

    local hasList = false
    local hasPush = false

    for _, method in ipairs(methods) do
        if method == "list" then
            hasList = true
        elseif method == "pushItems" then
            hasPush = true
        end
    end

    return hasList and hasPush
end

local function findWiredModem()
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            local modem = peripheral.wrap(name)
            if modem then
                local ok, wireless = pcall(modem.isWireless)
                if ok and wireless == false then
                    return modem
                end
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
        error("SUPPLY: Wired modem not found. Connect turtle to storage network.", 0)
    end

    local ok, name = pcall(wiredModem.getNameLocal)
    if not ok or not name then
        error("SUPPLY: Could not determine turtle network name.", 0)
    end

    turtleName = name

    chest, chestName = findChest()

    if not chest then
        error("SUPPLY: No network inventory/chest found.", 0)
    end
end

local function getItemKey(detail)
    if not detail then
        return nil
    end

    -- Name is the primary identity. This is enough for normal blocks,
    -- glass, doors, stairs, lights, etc.
    return detail.name
end

local function findMatchingChestSlot(itemName)
    local list = chest.list()

    for slot, item in pairs(list) do
        if item.name == itemName then
            return slot
        end
    end

    return nil
end

local function getTargetCount(slot)
    return turtle.getItemCount(slot)
end

local function getTargetLimit(slot)
    local ok, limit = pcall(turtle.getItemLimit, slot)

    if ok and type(limit) == "number" and limit > 0 then
        return limit
    end

    return 64
end

local function restockSlot(slot)
    if restocking or replaying then
        return true
    end

    local detail = turtle.getItemDetail(slot)
    local itemName = getItemKey(detail)

    if not itemName then
        return true
    end

    local current = getTargetCount(slot)

    if current >= 2 then
        return true
    end

    restocking = true

    local savedEventCount = #events

    print("")
    print("[SUPPLY] Material low")
    print("[SUPPLY] Item: " .. itemName)
    print("[SUPPLY] Slot: " .. slot)
    print("[SUPPLY] Returning to home...")

    -- Reverse every movement and turn without recording those movements.
    replaying = true

    for i = #events, 1, -1 do
        local event = events[i]

        if event == "f" then
            while not original.back() do
                sleepSafe(0.1)
            end
        elseif event == "b" then
            while not original.forward() do
                sleepSafe(0.1)
            end
        elseif event == "u" then
            while not original.down() do
                sleepSafe(0.1)
            end
        elseif event == "d" then
            while not original.up() do
                sleepSafe(0.1)
            end
        elseif event == "r" then
            original.turnLeft()
        elseif event == "l" then
            original.turnRight()
        end
    end

    print("[SUPPLY] At home position")
    print("[SUPPLY] Storage: " .. tostring(chestName))

    local limit = getTargetLimit(slot)
    local wanted = math.max(0, limit - getTargetCount(slot))

    while wanted > 0 do
        local sourceSlot = findMatchingChestSlot(itemName)

        if not sourceSlot then
            print("[SUPPLY] Missing: " .. itemName)
            print("[SUPPLY] Add it to the storage chest.")
            print("[SUPPLY] Retrying in " .. RETRY_DELAY .. " seconds...")
            sleepSafe(RETRY_DELAY)
        else
            local moved = chest.pushItems(turtleName, sourceSlot, wanted, slot)

            if moved and moved > 0 then
                wanted = math.max(0, limit - getTargetCount(slot))
                print("[SUPPLY] Loaded " .. moved .. " item(s)")
            else
                print("[SUPPLY] Could not transfer " .. itemName)
                sleepSafe(RETRY_DELAY)
            end
        end
    end

    print("[SUPPLY] Slot " .. slot .. " refilled to " .. getTargetCount(slot))
    print("[SUPPLY] Returning to construction...")

    -- Replay the exact route and restore the exact orientation.
    for i = 1, savedEventCount do
        local event = events[i]

        if event == "f" then
            while not original.forward() do
                sleepSafe(0.1)
            end
        elseif event == "b" then
            while not original.back() do
                sleepSafe(0.1)
            end
        elseif event == "u" then
            while not original.up() do
                sleepSafe(0.1)
            end
        elseif event == "d" then
            while not original.down() do
                sleepSafe(0.1)
            end
        elseif event == "r" then
            original.turnRight()
        elseif event == "l" then
            original.turnLeft()
        end
    end

    replaying = false
    restocking = false

    print("[SUPPLY] Back at construction position")
    print("")

    return true
end

local function wrapMovement(name, inverseEvent)
    original[name] = turtle[name]

    turtle[name] = function(...)
        local args = {...}
        local result = original[name](table.unpack(args))

        if not replaying and not restocking then
            local success = result

            if success == nil and (name == "turnRight" or name == "turnLeft") then
                success = true
            end

            if success then
                events[#events + 1] = inverseEvent
            end
        end

        return result
    end
end

local function wrapPlace(name, originalName)
    original[originalName] = turtle[originalName]

    turtle[name] = function(...)
        local args = {...}
        local slot = turtle.getSelectedSlot()

        if not replaying and not restocking then
            restockSlot(slot)
        end

        return original[originalName](table.unpack(args))
    end
end

function supply.start()
    if started then
        return
    end

    started = true

    findNetwork()

    -- Save original movement API before replacing anything.
    original.forward = turtle.forward
    original.back = turtle.back
    original.up = turtle.up
    original.down = turtle.down
    original.turnRight = turtle.turnRight
    original.turnLeft = turtle.turnLeft

    -- Movement tracking.
    turtle.forward = function(...)
        local result = original.forward(...)
        if result and not replaying and not restocking then
            events[#events + 1] = "f"
        end
        return result
    end

    turtle.back = function(...)
        local result = original.back(...)
        if result and not replaying and not restocking then
            events[#events + 1] = "b"
        end
        return result
    end

    turtle.up = function(...)
        local result = original.up(...)
        if result and not replaying and not restocking then
            events[#events + 1] = "u"
        end
        return result
    end

    turtle.down = function(...)
        local result = original.down(...)
        if result and not replaying and not restocking then
            events[#events + 1] = "d"
        end
        return result
    end

    turtle.turnRight = function(...)
        local result = original.turnRight(...)
        if not replaying and not restocking then
            events[#events + 1] = "r"
        end
        return result
    end

    turtle.turnLeft = function(...)
        local result = original.turnLeft(...)
        if not replaying and not restocking then
            events[#events + 1] = "l"
        end
        return result
    end

    -- Placement tracking/restocking.
    original.place = turtle.place
    original.placeDown = turtle.placeDown
    original.placeUp = turtle.placeUp

    turtle.place = function(...)
        local slot = turtle.getSelectedSlot()
        if not replaying and not restocking then
            restockSlot(slot)
        end
        return original.place(...)
    end

    turtle.placeDown = function(...)
        local slot = turtle.getSelectedSlot()
        if not replaying and not restocking then
            restockSlot(slot)
        end
        return original.placeDown(...)
    end

    turtle.placeUp = function(...)
        local slot = turtle.getSelectedSlot()
        if not replaying and not restocking then
            restockSlot(slot)
        end
        return original.placeUp(...)
    end

    print("[SUPPLY] Online")
    print("[SUPPLY] Chest: " .. tostring(chestName))
    print("[SUPPLY] Turtle: " .. tostring(turtleName))
    print("[SUPPLY] Restock threshold: 1 item")
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
