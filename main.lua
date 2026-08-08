
-- main.lua
-- Mini Stardew Valley style farming game
-- Everything is contained in one file

math.randomseed(os.time())

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local TILE_SIZE = 40

local WORLD_TILES_X = 50
local WORLD_TILES_Y = 38

local WORLD_WIDTH = WORLD_TILES_X * TILE_SIZE
local WORLD_HEIGHT = WORLD_TILES_Y * TILE_SIZE

local SCREEN_WIDTH = 800
local SCREEN_HEIGHT = 600

--------------------------------------------------
-- PLAYER
--------------------------------------------------

player = {
    x = 1000,
    y = 760,

    width = 28,
    height = 28,

    speed = 220,

    direction = "down",

    holdingPlant = nil
}

--------------------------------------------------
-- GAME STATE
--------------------------------------------------

score = 0
day = 1

seeds = 10

selectedTool = "hand"

message = ""
messageTimer = 0

camera = {
    x = 0,
    y = 0
}

--------------------------------------------------
-- PLANTS
--------------------------------------------------

plants = {}

-- Growth stages:
--
-- 1 = seed
-- 2 = sprout
-- 3 = small plant
-- 4 = adult plant
-- 5 = ready to harvest

PLANT_GROW_TIME = {
    [1] = 5,
    [2] = 10,
    [3] = 15,
    [4] = 20
}

--------------------------------------------------
-- TREES
--------------------------------------------------

trees = {
    {
        tileX = 8,
        tileY = 7
    },

    {
        tileX = 12,
        tileY = 10
    },

    {
        tileX = 32,
        tileY = 8
    },

    {
        tileX = 38,
        tileY = 22
    },

    {
        tileX = 10,
        tileY = 28
    },

    {
        tileX = 42,
        tileY = 12
    }
}

--------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------

function showMessage(text)

    message = text
    messageTimer = 2.5

end


--------------------------------------------------
-- DISTANCE
--------------------------------------------------

function distance(x1, y1, x2, y2)

    local dx = x2 - x1
    local dy = y2 - y1

    return math.sqrt(dx * dx + dy * dy)

end


--------------------------------------------------
-- GET TILE CENTER
--------------------------------------------------

function getTileCenter(tileX, tileY)

    local x =
        tileX * TILE_SIZE +
        TILE_SIZE / 2

    local y =
        tileY * TILE_SIZE +
        TILE_SIZE / 2

    return x, y

end


--------------------------------------------------
-- WORLD POSITION -> TILE
--------------------------------------------------

function worldToTile(x, y)

    local tileX =
        math.floor(x / TILE_SIZE)

    local tileY =
        math.floor(y / TILE_SIZE)

    return tileX, tileY

end


--------------------------------------------------
-- CHECK VALID TILE
--------------------------------------------------

function isValidTile(tileX, tileY)

    if tileX < 0 then
        return false
    end

    if tileY < 0 then
        return false
    end

    if tileX >= WORLD_TILES_X then
        return false
    end

    if tileY >= WORLD_TILES_Y then
        return false
    end

    return true

end


--------------------------------------------------
-- PLAYER CENTER
--------------------------------------------------

function getPlayerCenter()

    return
        player.x + player.width / 2,
        player.y + player.height / 2

end


--------------------------------------------------
-- GET PLAYER TILE
--------------------------------------------------

function getPlayerTile()

    local x, y =
        getPlayerCenter()

    return worldToTile(x, y)

end


--------------------------------------------------
-- GET TARGET TILE
--------------------------------------------------

function getTargetTile()

    local tileX, tileY =
        getPlayerTile()

    if player.direction == "up" then
        tileY = tileY - 0
    end

    if player.direction == "down" then
        tileY = tileY + 0
    end

    if player.direction == "left" then
        tileX = tileX - 0
    end

    if player.direction == "right" then
        tileX = tileX + 0
    end

    return tileX, tileY

end


