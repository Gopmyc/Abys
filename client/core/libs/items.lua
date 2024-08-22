local Item = {}
Item.__index = Item

function Item.new(image, width, height, rarity)
    local self = setmetatable({}, Item)
    self.image = love.graphics.newImage(image)
    self.width = width
    self.height = height
    self.rarity = rarity
    return self
end

return Item