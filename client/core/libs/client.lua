local utils = require("core/libs/utils")
local Class = require("core/libs/class")
local sock = require("libs/sock")
local bitser = require("libs/spec/bitser")
local Player = require("core/libs/player")
local Players = require("core/libs/players")
local GameObjects = require("core/libs/gameObjects")

local CLIENT_IP = "localhost" --"localhost"
local CLIENT_PORT = 22122 -- 22122

Client = Class{
    init = function(self, IP, PORT, TICKRATE, NAME)
        self.IP = IP or CLIENT_IP
        self.PORT = PORT or CLIENT_PORT
        self.NAME = NAME or "Unassigned"
        self.TICKRATE = 1/60
        self.TICK = 0
        self.main = sock.newClient(self.IP, self.PORT)
        self.INDEX = 0

        self.main:setSerialization(bitser.dumps, bitser.loads)
        self.main:enableCompression()
    end,

    load = function(self)
        self.main:setSchema("playersState", {"index", "x", "y", "z", "ry"})
        self.main:setSchema("playerNum", {"index", "player", "players"})
        self.main:setSchema("setTime", {"time"})
        self.main:setSchema("gameObjectsInit", {"gameObjects"})
        self.main:setSchema("gameObjectsUpdateClients", {"index", "x", "y", "z", "ry"})
        self.main:setSchema("gameObjectUseClient", {"index1", "index2"})

        self.main:on("playerNum", function(data)
            local index = data.index
            local player = data.player
            local players = data.players

            self.INDEX = index
            engine.players[index] = Player(player.x, player.y, player.z, player.ry, engine.physics:newCapsule(0.5, 0.5, -0.5))

            for k, v in pairs(players) do
                if k ~= index then
                    engine.players[k] = Players(v.x, v.y, v.z, v.ry, engine.physics:newCapsule(0.5, 1.5, -1.5))
                end
            end
        end)

        self.main:on("setTime", function(data)
            local time = data.time

            if time and engine.sky and engine.sun then
                engine.sky:setDaytime(engine.sun, time)
            end
        end)

        self.main:on("gameObjectsInit", function(data)
            local gameObjects = data.gameObjects

            --for k, v in pairs(gameObjects) do
            --    GameObjects(k, v.model, v.x, v.y, v.z, v.ry, engine.physics:newCapsule(v.shape[1], v.shape[2], v.shape[3]))
            --end
        end)

        self.main:on("gameObjectsUpdateClients", function(data)
            local index, x, y, z, ry = data.index, data.x, data.y, data.z, data.ry

            if engine.gameObjects[index] then
                local collider = engine.gameObjects[index].collider

                collider:setPosition(x, y, z)
                collider:getBody():setAngle(ry)
            end
        end)

        self.main:on("playersState", function(data)
            local index = data.index
            local x = data.x
            local y = data.y
            local z = data.z
            local ry = data.ry
    
            if engine.players[index] then
                if index ~= self.INDEX then
                    engine.players[index].x, engine.players[index].y, engine.players[index].z = x, y, z 
                    engine.players[index].ry = ry
                end
            else
                engine.players[index] = Players(x, y, z, ry, engine.physics:newCapsule(0.5, 1.5, -1.5))
            end
        end)

        self.main:on("gameObjectUseClient", function(data)
            local index1, index2 = data.index1, data.index2

            print(index2)

            if not engine.players or not engine.players[index2] then return end
            if index and engine.gameObject and engine.gameObject[index] then
                engine.gameObject[index]:use(engine.gameObject[index], engine.players[index2])
            end
        end)

        self.main:connect()
    end,

    update = function(self, dt, funct)
        self.main:update()

        if self.main:getState() == "connected" then
            self.TICK = self.TICK + dt
        end
    end,

    everyTick = function(self, funct)
        if self.TICK >= self.TICKRATE then
            self.TICK = 0
            funct()
        end
    end,

    SendToServer = function(self, identifiant, packages)
        if type(packages) ~= "table" then print("The data packet sent does not have the correct structure (it is not a table)") return end
        if love.window.hasFocus() then
            self.main:send(identifiant, packages)
        end
    end,
}

return Client