--------------------------------------------------
-- FIND PLANT ON TILE
--------------------------------------------------

function getPlantAtTile(tileX, tileY)

    for _, plant in ipairs(plants) do

        if plant.tileX == tileX
        and plant.tileY == tileY then

            return plant

        end

    end

    return nil

end


--------------------------------------------------
-- CHECK TREE ON TILE
--------------------------------------------------

function getTreeAtTile(tileX, tileY)

    for _, tree in ipairs(trees) do

        if tree.tileX == tileX
        and tree.tileY == tileY then

            return tree

        end

    end

    return nil

end


--------------------------------------------------
-- CHECK IF TILE IS OCCUPIED
--------------------------------------------------

function isTileOccupied(tileX, tileY)

    if not isValidTile(tileX, tileY) then
        return true
    end

    if getTreeAtTile(tileX, tileY) ~= nil then
        return true
    end

    if getPlantAtTile(tileX, tileY) ~= nil then
        return true
    end

    return false

end


--------------------------------------------------
-- PLAYER COLLISION
--------------------------------------------------

function canMoveTo(x, y)

    local left =
        math.floor(x / TILE_SIZE)

    local right =
        math.floor(
            (x + player.width - 1)
            / TILE_SIZE
        )

    local top =
        math.floor(y / TILE_SIZE)

    local bottom =
        math.floor(
            (y + player.height - 1)
            / TILE_SIZE
        )


    -- World boundaries

    if left < 0 then
        return false
    end

    if right >= WORLD_TILES_X then
        return false
    end

    if top < 0 then
        return false
    end

    if bottom >= WORLD_TILES_Y then
        return false
    end


    -- Check every tile occupied by player

    for tileX = left, right do

        for tileY = top, bottom do

            if getTreeAtTile(tileX, tileY) ~= nil then
                return false
            end

        end

    end

    return true

end


--------------------------------------------------
-- PLANT SEED
--------------------------------------------------

function plantSeed(tileX, tileY)

    if seeds <= 0 then

        showMessage(
            "You are out of seeds!"
        )

        return

    end


    if not isValidTile(tileX, tileY) then

        showMessage(
            "This tile is outside the farm"
        )

        return

    end


    if getTreeAtTile(tileX, tileY) ~= nil then

        showMessage(
            "You cannot plant on a tree"
        )

        return

    end


    if getPlantAtTile(tileX, tileY) ~= nil then

        showMessage(
            "This tile already has a plant"
        )

        return

    end


    local plant = {

        tileX = tileX,
        tileY = tileY,

        stage = 1,

        growth = 0,

        watered = false,

        waterTime = 0,

        carrying = false

    }


    table.insert(
        plants,
        plant
    )

    seeds = seeds - 1


    showMessage(
        "Seed planted!"
    )

end


--------------------------------------------------
-- WATER PLANT
--------------------------------------------------

function waterPlant(tileX, tileY)

    local plant =
        getPlantAtTile(
            tileX,
            tileY
        )


    if plant == nil then

        showMessage(
            "There is no plant on this tile"
        )

        return

    end


    if plant.carrying then
        return
    end


    if plant.stage >= 5 then

        showMessage(
            "This plant is ready to harvest!"
        )

        return

    end


    plant.watered = true
    plant.waterTime = 5


    showMessage(
        "Plant watered!"
    )

end


--------------------------------------------------
-- PICK UP PLANT
--------------------------------------------------

function pickUpPlant(plant)

    if plant == nil then
        return
    end


    if plant.carrying then
        return
    end


    if plant.stage < 4 then

        showMessage(
            "The plant is still growing"
        )

        return

    end


    plant.carrying = true

    player.holdingPlant = plant


    showMessage(
        "Plant picked up!"
    )

end


--------------------------------------------------
-- PLACE PLANT
--------------------------------------------------

