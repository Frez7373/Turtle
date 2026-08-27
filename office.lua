-- =========================================================
--              AMERICAN OFFICE BUILDER
--                    CC:Tweaked Turtle
-- =========================================================
--
-- Builds a compact 2-floor American-style office.
--
-- Inventory:
-- 1 = outer wall blocks
-- 2 = glass
-- 3 = doors
-- 4 = roof blocks
-- 5 = foundation blocks
-- 6 = floor blocks
-- 7 = stairs/slabs for entrance
-- 8 = lighting blocks
-- 9 = interior wall blocks
-- 10 = trim blocks
--
-- Start position:
-- Turtle is outside the FRONT-LEFT corner of the office,
-- facing along the front wall.
--
-- Size: 15 x 11
-- Floors: 2
-- =========================================================

local WALL       = 1
local GLASS      = 2
local DOOR       = 3
local ROOF       = 4
local FOUNDATION = 5
local FLOOR      = 6
local STAIRS     = 7
local LIGHT      = 8
local INTERIOR   = 9
local TRIM       = 10

local W = 15
local D = 11
local H = 5
local FLOORS = 2

local function need(slot)
    turtle.select(slot)
    while turtle.getItemCount(slot) == 0 do
        print("OUT OF MATERIAL - SLOT " .. slot)
        print("Insert items and press ENTER")
        read()
        turtle.select(slot)
    end
end

local function place(slot)
    need(slot)
    if not turtle.place() then
        turtle.dig()
        turtle.place()
    end
end

local function placeDown(slot)
    need(slot)
    if not turtle.placeDown() then
        turtle.digDown()
        turtle.placeDown()
    end
end

local function placeUp(slot)
    need(slot)
    if not turtle.placeUp() then
        turtle.digUp()
        turtle.placeUp()
    end
end

local function forward()
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
        else
            sleep(0.15)
        end
    end
end

local function up()
    while not turtle.up() do
        if turtle.detectUp() then
            turtle.digUp()
        else
            sleep(0.15)
        end
    end
end

local function down()
    while not turtle.down() do
        if turtle.detectDown() then
            turtle.digDown()
        else
            sleep(0.15)
        end
    end
end

local function right()
    turtle.turnRight()
end

local function left()
    turtle.turnLeft()
end

local function move(n)
    for _ = 1, n do forward() end
end

local function fuel()
    if turtle.getFuelLevel() == "unlimited" then return end

    if turtle.getFuelLevel() < 100 then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then
                turtle.refuel()
            end
        end
    end

    while turtle.getFuelLevel() < 100 do
        print("LOW FUEL")
        print("Put coal or another fuel in the turtle.")
        print("Press ENTER")
        read()
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then
                turtle.refuel()
            end
        end
    end
end

------------------------------------------------------------
-- FOUNDATION / FLOOR
------------------------------------------------------------

local function foundation()
    print("[1/8] Foundation")

    forward()

    for z = 1, D do
        for x = 1, W do
            placeDown(FOUNDATION)
            if x < W then forward() end
        end

        if z < D then
            if z % 2 == 1 then
                right()
                forward()
                right()
            else
                left()
                forward()
                left()
            end
        end
    end

    -- Return to front-left.
    if D % 2 == 1 then
        left()
        move(D - 1)
        left()
    else
        right()
        move(D - 1)
        right()
    end

    move(W - 1)
    right()

    print("Building ground floor...")

    for z = 1, D do
        for x = 1, W do
            placeDown(FLOOR)
            if x < W then forward() end
        end

        if z < D then
            if z % 2 == 1 then
                right()
                forward()
                right()
            else
                left()
                forward()
                left()
            end
        end
    end

    if D % 2 == 1 then
        left()
        move(D - 1)
        left()
    else
        right()
        move(D - 1)
        right()
    end

    move(W - 1)
    left()
end

------------------------------------------------------------
-- OUTER WALLS
------------------------------------------------------------

local function frontWall(level)
    for x = 1, W do
        local door = (x == 7 or x == 8 or x == 9) and level <= 2
        local window = ((x == 2 or x == 3 or x == 12 or x == 13) and level >= 2 and level <= 4)

        if door then
            -- Leave entrance open.
        elseif window then
            place(GLASS)
        else
            place(WALL)
        end

        if x < W then forward() end
    end
end

local function backWall(level)
    for x = 1, W do
        local window = ((x == 4 or x == 5 or x == 11 or x == 12) and level >= 2 and level <= 4)

        if window then
            place(GLASS)
        else
            place(WALL)
        end

        if x < W then forward() end
    end
