local SERVER = require("core.libs.server")

local function newGameObjects(x, y, z, ry, model, shape, index)
    return {x = x, y = y, z = z, ry = ry, model = model, shape = shape, index = index}
end

function love.load()
    engine = {server = {}, players = {}, time = 0.2, gameObjects = {}}
    engine.server = SERVER()

    engine.gameObjects[1] = newGameObjects(-5, 10, -5, 0, "sphere", {1, 1, 1}, 1)
    
    engine.server:load()
end

function love.update(dt)
    engine.server:update(dt)


    ------------------------ DEBUGS PARTS ------------------------
    --for k, client in pairs(engine.server.main:getClients()) do
    --    if client:getState() == "connected" then
    --        print("----------------------------------------------")
    --        print("Positions du joueur ["..client:getIndex().."] :")
    --        print("x : "..client.player.x)
    --        print("y : "..client.player.y)
    --        print("z : "..client.player.z)
    --        print("----------------------------------------------")
    --    end
    --end
    ---------------------------------------------------------------
end