function placePlant(tileX, tileY)

    local plant =
        player.holdingPlant


    if plant == nil then
        return
    end


    if not isValidTile(tileX, tileY) then

        showMessage(
            "You cannot place the plant here"
        )

        return

    end


    if isTileOccupied(tileX, tileY) then

        showMessage(
            "This tile is occupied"
        )

        return

    end


    plant.tileX = tileX
    plant.tileY = tileY

    plant.carrying = false

    player.holdingPlant = nil


    showMessage(
        "Plant placed!"
    )

end


--------------------------------------------------
-- HARVEST PLANT
--------------------------------------------------

function harvestPlant(plant)

    if plant == nil then
        return
    end


    if plant.stage < 5 then

        showMessage(
            "The plant is not ready yet"
        )

        return

    end


    for i, p in ipairs(plants) do

        if p == plant then

            table.remove(
                plants,
                i
            )

            score = score + 1


            showMessage(
                "Harvest collected! +1"
            )

            return

        end

    end

end


--------------------------------------------------
-- INTERACT WITH TILE
--------------------------------------------------

function interact()

    local tileX, tileY =
        getTargetTile()


    if not isValidTile(
        tileX,
        tileY
    ) then

        showMessage(
            "This tile is outside the world"
        )

        return

    end


    ------------------------------------------------
    -- HOLDING PLANT
    ------------------------------------------------

    if player.holdingPlant ~= nil then

        placePlant(
            tileX,
            tileY
        )

        return

    end


    ------------------------------------------------
    -- PLANT ON TILE
    ------------------------------------------------

    local plant =
        getPlantAtTile(
            tileX,
            tileY
        )


    if plant ~= nil then


        ------------------------------------------------
        -- HARVEST
        ------------------------------------------------

        if plant.stage >= 5 then

            harvestPlant(
                plant
            )

            return

        end


        ------------------------------------------------
        -- PICK UP
        ------------------------------------------------

        if plant.stage >= 4 then

            pickUpPlant(
                plant
            )

            return

        end


        showMessage(
            "The plant is still growing"
        )

        return

    end


    ------------------------------------------------
    -- EMPTY TILE
    ------------------------------------------------

    plantSeed(
        tileX,
        tileY
    )

end


--------------------------------------------------
-- WATER TARGET TILE
--------------------------------------------------

function waterTargetTile()

    local tileX, tileY =
        getTargetTile()


    if not isValidTile(
        tileX,
        tileY
    ) then

        showMessage(
            "This tile is outside the world"
        )

        return

    end


    waterPlant(
        tileX,
        tileY
    )

end


--------------------------------------------------
-- LOVE.LOAD
--------------------------------------------------

function love.load()

    love.window.setMode(
        SCREEN_WIDTH,
        SCREEN_HEIGHT
    )


    love.window.setTitle(
        "Mini Stardew Valley"
    )


    ------------------------------------------------
    -- Demo plants
    ------------------------------------------------

    plantSeed(
        20,
        12
    )

    plantSeed(
        21,
        12
    )

    plantSeed(
        22,
        12
    )


    -- Restore seeds

    seeds = 10

end


--------------------------------------------------
-- LOVE.UPDATE
--------------------------------------------------

