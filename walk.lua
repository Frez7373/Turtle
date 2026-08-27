-- POLISHED ANDESITE ROAD WALKER
-- CC:Tweaked Turtle

local ROAD = "minecraft:polished_andesite"

-- Проверяет, является ли блок дорожкой
local function isRoad(block)
    return block and block.name == ROAD
end

-- Проверка блока впереди
local function canMoveForward()
    local ok, data = turtle.inspect()
    
    if not ok then
        return true
    end
    
    return false
end

-- Безопасное движение вперед
local function safeForward()
    if canMoveForward() then
        return turtle.forward()
    end
    
    return false
end

-- Проверяет дорожку перед собой
local function roadForward()
    local ok, data = turtle.inspect()
    
    if not ok then
        return false
    end
    
    return isRoad(data)
end

-- Проверяет дорожку слева
local function roadLeft()
    turtle.turnLeft()
    
    local ok, data = turtle.inspect()
    local result = ok and isRoad(data)
    
    turtle.turnRight()
    
    return result
end

-- Проверяет дорожку справа
local function roadRight()
    turtle.turnRight()
    
    local ok, data = turtle.inspect()
    local result = ok and isRoad(data)
    
    turtle.turnLeft()
    
    return result
end

-- Проверяет, свободен ли путь
local function freeForward()
    local ok = turtle.inspect()
    return not ok
end

-- Пытается выбрать направление
local function chooseDirection()

    -- Сначала вперед
    if freeForward() then
        return "forward"
    end

    -- Если впереди препятствие, ищем дорожку слева
    if roadLeft() then
        return "left"
    end

    -- Или справа
    if roadRight() then
        return "right"
    end

    -- Ничего нет — разворот
    return "back"
end

-- Делаем шаг
local function walkStep()

    local direction = chooseDirection()

    if direction == "forward" then
        turtle.forward()

    elseif direction == "left" then
        turtle.turnLeft()

        if freeForward() then
            turtle.forward()
        end

    elseif direction == "right" then
        turtle.turnRight()

        if freeForward() then
            turtle.forward()
        end

    elseif direction == "back" then
        turtle.turnLeft()
        turtle.turnLeft()

        if freeForward() then
            turtle.forward()
        end
    end
end

print("POLISHED ANDESITE WALKER")
print("Starting...")

while true do

    -- Если впереди свободно — идём
    if freeForward() then
        turtle.forward()
    else
        -- Иначе выбираем другое направление
        walkStep()
    end

    -- Небольшая задержка
    sleep(0.15)
end
