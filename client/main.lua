local CLIENT = require("core/libs/client")
local utils = require("core/libs/utils")
local dream = require("engine/init")
local cameraController = require("extensions/utils/cameraController")
local physics = require("extensions/physics/init")
local sky = require("extensions/sky")
local raytrace = require("extensions/raytrace")

dream:init()
dream:setFogHeight(0.0, 150.0)
dream:setSky(sky.render)

local sun = dream:newLight("sun")
sun:addNewShadow()

dream.camera.fov = 120

local objects = {
    default = dream:loadObject("assets/objects/sphere"),
    scene = dream:loadObject("assets/objects/scene"),
    player = dream:loadObject("assets/objects/player"),
}
local inventoryVGUI = nil

function love.load()
    engine = {dream = dream, world = physics:newWorld(), players = {}, gameObjects = {}, camera = cameraController, objects = objects, time = 0, sky = sky, sun = sun, raytrace = raytrace}
    engine.client = CLIENT()
    engine.client:load()

    engine.world:add(physics:newPhysicsObject(engine.objects.scene))
    engine.physics = physics
    engine.INDEX = engine.client.INDEX

   engine.screen_width, engine.screen_height = love.graphics.getDimensions()
end

function love.update(dt)
    engine.client:update(dt)

    if love.window.hasFocus() then
        engine.world:update(dt)

        engine.camera:update(dt)
        engine.dream:update()
    
        for _, player in pairs(engine.players) do
            player:update(dt)
        end
    
        for _, object in pairs(engine.gameObjects) do
            object:update(dt)
        end
    end
end

function love.draw()
    if engine.client.main:getState() == "connected" and love.window.hasFocus() then
        engine.dream:prepare()
        engine.dream:draw(engine.objects.scene)
        engine.dream:addLight(sun)

        for _, player in pairs(engine.players) do
            player:draw()
            if player.inventoryVGUI and not inventoryVGUI then
                inventoryVGUI = player.inventoryVGUI
            end
        end

        for _, object in pairs(engine.gameObjects) do
            object:draw()
        end

        engine.dream:present() 

        if inventoryVGUI then
            inventoryVGUI:draw()
        end
    end

    -- Afficher les valeurs de débogage
    local stats = love.graphics.getStats()
    local str = string.format("FPS: %d", love.timer.getFPS())
    love.graphics.print(str, 5, 5)
    str = string.format("Texture memory used: %.2f MB", stats.texturememory / 1024 / 1024)
    love.graphics.print(str, 5, 25)
    if engine.client then
        str = string.format("Player [%d], IP: %s, PORT: %d", engine.client.INDEX, engine.client.IP, engine.client.PORT)
        love.graphics.print(str, 5, 45)
    else
        love.graphics.print("No player number assigned", 5, 45)
    end
    --love.graphics.point(screen_width/2, screen_height/2)
end

function love.mousemoved(_, _, x, y)
    engine.camera:mousemoved(x, y)
end