function love.update(dt)

    ------------------------------------------------
    -- MESSAGE TIMER
    ------------------------------------------------

    if messageTimer > 0 then

        messageTimer =
            messageTimer - dt


        if messageTimer <= 0 then
            message = ""
        end

    end


    ------------------------------------------------
    -- MOVEMENT
    ------------------------------------------------

    local dx = 0
    local dy = 0


    if love.keyboard.isDown("w") then

        dy = dy - 1

        player.direction = "up"

    end


    if love.keyboard.isDown("s") then

        dy = dy + 1

        player.direction = "down"

    end


    if love.keyboard.isDown("a") then

        dx = dx - 1

        player.direction = "left"

    end


    if love.keyboard.isDown("d") then

        dx = dx + 1

        player.direction = "right"

    end


    ------------------------------------------------
    -- NORMALIZE DIAGONAL MOVEMENT
    ------------------------------------------------

    if dx ~= 0
    or dy ~= 0 then

        local length =
            math.sqrt(
                dx * dx +
                dy * dy
            )


        dx =
            dx / length

        dy =
            dy / length

    end


    ------------------------------------------------
    -- MOVE PLAYER
    ------------------------------------------------

    local newX =
        player.x +
        dx * player.speed * dt


    local newY =
        player.y +
        dy * player.speed * dt


    if canMoveTo(
        newX,
        player.y
    ) then

        player.x = newX

    end


    if canMoveTo(
        player.x,
        newY
    ) then

        player.y = newY

    end


    ------------------------------------------------
    -- PLANT GROWTH
    ------------------------------------------------

    for _, plant in ipairs(plants) do

        if not plant.carrying
        and plant.stage < 5 then


            if plant.watered then

                plant.waterTime =
                    plant.waterTime - dt


                ------------------------------------------------
                -- WATER EXPIRED
                ------------------------------------------------

                if plant.waterTime <= 0 then

                    plant.watered = false

                end


                ------------------------------------------------
                -- GROW
                ------------------------------------------------

                plant.growth =
                    plant.growth + dt


                local required =
                    PLANT_GROW_TIME[
                        plant.stage
                    ]


                if plant.growth >= required then

                    plant.growth = 0

                    plant.stage =
                        plant.stage + 1


                    if plant.stage == 5 then

                        showMessage(
                            "Plant is ready to harvest!"
                        )

                    end

                end

            end

        end

    end


    ------------------------------------------------
    -- CAMERA
    ------------------------------------------------

    camera.x =
        player.x +
        player.width / 2 -
        SCREEN_WIDTH / 2


    camera.y =
        player.y +
        player.height / 2 -
        SCREEN_HEIGHT / 2


    ------------------------------------------------
    -- CAMERA BOUNDARIES
    ------------------------------------------------

    if camera.x < 0 then
        camera.x = 0
    end


    if camera.y < 0 then
        camera.y = 0
    end


    if camera.x >
        WORLD_WIDTH - SCREEN_WIDTH then

        camera.x =
            WORLD_WIDTH - SCREEN_WIDTH

    end


    if camera.y >
        WORLD_HEIGHT - SCREEN_HEIGHT then

        camera.y =
            WORLD_HEIGHT - SCREEN_HEIGHT

    end

end


--------------------------------------------------
-- LOVE.KEYPRESSED
--------------------------------------------------

function love.keypressed(key)


    ------------------------------------------------
    -- INTERACT
    ------------------------------------------------

    if key == "e" then

        interact()

    end


    ------------------------------------------------
    -- WATER
    ------------------------------------------------

    if key == "space" then

        waterTargetTile()

    end


    ------------------------------------------------
    -- TOOL SELECTION
    ------------------------------------------------

    if key == "1" then

        selectedTool = "hand"

        showMessage(
            "Hand selected"
        )

    end


    if key == "2" then

        selectedTool = "water"

        showMessage(
            "Watering can selected"
        )

    end


    if key == "3" then

        selectedTool = "seed"

        showMessage(
            "Seeds selected"
        )

    end


    ------------------------------------------------
    -- QUICK PLANT
    ------------------------------------------------

    if key == "r" then

        local tileX, tileY =
            getTargetTile()


        plantSeed(
            tileX,
            tileY
        )

    end

end


--------------------------------------------------
-- DRAW GROUND
--------------------------------------------------

