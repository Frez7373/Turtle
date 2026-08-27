local supply = require("supply")
supply.start()

-- =========================================================
--        AMERICAN SUBURBAN HOUSE BUILDER
--                 CC:Tweaked Turtle
-- =========================================================
-- HOUSE SIZE: 11 x 11
-- WALL HEIGHT: 5
--
-- INVENTORY:
-- 1 = WALL BLOCK
-- 2 = GLASS
-- 3 = DOOR
-- 4 = ROOF BLOCK
-- 5 = FOUNDATION
-- 6 = FLOOR
-- 7 = STAIRS
-- 8 = LIGHT
-- 9 = INTERIOR WALL
-- =========================================================

local SLOT_WALL = 1
local SLOT_GLASS = 2
local SLOT_DOOR = 3
local SLOT_ROOF = 4
local SLOT_FOUNDATION = 5
local SLOT_FLOOR = 6
local SLOT_STAIRS = 7
local SLOT_LIGHT = 8
local SLOT_INTERIOR = 9

local HOUSE_W = 11
local HOUSE_D = 11
local WALL_H = 5

local function select(slot) turtle.select(slot) end

local function waitForItem(slot)
    if turtle.getItemCount(slot) == 0 then
        print("")
        print("OUT OF MATERIAL")
        print("Slot: " .. slot)
        print("Insert one starter item and press ENTER")
        read()
    end
    select(slot)
end

local function forward()
    while not turtle.forward() do
        if turtle.detect() then turtle.dig() else sleep(0.2) end
    end
end

local function up()
    while not turtle.up() do
        if turtle.detectUp() then turtle.digUp() else sleep(0.2) end
    end
end

local function down()
    while not turtle.down() do
        if turtle.detectDown() then turtle.digDown() else sleep(0.2) end
    end
end

local function right() turtle.turnRight() end
local function left() turtle.turnLeft() end

local function place(slot)
    waitForItem(slot)
    if not turtle.place() then turtle.dig(); turtle.place() end
end

local function placeDown(slot)
    waitForItem(slot)
    if not turtle.placeDown() then turtle.digDown(); turtle.placeDown() end
end

local function placeUp(slot)
    waitForItem(slot)
    if not turtle.placeUp() then turtle.digUp(); turtle.placeUp() end
end

local function lineForward(length)
    for _ = 1, length do forward() end
end

local function refuel()
    if turtle.getFuelLevel() == "unlimited" then return end
    if turtle.getFuelLevel() < 100 then
        print("Refueling...")
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then turtle.refuel() end
        end
    end
    if turtle.getFuelLevel() < 100 then
        print("WARNING: LOW FUEL")
        print("Put fuel in the turtle.")
        print("Press ENTER")
        read()
    end
end

local function buildFloor()
    print("Building foundation...")
    forward()
    for z = 1, HOUSE_D do
        for x = 1, HOUSE_W do
            placeDown(SLOT_FOUNDATION)
            if x < HOUSE_W then forward() end
        end
        if z < HOUSE_D then
            if z % 2 == 1 then right(); forward(); right() else left(); forward(); left() end
        end
    end
    if HOUSE_D % 2 == 1 then left(); lineForward(HOUSE_D - 1); left() else right(); lineForward(HOUSE_D - 1); right() end
    lineForward(HOUSE_W - 1)
    right()

    print("Building floor...")
    for z = 1, HOUSE_D do
        for x = 1, HOUSE_W do
            placeDown(SLOT_FLOOR)
            if x < HOUSE_W then forward() end
        end
        if z < HOUSE_D then
            if z % 2 == 1 then right(); forward(); right() else left(); forward(); left() end
        end
    end
    if HOUSE_D % 2 == 1 then left(); lineForward(HOUSE_D - 1); left() else right(); lineForward(HOUSE_D - 1); right() end
    lineForward(HOUSE_W - 1)
    left()
end

local function buildFrontWall(height)
    for x = 1, HOUSE_W do
        local doorArea = (x == 5 or x == 6 or x == 7) and height <= 2
        local windowArea = ((x == 2 or x == 3 or x == 9 or x == 10) and height >= 2 and height <= 3)
        if not doorArea then
            if windowArea then place(SLOT_GLASS) else place(SLOT_WALL) end
        end
        if x < HOUSE_W then forward() end
    end
end

local function buildBackWall(height)
    for x = 1, HOUSE_W do
        local windowArea = ((x == 3 or x == 4 or x == 8 or x == 9) and height >= 2 and height <= 3)
        if windowArea then place(SLOT_GLASS) else place(SLOT_WALL) end
        if x < HOUSE_W then forward() end
    end
