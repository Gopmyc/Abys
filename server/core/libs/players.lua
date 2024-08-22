local Player = {}

local DEFAULT_SPEED = 200
local DEFAULT_X = 200
local DEFAULT_Y = 200
local DEFAULT_WIDTH = 50
local DEFAULT_HEIGHT = 50

function Player:new()
    local newObj = {x = DEFAULT_X, y = DEFAULT_Y, width = DEFAULT_WIDTH, heigth = DEFAULT_HEIGHT, speed = DEFAULT_SPEED}
    self.__index = self
    return setmetatable(newObj, self)
end

return Player