function drawGround()

    ------------------------------------------------
    -- BASE GROUND
    ------------------------------------------------

    love.graphics.setColor(
        0.35,
        0.55,
        0.25
    )


    love.graphics.rectangle(
        "fill",
        0,
        0,
        WORLD_WIDTH,
        WORLD_HEIGHT
    )


    ------------------------------------------------
    -- TILE GRID
    ------------------------------------------------

    love.graphics.setColor(
        0.25,
        0.43,
        0.18,
        0.45
    )


    for tileX = 0,
        WORLD_TILES_X do

        local x =
            tileX * TILE_SIZE


        love.graphics.line(
            x,
            0,
            x,
            WORLD_HEIGHT
        )

    end


    for tileY = 0,
        WORLD_TILES_Y do

        local y =
            tileY * TILE_SIZE


        love.graphics.line(
            0,
            y,
            WORLD_WIDTH,
            y
        )

    end


    ------------------------------------------------
    -- FARM AREA
    ------------------------------------------------

    love.graphics.setColor(
        0.55,
        0.38,
        0.20
    )


    love.graphics.rectangle(
        "fill",
        600,
        400,
        700,
        600
    )


    ------------------------------------------------
    -- FARM GRID
    ------------------------------------------------

    love.graphics.setColor(
        0.40,
        0.27,
        0.14,
        0.6
    )


    for x = 600,
        1300,
        TILE_SIZE do

        love.graphics.line(
            x,
            400,
            x,
            1000
        )

    end


    for y = 400,
        1000,
        TILE_SIZE do

        love.graphics.line(
            600,
            y,
            1300,
            y
        )

    end

end


--------------------------------------------------
-- DRAW TREES
--------------------------------------------------

function drawTrees()

    for _, tree in ipairs(trees) do

        local x, y =
            getTileCenter(
                tree.tileX,
                tree.tileY
            )


        ------------------------------------------------
        -- TRUNK
        ------------------------------------------------

        love.graphics.setColor(
            0.35,
            0.20,
            0.08
        )


        love.graphics.rectangle(
            "fill",
            x - 9,
            y,
            18,
            25
        )


        ------------------------------------------------
        -- TREE CROWN
        ------------------------------------------------

        love.graphics.setColor(
            0.05,
            0.35,
            0.08
        )


        love.graphics.circle(
            "fill",
            x,
            y - 5,
            25
        )


        love.graphics.setColor(
            0.10,
            0.50,
            0.12
        )


        love.graphics.circle(
            "fill",
            x - 8,
            y - 13,
            14
        )

    end

end


--------------------------------------------------
-- DRAW PLANT
--------------------------------------------------

function drawPlant(plant)

    local x, y =
        getTileCenter(
            plant.tileX,
            plant.tileY
        )


    ------------------------------------------------
    -- STAGE 1
    ------------------------------------------------

    if plant.stage == 1 then

        love.graphics.setColor(
            0.45,
            0.25,
            0.08
        )


        love.graphics.circle(
            "fill",
            x,
            y + 5,
            6
        )

    end


    ------------------------------------------------
    -- STAGE 2
    ------------------------------------------------

    if plant.stage == 2 then

        love.graphics.setColor(
            0.10,
            0.60,
            0.10
        )


        love.graphics.rectangle(
            "fill",
            x - 3,
            y - 12,
            6,
            17
        )


        love.graphics.circle(
            "fill",
            x - 7,
            y - 10,
            7
        )


        love.graphics.circle(
            "fill",
            x + 7,
            y - 10,
            7
        )

    end


    ------------------------------------------------
    -- STAGE 3
    ------------------------------------------------

    if plant.stage == 3 then

        love.graphics.setColor(
            0.08,
            0.55,
            0.08
        )


        love.graphics.rectangle(
            "fill",
            x - 4,
            y - 20,
            8,
            25
        )


        love.graphics.circle(
            "fill",
            x - 11,
            y - 15,
            10
        )


        love.graphics.circle(
            "fill",
            x + 11,
            y - 15,
            10
        )

    end


    ------------------------------------------------
    -- STAGE 4
    ------------------------------------------------

    if plant.stage == 4 then

        love.graphics.setColor(
            0.05,
            0.45,
            0.05
        )


        love.graphics.rectangle(
            "fill",
            x - 5,
            y - 30,
            10,
            35
        )


        love.graphics.circle(
            "fill",
            x - 13,
            y - 23,
            13
        )


        love.graphics.circle(
            "fill",
            x + 13,
            y - 23,
            13
        )


        love.graphics.circle(
            "fill",
            x,
            y - 34,
            14
        )

    end


    ------------------------------------------------
    -- STAGE 5
    ------------------------------------------------

    if plant.stage == 5 then

        love.graphics.setColor(
            0.05,
            0.40,
            0.05
        )


        love.graphics.rectangle(
            "fill",
            x - 5,
            y - 35,
            10,
            40
        )


        love.graphics.circle(
            "fill",
            x - 14,
            y - 25,
            13
        )


        love.graphics.circle(
            "fill",
            x + 14,
            y - 25,
            13
        )


        ------------------------------------------------
        -- FRUIT
        ------------------------------------------------

        love.graphics.setColor(
            1,
            0.65,
            0.05
        )


        love.graphics.circle(
            "fill",
            x,
            y - 40,
            14
        )


        love.graphics.setColor(
            1,
            1,
            0.2
        )


        love.graphics.circle(
            "line",
            x,
            y - 40,
            18
        )

    end


    ------------------------------------------------
    -- WATER INDICATOR
    ------------------------------------------------

    if plant.watered then

        love.graphics.setColor(
            0.2,
            0.7,
            1
        )


        love.graphics.circle(
            "fill",
            x + 14,
            y - 14,
            4
        )

    end

