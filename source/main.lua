import "CoreLibs/graphics"
import "CoreLibs/sprites"

local pd = playdate
local gfx = pd.graphics
local sound = pd.sound

-- Background & FX sounds (looping / one-shot)
local dayAmbience = sound.fileplayer.new("sounds/wind-birds")
local nightAmbience = sound.fileplayer.new("sounds/crickets-night")
local purrLoop = sound.fileplayer.new("sounds/purr-loop")
local rainLoop = sound.fileplayer.new("sounds/rain-patter")
local thunderSfx = sound.fileplayer.new("sounds/thunder")
local doorbellSfx = sound.fileplayer.new("sounds/doorbell")

-- Set volumes & loop where needed
if dayAmbience then dayAmbience:setVolume(0.4); dayAmbience:play(0) end
if nightAmbience then nightAmbience:setVolume(0.35); nightAmbience:stop() end
if purrLoop then purrLoop:setVolume(0.6); purrLoop:stop() end
if rainLoop then rainLoop:setVolume(0.45); rainLoop:stop() end
if thunderSfx then thunderSfx:setVolume(0.7) end
if doorbellSfx then doorbellSfx:setVolume(0.8) end

-- Game variables (example placeholders - replace with your actual ones)
local hunger = 0
local maxHunger = 100
local isOnBed = false
local dayNightCycle = 0  -- 0 = full day, 1 = full night (your cycle var)
local isStorming = false
local lastThunderTime = 0
local stormChance = 0.02  -- % chance per frame to start storm
local treatJustSpawned = false

-- Player sprite (example)
local playerSprite = gfx.sprite.new(gfx.image.new(32,32)) -- replace with your cat image
playerSprite:setCollideRect(0, 0, 32, 32)
playerSprite:moveTo(200, 120)
playerSprite:add()

function pd.update()
    gfx.sprite.update()

    -- Example: update day/night cycle (replace with your real logic)
    dayNightCycle = (dayNightCycle + 0.0005) % 1

    -- === AMBIENCE SWITCHING ===
    local isNight = (dayNightCycle > 0.6)

    if isNight then
        if dayAmbience then dayAmbience:stop() end
        if nightAmbience and not nightAmbience:isPlaying() then
            nightAmbience:play(0)
        end
    else
        if nightAmbience then nightAmbience:stop() end
        if dayAmbience and not dayAmbience:isPlaying() then
            dayAmbience:play(0)
        end
    end

    -- === STORM LOGIC ===
    if not isStorming and pd.getElapsedTime() - lastThunderTime > 30 then
        if math.random() < stormChance then
            isStorming = true
            if rainLoop then rainLoop:play(0) end
            print("Storm starting!")
        end
    end

    if isStorming then
        -- Random thunder rolls
        if pd.getElapsedTime() - lastThunderTime > math.random(8, 20) then
            if thunderSfx then thunderSfx:play(1) end
            lastThunderTime = pd.getElapsedTime()
        end

        -- End storm after ~60 seconds
        if pd.getElapsedTime() - lastThunderTime > 60 then
            isStorming = false
            if rainLoop then rainLoop:stop() end
            print("Storm cleared")
        end

        -- Rain makes sprint cost more hunger
        if pd.buttonIsPressed(pd.kButtonB) then
            hunger = hunger + 0.1  -- slippery & tiring
        end
    end

    -- === PURR LOOP ===
    if isOnBed then
        if pd.getCrankChange() ~= 0 then
            if purrLoop and not purrLoop:isPlaying() then
                purrLoop:play(0)
            end
        else
            if purrLoop then purrLoop:stop() end
        end
    else
        if purrLoop then purrLoop:stop() end
    end

    -- === DOORBELL SURPRISE ===
    if treatJustSpawned then
        if doorbellSfx then doorbellSfx:play(1) end
        treatJustSpawned = false
    end

    -- === YOUR EXISTING GAME LOGIC HERE ===
    -- hunger drain, movement, hunting, eating, etc.
    -- hunger = hunger + 0.01  -- example slow drain

    -- Simple HUD example
    gfx.drawText("Hunger: " .. math.floor(hunger), 10, 10)
    gfx.drawText("Storm: " .. (isStorming and "YES" or "no"), 10, 30)
end