end

local function sideWall(level)
    for z = 1, D do
        local window = ((z == 3 or z == 4 or z == 8 or z == 9) and level >= 2 and level <= 4)

        if window then
            place(GLASS)
        else
            place(WALL)
        end

        if z < D then forward() end
    end
end

local function walls()
    print("[2/8] Exterior walls")

    for level = 1, H do
        frontWall(level)
        right()
        sideWall(level)
        right()
        backWall(level)
        right()
        sideWall(level)
        right()

        if level < H then
            up()
        end
    end
end

------------------------------------------------------------
-- INTERIOR ROOMS
------------------------------------------------------------

local function interiorWalls()
    print("[3/8] Interior offices")

    -- Return to ground-level front-left interior area.
    down()
    down()
    down()
    down()

    -- Move inside.
    forward()
    forward()
    forward()

    -- Left row of offices.
    for i = 1, 6 do
        place(INTERIOR)
        if i < 6 then forward() end
    end

    -- Return and make second divider.
    left()
    move(6)
    left()
    move(3)
    right()

    for i = 1, 4 do
        place(INTERIOR)
        if i < 4 then forward() end
    end

    -- Hallway opening is intentionally left between offices.
end

------------------------------------------------------------
-- DOORS
------------------------------------------------------------

local function doors()
    print("[4/8] Doors")

    -- Main entrance.
    -- Reposition near center of front wall.
    move(5)
    place(DOOR)
    up()
    place(DOOR)
    down()
end

------------------------------------------------------------
-- STAIRS / ENTRANCE
------------------------------------------------------------

local function entrance()
    print("[5/8] Entrance and stairs")

    -- Small three-step entrance platform.
    down()

    for i = 1, 3 do
        placeDown(STAIRS)
        forward()
    end

    left()
end

------------------------------------------------------------
-- LIGHTING
------------------------------------------------------------

local function lighting()
    print("[6/8] Interior lighting")

    -- Move through several office positions.
    forward()
    forward()
    placeUp(LIGHT)

    right()
    forward()
    forward()
    placeUp(LIGHT)

    left()
    left()
    forward()
    forward()
    placeUp(LIGHT)

    right()
    forward()
    forward()
    placeUp(LIGHT)

    left()
    left()
end

------------------------------------------------------------
-- SECOND FLOOR
------------------------------------------------------------

local function secondFloor()
    print("[7/8] Second floor")

    -- Return to an area where we can climb.
    up()
    up()
    up()
    up()
    up()

    -- Floor ceiling / second floor slab.
    for z = 1, D do
        for x = 1, W do
            placeDown(FLOOR)
            if x < W then forward() end
        end

        if z < D then
            if z % 2 == 1 then
                right()
                forward()
                right()
            else
                left()
                forward()
                left()
            end
        end
    end

    -- Return.
    if D % 2 == 1 then
        left()
        move(D - 1)
        left()
    else
        right()
        move(D - 1)
        right()
    end

    move(W - 1)
    left()

    -- Second floor partitions.
    forward()
    forward()

    for i = 1, 5 do
        place(INTERIOR)
        if i < 5 then forward() end
    end

    right()

    for i = 1, 8 do
        if i ~= 5 then
            place(INTERIOR)
        end

        if i < 8 then forward() end
    end
end

------------------------------------------------------------
-- ROOF
------------------------------------------------------------

local function roof()
    print("[8/8] Roof and trim")

    -- Return near front-left of roof level.
    up()

    for z = 1, D + 2 do
        for x = 1, W + 2 do
            placeDown(ROOF)
            if x < W + 2 then forward() end
        end

        if z < D + 2 then
            if z % 2 == 1 then
                right()
                forward()
                right()
            else
                left()
                forward()
                left()
            end
        end
    end

    -- Decorative trim around upper front edge.
    up()

    for i = 1, W do
        place(TRIM)
        if i < W then forward() end
    end
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("=======================================")
print("       AMERICAN OFFICE BUILDER")
print("=======================================")
print("")
print("Office: 15 x 11")
print("Floors: 2")
print("")
print("Materials must be in slots 1-10.")
print("Starting in 5 seconds...")

fuel()
sleep(5)

foundation()
walls()
interiorWalls()
doors()
entrance()
lighting()
secondFloor()
roof()

print("")
print("=======================================")
print("          OFFICE COMPLETE")
print("=======================================")
print("")
print("Ground floor: reception + offices")
print("Second floor: offices + meeting areas")
print("Features: glass facade, entrance, stairs,")
print("interior walls, lighting and roof")
print("")
