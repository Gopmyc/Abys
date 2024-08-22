local Class = require("core/libs/class")

local Players = Class{
    init = function(self, x, y, z, ry, shape, model)
        if not shape then return end
        local model = model or engine.objects.player

        self.x = x or 0
        self.y = y or 0
        self.z = z or 0
        self.ry = ry or 0
        self.object = model:instance() or nil
        self.collider = engine.world:add(shape, "dynamic", self.x, self.y, self.z) or nil
        self.transform = model:getTransform()
    end,

    draw = function(self)
        if self.object then 
            local pos = self.collider:getPosition()
            self.object:setTransform(self.transform)
            self.object:translateWorld(pos - engine.dream.vec3(0, 0.5, 0))
            self.object:rotateY(self.ry)
            engine.dream:draw(self.object)
        end
    end,

    update = function(self, dt)  
        if self.collider then
            self.collider:setPosition(self.x, self.y, self.z) 
        end
    end
}

return Players