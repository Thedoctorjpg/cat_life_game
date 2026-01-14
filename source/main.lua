import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animation"
import "CoreLibs/crank"

local pd <const> = playdate
local gfx <const> = pd.graphics
local snd <const> = pd.sound

-- ---------------------------------------------------------
-- GAME STATE & TIME CYCLES
-- ---------------------------------------------------------
local hunger = 100.0
local fishInventory = 0
local birdInventory = 0
local isGameOver = false

-- Movement Constants
local normalSpeed = 3
local sprintSpeed = 6

-- Day/Night & Crank Logic
local dayDuration = 2000 
local currentTime = 0
local isNight = false
local lightLevel = 1.0 
local isPurring = false

-- Surprise Event Variables
local surpriseActive = false

-- ---------------------------------------------------------
-- ASSET LOADING
-- ---------------------------------------------------------
local catTable = gfx.imagetable.new("images/cat-table-32-32")
local catAnimation = gfx.animation.loop.new(100, catTable, true)

local fishImage = gfx.image.new("images/fish")
local birdImage = gfx.image.new("images/bird")
local bowlImage = gfx.image.new("images/cat_food")
local poopImage = gfx.image.new("images/poop")
local bedImage = gfx.image.new("images/bed")
local surpriseImage = gfx.image.new("images/surprise")

local splashSound = snd.sampleplayer.new("sounds/splash")
local shakeSound = snd.sampleplayer.new("sounds/shake-bag")
local poopSound = snd.sampleplayer.new("sounds/pooping")
local bellSound = snd.sampleplayer.new("sounds/doorbell-rings")

-- ---------------------------------------------------------
-- SPRITE SETUP
-- ---------------------------------------------------------
local function createStdSprite(img, x, y)
    local s = gfx.sprite.new(img)
    s:moveTo(x, y)
    s:setCollideRect(0, 0, 32, 32)
    s:add()
    return s
end

local catSprite = gfx.sprite.new()
catSprite:moveTo(200, 120)
catSprite:setCollideRect(0, 0, 32, 32)
catSprite:add()

local fishSprite = createStdSprite(fishImage, 100, 100)
local birdSprite = createStdSprite(birdImage, 300, 50)
local bowlSprite = createStdSprite(bowlImage, 200, 200)
local bedSprite = createStdSprite(bedImage, 50, 50)
local surpriseSprite = gfx.sprite.new(surpriseImage)
surpriseSprite:setCollideRect(0, 0, 32, 32)

-- ---------------------------------------------------------
-- LOGIC FUNCTIONS
-- ---------------------------------------------------------

local function triggerSurprise()
    if not surpriseActive and not isGameOver then
        bellSound:play()
        surpriseActive = true
        surpriseSprite:moveTo(math.random(40, 360), math.random(40, 200))
        surpriseSprite:add()
        pd.timer.performAfterDelay(10000, function()
            if surpriseActive then surpriseSprite:remove(); surpriseActive = false end
        end)
    end
end

local function startSurpriseTimer()
    pd.timer.performAfterDelay(math.random(45000, 60000), function()
        triggerSurprise()
        startSurpriseTimer()
    end)
end

local function updateDayNight()
    currentTime = currentTime + 1
    if currentTime > dayDuration then currentTime = 0 end
    local progress = currentTime / dayDuration
    lightLevel = (math.sin(progress * math.pi * 2) + 1) / 2
    isNight = lightLevel < 0.4
end

local function drawOverlay()
    if lightLevel < 0.8 then
        gfx.setDitherPattern(1 - lightLevel, gfx.image.kDitherTypeBayer8x8)
        gfx.fillRect(0, 0, 400, 240)
    end
end

function updateInteractions(isSprinting)
    if isGameOver then return end

    -- Check for Crank Purr Mechanic
    local change = pd.getCrankChange()
    isPurring = (math.abs(change) > 2) and catSprite:collidesWith(bedSprite)

    -- Determine Hunger Drain Rate
    local baseDrain = 0.05
    if isNight then
        if catSprite:collidesWith(bedSprite) then
            baseDrain = isPurring and 0.005 or 0.02 -- Purring makes rest even better!
        else
            baseDrain = 0.1 -- Night wandering is hard work
        end
    end

    if isSprinting then
        hunger = hunger - (baseDrain * 3)
    else
        hunger = hunger - baseDrain
    end

    -- Collisions
    if catSprite:collidesWith(fishSprite) then
        splashSound:play()
        fishInventory = fishInventory + 1
        fishSprite:moveTo(math.random(32,368), math.random(32,208))
    end

    if surpriseActive and catSprite:collidesWith(surpriseSprite) then
        shakeSound:play()
        hunger = math.min(hunger + 50, 100)
        surpriseSprite:remove()
        surpriseActive = false
    end

    if catSprite:collidesWith(bowlSprite) then
        if fishInventory > 0 or birdInventory > 0 then
            shakeSound:play()
            hunger = math.min(hunger + (fishInventory * 25), 100)
            fishInventory = 0
            pd.timer.performAfterDelay(5000, function()
                poopSound:play()
                local p = gfx.sprite.new(poopImage)
                p:moveTo(catSprite:getPosition())
                p:add()
            end)
        end
    end
end

-- ---------------------------------------------------------
-- INITIALIZE & MAIN LOOP
-- ---------------------------------------------------------
startSurpriseTimer()

function pd.update()
    local isMoving = false
    local isSprinting = pd.buttonIsPressed(pd.kButtonB)
    local currentMoveSpeed = isSprinting and sprintSpeed or normalSpeed
    
    if not isGameOver then
        if pd.buttonIsPressed(pd.kButtonUp) then catSprite:moveBy(0, -currentMoveSpeed); isMoving = true end
        if pd.buttonIsPressed(pd.kButtonDown) then catSprite:moveBy(0, currentMoveSpeed); isMoving = true end
        if pd.buttonIsPressed(pd.kButtonLeft) then 
            catSprite:moveBy(-currentMoveSpeed, 0); isMoving = true; catSprite:setImageFlip(gfx.kImageFlippedX) 
        end
        if pd.buttonIsPressed(pd.kButtonRight) then 
            catSprite:moveBy(currentMoveSpeed, 0); isMoving = true; catSprite:setImageFlip(gfx.kImageUnflipped) 
        end

        if isMoving then
            catAnimation.delay = isSprinting and 50 or 100
            catSprite:setImage(catAnimation:image())
        else
            catSprite:setImage(catTable:getImage(1))
        end

        updateDayNight()
        updateInteractions(isSprinting and isMoving)
    end

    if hunger <= 0 then isGameOver = true end

    gfx.sprite.update()
    pd.timer.updateTimers()
    drawOverlay()
    
    -- UI
    gfx.drawText("Hunger: " .. math.floor(hunger), 10, 10)
    if isPurring then 
        gfx.drawText("PURRING... RESTORING", 120, 210) 
    elseif isSprinting and isMoving then 
        gfx.drawText("SPRINTING!", 140, 210) 
    end
end