end


--------------------------------------------------
-- DRAW PLAYER
--------------------------------------------------

function drawPlayer()

    local x = player.x
    local y = player.y


    ------------------------------------------------
    -- BODY
    ------------------------------------------------

    love.graphics.setColor(
        0.15,
        0.55,
        1
    )


    love.graphics.rectangle(
        "fill",
        x,
        y,
        player.width,
        player.height
    )


    ------------------------------------------------
    -- HEAD
    ------------------------------------------------

    love.graphics.setColor(
        1,
        0.75,
        0.55
    )


    love.graphics.circle(
        "fill",
        x + player.width / 2,
        y - 5,
        12
    )


    ------------------------------------------------
    -- PLANT IN HANDS
    ------------------------------------------------

    if player.holdingPlant ~= nil then

        love.graphics.setColor(
            0.08,
            0.55,
            0.08
        )


        love.graphics.circle(
            "fill",
            x + player.width / 2,
            y - 32,
            12
        )


        love.graphics.setColor(
            0.5,
            0.3,
            0.1
        )


        love.graphics.rectangle(
            "fill",
            x + player.width / 2 - 4,
            y - 22,
            8,
            20
        )

    end

end


--------------------------------------------------
-- DRAW TARGET TILE
--------------------------------------------------

function drawTargetTile()

    local tileX, tileY =
        getTargetTile()


    if not isValidTile(
        tileX,
        tileY
    ) then

        return

    end


    local x =
        tileX * TILE_SIZE

    local y =
        tileY * TILE_SIZE


    ------------------------------------------------
    -- TARGET TILE
    ------------------------------------------------

    love.graphics.setColor(
        1,
        1,
        1,
        0.25
    )


    love.graphics.rectangle(
        "fill",
        x,
        y,
        TILE_SIZE,
        TILE_SIZE
    )


    ------------------------------------------------
    -- TARGET OUTLINE
    ------------------------------------------------

    love.graphics.setColor(
        1,
        1,
        1,
        0.8
    )


    love.graphics.setLineWidth(2)


    love.graphics.rectangle(
        "line",
        x + 1,
        y + 1,
        TILE_SIZE - 2,
        TILE_SIZE - 2
    )


    love.graphics.setLineWidth(1)

end


--------------------------------------------------
-- DRAW UI
--------------------------------------------------

