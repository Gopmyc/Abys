local Class = require("core.libs.class")

local UPDATE_TIMER = 1/60
local timer = 0

local gameObjects = Class{
    init = function(self, index, model, x, y, z, ry, shape)
        if not engine.gameObjects then return end
        if not index then return end

        self.index = index
        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
        self.ry = ry or 0
        self.model = engine.dream:loadObject(tostring("objects/"..model)) or engine.objects.default
        self.object = self.model:instance()
        self.collider = engine.world:add(shape, "dynamic", self.x, self.y, self.z) or engine.world:add(physics:newCapsule(0.1, 0.2, -0.1), "dynamic", self.x, self.y, self.z)
        self.transform = self.object:getTransform()
        self.lastPos = {self.x, self.y, self.z}
        self.lastAngl = self.ry
        self.state = true
        
        if self.collider then
            self.collider:getBody():setLinearDamping(1)
            self.collider:getBody():setAngularDamping(1)
        end
        
        engine.gameObjects[index] = self
    end,

    draw = function(self)  
        local pos = self.collider:getPosition()
        self.object:setTransform(self.transform)

        self.object:translateWorld(pos)
            
        self.object:rotateYWorld(self.collider:getBody():getAngle())
    
        engine.dream:draw(self.object)

        if pos.y < -20 then
            table.remove(engine.gameObjects, self.index)
            self = nil
        end
    end,

    update = function(self, dt)
        body = self.collider:getBody()
        if love.window.hasFocus() then
            if body:isSleepingAllowed() then body:setSleepingAllowed(false) end
            timer = timer + dt
            if timer >= UPDATE_TIMER then
                timer = 0
                local pos = self.collider:getPosition()
                local angl = self.collider:getBody():getAngle()

                if pos[2] <= 0 then
                    self.collider:setPosition(self.x, 5, self.y)
                    return
                end
            
                local roundedX, roundedY, roundedZ, roundedAngl = math.floor(pos[1]), math.floor(pos[2]), math.floor(pos[3]), math.floor(angl)
            
                if roundedAngl ~= self.lastAngl or roundedX ~= self.lastPos[1] or roundedY ~= self.lastPos[2] or roundedZ ~= self.lastPos[3] then
                    self.x, self.y, self.z, self.ry = roundedX, roundedY, roundedZ, roundedAngl
                    self.lastPos[1], self.lastPos[2], self.lastPos[3], self.lastAngl = self.x, self.y, self.z, self.ry
                
                    engine.client:SendToServer("gameObjectsUpdate", {self.index, self.x, self.y, self.z, self.ry})
                end
            end
        else
            body:setSleepingAllowed(true)
        end
    end,            

    use = function(self, user)
        print(user)
        if not user then print("Not a user valid") return end
        print("the gameObjects ["..self.index.."] was use by "..user.INDEX.." !")
    end,
}

return gameObjects