end

local function buildLeftWall(height)
    for z = 1, HOUSE_D do
        local windowArea = ((z == 3 or z == 4 or z == 8 or z == 9) and height >= 2 and height <= 3)
        if windowArea then place(SLOT_GLASS) else place(SLOT_WALL) end
        if z < HOUSE_D then forward() end
    end
end

local function buildRightWall(height)
    for z = 1, HOUSE_D do
        local windowArea = ((z == 3 or z == 4 or z == 8 or z == 9) and height >= 2 and height <= 3)
        if windowArea then place(SLOT_GLASS) else place(SLOT_WALL) end
        if z < HOUSE_D then forward() end
    end
end

local function buildWalls()
    print("Building walls...")
    for height = 1, WALL_H do
        buildFrontWall(height); right(); buildRightWall(height); right(); buildBackWall(height); right(); buildLeftWall(height); right()
        if height < WALL_H then up() end
    end
end

local function installFrontDoor()
    print("Installing front door...")
    lineForward(5)
    place(SLOT_DOOR)
    up(); place(SLOT_DOOR); down()
    lineForward(5)
    left()
end

local function buildInteriorWalls()
    print("Building interior rooms...")
    forward()
    for i = 1, 4 do place(SLOT_INTERIOR); if i < 4 then forward() end end
    up()
    for i = 1, 4 do place(SLOT_INTERIOR); if i < 4 then forward() end end
    down(); left(); lineForward(4); right(); lineForward(1); right()
    for i = 1, 7 do if i ~= 4 then place(SLOT_INTERIOR) end; if i < 7 then forward() end end
    up()
    for i = 1, 7 do if i ~= 4 then place(SLOT_INTERIOR) end; if i < 7 then forward() end end
    down()
end

local function addLights()
    print("Installing lights...")
    forward(); forward(); forward(); placeUp(SLOT_LIGHT)
    right(); forward(); forward(); placeUp(SLOT_LIGHT)
    left(); left(); forward(); forward(); placeUp(SLOT_LIGHT)
    right(); forward(); forward(); placeUp(SLOT_LIGHT)
    left(); left()
end

local function buildPorch()
    print("Building front porch...")
    for i = 1, 3 do
        right()
        for x = 1, 7 do placeDown(SLOT_FLOOR); if x < 7 then forward() end end
        left(); if i < 3 then forward() end
    end
    place(SLOT_WALL); up(); place(SLOT_WALL); up(); place(SLOT_WALL); down(); down(); lineForward(6)
    place(SLOT_WALL); up(); place(SLOT_WALL); up(); place(SLOT_WALL); down(); down()
end

local function buildStairs()
    print("Building front steps...")
    right(); for _ = 1, 3 do placeDown(SLOT_STAIRS); forward() end; left()
end

local function buildRoof()
    print("Building roof...")
    up()
    for z = 1, HOUSE_D + 2 do
        for x = 1, HOUSE_W + 2 do placeDown(SLOT_ROOF); if x < HOUSE_W + 2 then forward() end end
        if z < HOUSE_D + 2 then if z % 2 == 1 then right(); forward(); right() else left(); forward(); left() end end
    end
    if (HOUSE_D + 2) % 2 == 1 then left(); lineForward(HOUSE_D + 1); left() else right(); lineForward(HOUSE_D + 1); right() end
    lineForward(HOUSE_W + 1)
    up()
    for z = 1, HOUSE_D do
        for x = 1, HOUSE_W do placeDown(SLOT_ROOF); if x < HOUSE_W then forward() end end
        if z < HOUSE_D then if z % 2 == 1 then right(); forward(); right() else left(); forward(); left() end end
    end
end

local function buildChimney()
    print("Building chimney...")
    up(); place(SLOT_WALL); up(); place(SLOT_WALL); up(); place(SLOT_WALL); down(); down(); down()
end

term.clear(); term.setCursorPos(1,1)
print("================================")
print("  AMERICAN HOUSE BUILDER")
print("================================")
print("")
print("Size: 11 x 11")
print("Height: 5")
print("Supply system: ONLINE")
print("Starting in 5 seconds...")
refuel(); sleep(5)
buildFloor(); buildWalls(); installFrontDoor(); buildInteriorWalls(); addLights(); buildPorch(); buildStairs(); buildRoof(); buildChimney()
print(""); print("HOUSE CONSTRUCTION COMPLETE")
