local utils = require("core.libs.utils")
local Class = require("core.libs.class")
local sock = require("libs.sock")
local bitser = require("libs.spec.bitser")

local SERVER_IP = "*" --"*"
local SERVER_PORT = 22122 --22122

local function newPlayer(x, y, z, ry, index)
    return {x = x, y = y, z = z, ry = ry, index = index}
end

local function sendPlayerState(client, index, newX, newY, newZ, newRy)
    client:send("playersState", {index, newX, newY, newZ, newRy})
end

local function distance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

Server = Class{
    init = function(self, IP, PORT, TICKRATE, NAME)
        self.IP = IP or SERVER_IP
        self.PORT = PORT or SERVER_PORT
        self.NAME = NAME or "Unassigned"
        self.TICKRATE = 1 / 60
        self.TICK = 0
        self.main = sock.newServer(self.IP, self.PORT)

        self.main:setSerialization(bitser.dumps, bitser.loads)
        self.main:enableCompression()
    end,

    load = function(self)
        self.main:setSchema("playerUpdate", {"index", "x", "y", "z", "ry"})
        self.main:setSchema("gameObjectsUpdate", {"index", "x", "y", "z", "ry"})
        self.main:setSchema("gameObjectUse", {"playerIndex", "objectIndex"})

        self.main:on("connect", function(data, client)
            local index = client:getIndex()
            local player = newPlayer(0, 10, 0, 0, index)
            local time = engine.time

            if not client.player then
                engine.players[index] = player
                client.player = player
                client:send("playerNum", {index, client.player, engine.players})
            else
                print("The player is already on the server")
            end
            client:send("setTime", {time})
            client:send("gameObjectsInit", {engine.gameObjects})
        end)

        self.main:on("playerUpdate", function(data)
            local index = data.index
            local x, y, z, ry = data.x, data.y, data.z, data.ry

            for _, client in pairs(self.main:getClients()) do
                if client:getState() == "connected" and index == client:getIndex() then
                    local player = engine.players[index]
                    if player then
                        player.x, player.y, player.z, player.ry = x, y, z, ry
                    end
                    local clientPlayer = client.player
                    if clientPlayer then
                        clientPlayer.x, clientPlayer.y, clientPlayer.z, clientPlayer.ry = x, y, z, ry
                    end
                    break
                end
            end
        end)

        self.main:on("gameObjectsUpdate", function(data, client)
            local clientIndex = client:getIndex()
 
            data.y = math.max(data.y, 10)
        
            for _, otherClient in pairs(self.main:getClients()) do
                if otherClient ~= client and otherClient:getState() == "connected" then
                    otherClient:send("gameObjectsUpdateClients", data)
                end
            end
        end)        

        self.main:on("gameObjectUse", function(data)
            local playerIndex, gameObjectIndex = data.playerIndex, data.objectIndex

            if not engine.players or not engine.players[playerIndex] then return end
            if engine.gameObjects and engine.gameObjects[gameObjectIndex] then
                local player = engine.players[playerIndex]
                local object = engine.gameObjects[gameObjectIndex]
                local x1, y1, z1 = player.x, player.y, player.z
                local x2, y2, z2 = object.x, object.y, object.z
                local dist = distance(x1, y1, z1, x2, y2, z2)

                if dist < 3 then
                    print(4)
                    client:send("gameObjectUseClient", {gameObjectIndex, playerIndex})
                end
            end
        end)
    end,

    update = function(self, dt)
        self.main:update()
        self.TICK = self.TICK + dt

        if self.TICK >= self.TICKRATE then
            self.TICK = 0

            local clients = self.main:getClients()
            if clients then
                local updatedClients = {}

                for index, client in pairs(clients) do
                    if client:getState() == "connected" then
                        local player = client.player
                        if player then
                            local newX, newY, newZ, newRy = player.x, player.y, player.z, player.ry
                            local oldX, oldY, oldZ, oldRy = player.oldX or 0, player.oldY or 0, player.oldZ or 0, player.oldRy or 0

                            local posChanged = newX ~= oldX or newY ~= oldY or newZ ~= oldZ
                            local angleChanged = newRy ~= oldRy

                            if posChanged or angleChanged then
                                updatedClients[index] = {
                                    posChanged = posChanged,
                                    angleChanged = angleChanged,
                                    newX = newX,
                                    newY = newY,
                                    newZ = newZ,
                                    newRy = newRy
                                }

                                player.oldX, player.oldY, player.oldZ, player.oldRy = newX, newY, newZ, newRy
                            end
                        end
                    else
                        engine.players[index] = nil
                    end
                end

                for index, client in pairs(clients) do
                    if client:getState() == "connected" then
                        local updateData = updatedClients[index]
                        if updateData then
                            local newX, newY, newZ, newRy = updateData.newX, updateData.newY, updateData.newZ, updateData.newRy
                            for otherIndex, otherClient in pairs(clients) do
                                if otherIndex ~= index then
                                    if updateData.posChanged or updateData.angleChanged then
                                        sendPlayerState(otherClient, index, newX, newY, newZ, newRy)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
}

return Server