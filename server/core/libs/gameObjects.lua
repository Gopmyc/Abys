local utils = require("core.libs.utils")
local Class = require("libs.class")

GameObjects = Class{
    init = function(self, pos, ang, name)
        local index = utils.generateUniqueIndex()
        self[index] = {
            pos = pos or {0, 0},
            ang = ang or 0,
            name = name or "Unassigned["..index.."]"
        }

        --- POUR CLIENT ---
        --self.sprite = 
        --self.collider = 
    end,

    getVar = function(self, index)
        return setmetatable({}, {
            __index = function(table, key)
                return self[index][key]
            end,
            __newindex = function(table, key, value)
                self[index][key] = value
            end
        })
    end,

    getIndexByName = function(self, name)
        for index, object in pairs(self) do
            if object.name == name then
                return index
            end
        end
        return nil
    end,

    getNameByIndex = function(self, index)
        return self[index] and self[index].name or nil
    end
}

return GameObjects
