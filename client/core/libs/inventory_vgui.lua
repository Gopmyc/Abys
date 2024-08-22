-- inventory_vgui.lua

local InventoryVGUI = {}
InventoryVGUI.__index = InventoryVGUI

function InventoryVGUI.new(inventory)
    local self = setmetatable({}, InventoryVGUI)
    self.inventory = inventory
    self.itemSize = 32 -- Taille d'une case dans l'inventaire (en pixels)
    self.isVisible = false
    self.selectedItem = nil
    self.mouseOffset = {x = 0, y = 0}

    return self
end

function InventoryVGUI:draw()
    if not self.isVisible then
        return
    end

    for y = 1, self.inventory.height do
        for x = 1, self.inventory.width do
            love.graphics.rectangle("line", (x - 1) * self.itemSize, (y - 1) * self.itemSize, self.itemSize, self.itemSize)
        end
    end

    self:drawItems()
end

function InventoryVGUI:drawItems()
    for _, entry in ipairs(self.inventory.items) do
        local itemWidth = entry.item.width * self.itemSize
        local itemHeight = entry.item.height * self.itemSize
        love.graphics.draw(entry.item.image, (entry.slots[1].x - 1) * self.itemSize, (entry.slots[1].y - 1) * self.itemSize, 0, itemWidth / entry.item.image:getWidth(), itemHeight / entry.item.image:getHeight())
    end
end

function InventoryVGUI:update(dt)
    if love.keyboard.isDown("i") then
        self.isVisible = not self.isVisible
    end

    if self.isVisible then
        self:handleItemDrag()
        self:handleRotate()
    end
end

function InventoryVGUI:handleItemDrag()
    if love.mouse.isDown(1) and self.selectedItem == nil then
        local mouseX, mouseY = love.mouse.getPosition()
        for _, entry in ipairs(self.inventory.items) do
            local itemX = (entry.slots[1].x - 1) * self.itemSize
            local itemY = (entry.slots[1].y - 1) * self.itemSize
            local itemWidth = entry.item.width * self.itemSize
            local itemHeight = entry.item.height * self.itemSize
            if mouseX >= itemX and mouseX <= itemX + itemWidth and mouseY >= itemY and mouseY <= itemY + itemHeight then
                self.selectedItem = entry
                self.mouseOffset.x = mouseX - itemX
                self.mouseOffset.y = mouseY - itemY
                break
            end
        end
    elseif love.mouse.isDown(1) and self.selectedItem ~= nil then
        local mouseX, mouseY = love.mouse.getPosition()
        self.selectedItem.slots[1].x = math.floor((mouseX - self.mouseOffset.x) / self.itemSize) + 1
        self.selectedItem.slots[1].y = math.floor((mouseY - self.mouseOffset.y) / self.itemSize) + 1
    elseif not love.mouse.isDown(1) then
        self.selectedItem = nil
    end
end

function InventoryVGUI:handleRotate()
    if love.keyboard.isDown("r") and self.selectedItem ~= nil then
        local temp = self.selectedItem.item.width
        self.selectedItem.item.width = self.selectedItem.item.height
        self.selectedItem.item.height = temp
    end
end

function InventoryVGUI:setPos(x, y)
    self.x, self.y = x, y
end

function InventoryVGUI:getPos()
    return self.x, self.y
end

return InventoryVGUI