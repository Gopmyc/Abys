local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(width, height)
    local self = setmetatable({}, Inventory)
    self.width = width
    self.height = height
    self.items = {}
    return self
end

function Inventory:addItem(item)
    local availableSlots = self:findAvailableSlots(item.width, item.height)
    if availableSlots then
        table.insert(self.items, {item = item, slots = availableSlots})
        return true
    else
        return false
    end
end

function Inventory:removeItem(item)
    for i, entry in ipairs(self.items) do
        if entry.item == item then
            table.remove(self.items, i)
            return true
        end
    end
    return false
end

function Inventory:findAvailableSlots(width, height)
    local availableSlots = {}
    for y = 1, self.height - height + 1 do
        for x = 1, self.width - width + 1 do
            local empty = true
            for h = 0, height - 1 do
                for w = 0, width - 1 do
                    if self:isOccupied(x + w, y + h) then
                        empty = false
                        break
                    end
                end
                if not empty then
                    break
                end
            end
            if empty then
                table.insert(availableSlots, {x = x, y = y})
            end
        end
    end
    if #availableSlots > 0 then
        return availableSlots
    else
        return nil
    end
end

function Inventory:isOccupied(x, y)
    for _, entry in ipairs(self.items) do
        for _, slot in ipairs(entry.slots) do
            if x >= slot.x and x <= slot.x + entry.item.width - 1 and
               y >= slot.y and y <= slot.y + entry.item.height - 1 then
                return true
            end
        end
    end
    return false
end

return Inventory