function drawUI()

    ------------------------------------------------
    -- TOP PANEL
    ------------------------------------------------

    love.graphics.setColor(
        0,
        0,
        0,
        0.65
    )


    love.graphics.rectangle(
        "fill",
        0,
        0,
        SCREEN_WIDTH,
        85
    )


    love.graphics.setColor(
        1,
        1,
        1
    )


    love.graphics.print(
        "Day: " .. day,
        15,
        10
    )


    love.graphics.print(
        "Harvest: " .. score,
        15,
        32
    )


    love.graphics.print(
        "Seeds: " .. seeds,
        15,
        54
    )


    ------------------------------------------------
    -- CONTROLS
    ------------------------------------------------

    love.graphics.print(
        "WASD - Move",
        180,
        10
    )


    love.graphics.print(
        "E - Interact with tile",
        180,
        30
    )


    love.graphics.print(
        "SPACE - Water tile",
        180,
        50
    )


    love.graphics.print(
        "R - Plant seed",
        400,
        10
    )


    ------------------------------------------------
    -- TOOL
    ------------------------------------------------

    local toolText = ""


    if selectedTool == "hand" then

        toolText = "Hand"

    elseif selectedTool == "water" then

        toolText = "Watering Can"

    elseif selectedTool == "seed" then

        toolText = "Seeds"

    end


    love.graphics.print(
        "Tool: " .. toolText,
        400,
        30
    )


    ------------------------------------------------
    -- MESSAGE
    ------------------------------------------------

    if message ~= "" then

        local width = 400
        local height = 45


        local x =
            SCREEN_WIDTH / 2 -
            width / 2


        local y =
            SCREEN_HEIGHT - 75


        love.graphics.setColor(
            0,
            0,
            0,
            0.75
        )


        love.graphics.rectangle(
            "fill",
            x,
            y,
            width,
            height
        )


        love.graphics.setColor(
            1,
            1,
            1
        )


        love.graphics.printf(
            message,
            x,
            y + 14,
            width,
            "center"
        )

    end


    ------------------------------------------------
    -- TARGET INFORMATION
    ------------------------------------------------

    local tileX, tileY =
        getTargetTile()


    if isValidTile(
        tileX,
        tileY
    ) then

        local plant =
            getPlantAtTile(
                tileX,
                tileY
            )


        local tree =
            getTreeAtTile(
                tileX,
                tileY
            )


        local targetText = ""


        if plant ~= nil then

            if plant.stage == 1 then

                targetText =
                    "Seed"

            elseif plant.stage == 2 then

                targetText =
                    "Sprout"

            elseif plant.stage == 3 then

                targetText =
                    "Young Plant"

            elseif plant.stage == 4 then

                targetText =
                    "Adult Plant"

            elseif plant.stage == 5 then

                targetText =
                    "Ready to Harvest"

            end


            if plant.watered then

                targetText =
                    targetText ..
                    " - Watered"

            else

                targetText =
                    targetText ..
                    " - Dry"

            end


        elseif tree ~= nil then

            targetText =
                "Tree"


        else

            targetText =
                "Empty Tile"

        end


        love.graphics.setColor(
            1,
            1,
            1
        )


        love.graphics.print(
            targetText,
            600,
            10
        )

    end

end


--------------------------------------------------
-- LOVE.DRAW
--------------------------------------------------

function love.draw()

    ------------------------------------------------
    -- CAMERA
    ------------------------------------------------

    love.graphics.push()


    love.graphics.translate(
        -camera.x,
        -camera.y
    )


    ------------------------------------------------
    -- GROUND
    ------------------------------------------------

    drawGround()


    ------------------------------------------------
    -- TARGET TILE
    ------------------------------------------------

    drawTargetTile()


    ------------------------------------------------
    -- TREES
    ------------------------------------------------

    drawTrees()


    ------------------------------------------------
    -- PLANTS
    ------------------------------------------------

    for _, plant in ipairs(plants) do

        if not plant.carrying then

            drawPlant(
                plant
            )

        end

    end


    ------------------------------------------------
    -- PLAYER
    ------------------------------------------------

    drawPlayer()


    love.graphics.pop()


    ------------------------------------------------
    -- UI
    ------------------------------------------------

    drawUI()

end

