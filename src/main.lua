import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local pd <const> = playdate
local gfx <const> = pd.graphics
local snd <const> = pd.sound

-- ---------------------------------------------------------
-- GAME STATE & INVENTORY
-- ---------------------------------------------------------
local hunger = 100.0
local isGameOver = false

-- Inventory for "Nude Food" ingredients
local fishInventory = 0
local birdInventory = 0
local survivalDays = 0
local dayTimer = 0

-- ---------------------------------------------------------
-- ASSET LOADING
-- ---------------------------------------------------------
local catImage = gfx.image.new("images/cat")
local fishImage = gfx.image.new("images/fish")
local birdImage = gfx.image.new("images/bird")
local foodImage = gfx.image.new("images/cat_food")
local poopImage = gfx.image.new("images/poop")

local splashSound = snd.sampleplayer.new("sounds/splash")
local crowSound = snd.sampleplayer.new("sounds/crow-call")
local shakeBagSound = snd.sampleplayer.new("sounds/shake-bag")
local poopSound = snd.sampleplayer.new("sounds/pooping")

-- Simple logger for automated sanity tests
local function logEvent(msg)
    local LOG_PATH = "/Users/admin/Documents/cat_life_game/cat_life_test.log"
    local ok, f = pcall(function() return io.open(LOG_PATH, "a") end)
    if ok and f then
        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
        f:close()
    else
        -- fallback to print if file access fails
        print("LOG: " .. tostring(msg))
    end
end

-- Automated sanity test (runs once if enabled)
local AUTO_TEST = true
local testState = 0
local testTimer = 0
local testCompleted = false

local function runAutoTest()
    if not AUTO_TEST or testCompleted then return end
    testTimer = testTimer + 1

    if testState == 0 and testTimer > 10 then
        local fx, fy = fishSprite:getPosition()
        catSprite:moveTo(fx, fy)
        logEvent("AutoTest: moved cat to fish")
        testState = 1
        testTimer = 0
    elseif testState == 1 then
        if catSprite:collidesWith(fishSprite) then
            updateInteractions()
            if fishInventory > 0 then
                logEvent("AutoTest: fish pickup PASS (fishInventory=" .. fishInventory .. ")")
            else
                logEvent("AutoTest: fish pickup FAIL")
            end
            testState = 2
            testTimer = 0
        end
    elseif testState == 2 and testTimer > 10 then
        local bx, by = foodBowlSprite:getPosition()
        catSprite:moveTo(bx, by)
        logEvent("AutoTest: moved cat to bowl")
        testState = 3
        testTimer = 0
    elseif testState == 3 then
        if catSprite:collidesWith(foodBowlSprite) then
            updateInteractions()
            if fishInventory == 0 and birdInventory == 0 then
                logEvent("AutoTest: eat/reset PASS (inventory reset)")
            else
                logEvent("AutoTest: eat/reset FAIL (fish=" .. fishInventory .. ", bird=" .. birdInventory .. ")")
            end
            testCompleted = true
            logEvent("AutoTest: completed. hunger=" .. hunger)
            AUTO_TEST = false
        end
    end
end

-- ---------------------------------------------------------
-- SPRITE SETUP
-- ---------------------------------------------------------
local catSprite = gfx.sprite.new(catImage)
catSprite:moveTo(200, 120)
catSprite:setCollideRect(0, 0, catSprite:getSize())
catSprite:add()

local fishSprite = gfx.sprite.new(fishImage)
fishSprite:moveTo(100, 100)
fishSprite:add()

local birdSprite = gfx.sprite.new(birdImage)
birdSprite:moveTo(300, 50)
birdSprite:add()

-- The "Processing Station" (Nadia Lim's Development Kitchen style)
local foodBowlSprite = gfx.sprite.new(foodImage)
foodBowlSprite:moveTo(200, 200)
foodBowlSprite:setCollideRect(0, 0, foodBowlSprite:getSize())
foodBowlSprite:add()

-- ---------------------------------------------------------
-- UI DRAWING
-- ---------------------------------------------------------
local function drawUI()
    gfx.drawText("HUNGER:", 10, 10)
    gfx.drawRect(80, 12, 100, 12)
    if hunger > 0 then gfx.fillRect(82, 14, (hunger * 0.96), 8) end
    
    -- Display Inventory
    gfx.drawText("FISH: " .. fishInventory, 300, 10)
    gfx.drawText("BIRDS: " .. birdInventory, 300, 30)
    gfx.drawText("DAY: " .. survivalDays, 10, 210)
end

-- ---------------------------------------------------------
-- PRODUCTION LOGIC
-- ---------------------------------------------------------
function updateInteractions()
    if isGameOver then return end

    -- 1. Hunting for Ingredients
    if catSprite:collidesWith(fishSprite) then
        splashSound:play()
        fishInventory = fishInventory + 1
        logEvent("Picked up fish; fishInventory=" .. fishInventory)
        fishSprite:moveTo(math.random(20, 380), math.random(40, 180))
    end

    if catSprite:collidesWith(birdSprite) then
        crowSound:play()
        birdInventory = birdInventory + 1
        logEvent("Picked up bird; birdInventory=" .. birdInventory)
        birdSprite:moveTo(math.random(20, 380), math.random(20, 100))
    end

    -- 2. Making and Eating Food at the Bowl
    if catSprite:collidesWith(foodBowlSprite) then
        if fishInventory > 0 or birdInventory > 0 then
            -- Processing fresh ingredients into a balanced meal
            shakeBagSound:play()
            
            local mealValue = (fishInventory * 20) + (birdInventory * 35)
            hunger = math.min(hunger + mealValue, 100)
            logEvent("Ate meal: mealValue=" .. mealValue .. ", hunger=" .. hunger)
            
            -- Reset inventory after "cooking"
            fishInventory = 0
            birdInventory = 0
            
            -- Trigger digestion (poop) after a healthy meal
            pd.timer.performAfterDelay(4000, function()
                poopSound:play()
                local px, py = catSprite:getPosition()
                logEvent("Pooped at: " .. px .. "," .. py)
                local p = gfx.sprite.new(poopImage)
                p:moveTo(px, py)
                p:add()
            end)
        end
    end
end

-- ---------------------------------------------------------
-- MAIN LOOP
-- ---------------------------------------------------------
function pd.update()
    if not isGameOver then
        if pd.buttonIsPressed(pd.kButtonUp) then catSprite:moveBy(0, -3) end
        if pd.buttonIsPressed(pd.kButtonDown) then catSprite:moveBy(0, 3) end
        if pd.buttonIsPressed(pd.kButtonLeft) then catSprite:moveBy(-3, 0) end
        if pd.buttonIsPressed(pd.kButtonRight) then catSprite:moveBy(3, 0) end
        
        runAutoTest()
        
        hunger = hunger - 0.06
        if hunger <= 0 then isGameOver = true end
        
        updateInteractions()
    end
    
    gfx.sprite.update()
    pd.timer.updateTimers()
    drawUI()
end