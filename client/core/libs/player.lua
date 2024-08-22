local Class = require("core/libs/class")

local DEFAULT_SPEED = 200
local USE_KEY = "f"
local USE_KEY_PRESSED = false
local UPDATE_TIME = 1/120
local timer = 0

local function updateMovement(self, dt)
    local timer = timer + dt
    local player = self.collider
    local pos = player:getPosition()
    if player then
        local d = love.keyboard.isDown
        local ax, az = 0, 0
        self.ry = engine.camera.ry or 0
        if d("z") then ax, az = ax + math.cos(self.ry - math.pi / 2), az + math.sin(self.ry - math.pi / 2) end
        if d("s") then ax, az = ax + math.cos(self.ry + math.pi - math.pi / 2), az + math.sin(self.ry + math.pi - math.pi / 2) end
        if d("q") then ax, az = ax + math.cos(self.ry - math.pi / 2 - math.pi / 2), az + math.sin(self.ry - math.pi / 2 - math.pi / 2) end
        if d("d") then ax, az = ax + math.cos(self.ry + math.pi / 2 - math.pi / 2), az + math.sin(self.ry + math.pi / 2 - math.pi / 2) end
        local a = math.sqrt(ax ^ 2 + az ^ 2)
        if a > 0 then
            local v = player:getVelocity()
            ax, az = ax / a, az / a
            local speed = engine.dream.vec3(v.x, 0, v.z):length()
            local maxSpeed = d("a") and 1000 or 200
            local dot = speed > 0 and (ax * v.x / speed + az * v.z / speed) or 0
            local accel = 16000 * math.max(0, 1 - speed / maxSpeed * math.abs(dot))
            local forceFactor = player.touchedFloor and 1 or 0.05
            player:applyForce(ax * accel * forceFactor, 0, az * accel * forceFactor)
        end

        pos = player:getPosition()

        if timer >= UPDATE_TIME then
            timer = 0
            if self.ry ~= self.lastAngl or pos[1] ~= self.lastPos[1] or pos[2] ~= self.lastPos[2] or pos[3] ~= self.lastPos[3] then
                self.lastAngl = self.ry
                self.lastPos[1], self.lastPos[2], self.lastPos[3] = pos[1], pos[2], pos[3]
                engine.client:SendToServer("playerUpdate", {self.INDEX, pos[1], pos[2], pos[3], self.ry})
            end
        end
    end
end

local function updateJump(self, dt)
    local player = self.collider
    if player and player.touchedFloor and love.keyboard.isDown("space") then
        player.vy = 6
    end
end

local function updateResetPosition(self, dt)
    local player = self.collider
    if player and player:getPosition()[2] < -20 then
        player:setPosition(0, 10, 0)
    end
end

local function useObject(self, dt)
    local key = love.keyboard.isDown
    if key(USE_KEY) and not USE_KEY_PRESSED then
        USE_KEY_PRESSED = true
        local playerPos = self.collider:getPosition()
        local forwardVector = self:getForward()

        for k, gameObject in pairs(engine.gameObjects) do
            local gameObjectPos = gameObject.collider:getPosition()
            local direction = engine.dream.vec3(gameObjectPos[1] - playerPos[1], 0, gameObjectPos[3] - playerPos[3]):normalize()
            local dotProduct = forwardVector:dot(direction)
            local distance = engine.dream.vec3(gameObjectPos[1] - playerPos[1], 0, gameObjectPos[3] - playerPos[3]):length()

            if dotProduct > 0.9 and distance < 3 then
                engine.client:SendToServer("gameObjectUse", {self.INDEX, k})
            end
        end
    elseif not key(USE_KEY) then
        USE_KEY_PRESSED = false
    end
end

local Player = Class{
    init = function(self, x, y, z, ry, shape, speed, model)
        if not shape then return end

        local model = model or engine.objects.player

        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
        self.ry = ry or 0
        self.object = model:instance() or nil
        self.transform = model:getTransform()
        self.speed = speed or DEFAULT_SPEED
        self.collider = engine.world:add(shape, "dynamic", self.x, self.y, self.z) or nil
        self.transform = self.object:getTransform()
        self.INDEX = engine.client.INDEX
        self.lastPos = {self.x, self.y, self.z}
        self.lastAngl = self.ry
    end,

    draw = function(self)
        if self.collider then
            local pos = self.collider:getPosition()
            local forwardVector = self:getForward()
            local cameraOffset = engine.dream.vec3(0, 1, 0) + forwardVector * 0.4
            engine.camera:lookAt(engine.dream.camera, pos + cameraOffset, 5)

            if self.object then 
                self.object:setTransform(self.transform)
                self.object:translateWorld(pos - engine.dream.vec3(0, 0.5, 0))
                engine.dream:draw(self.object)
            end
        end
    end,    

    getForward = function(self)
        return engine.dream.vec3(math.cos(self.ry - math.pi / 2), 0, math.sin(self.ry - math.pi / 2))
    end,

    update = function(self, dt)
        local body = self.collider:getBody()
        if love.window.hasFocus() then
            if body:isSleepingAllowed() then body:setSleepingAllowed(false) end
            useObject(self, dt)
            updateMovement(self, dt)
            updateJump(self, dt)
            updateResetPosition(self, dt)
        else
            body:setSleepingAllowed(true)
        end
    end
}

return Player