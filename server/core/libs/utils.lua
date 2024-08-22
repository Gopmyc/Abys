local utils = {
    filesystem = { },
    table = { },
    string = { },
    math = { },
    usedIndexes = {},
}

function utils.table.printTable(tbl, indent)
    indent = indent or 0
    local formattedString = ""

    for key, value in pairs(table) do
        if type(value) == "table" then
            formattedString = formattedString .. string.rep("  ", indent) .. key .. ":\n"
            formattedString = formattedString .. utils.table.printTable(value, indent + 1)
        else
            formattedString = formattedString .. string.rep("  ", indent) .. key .. ": " .. tostring(value) .. "\n"
        end
    end

    print(formattedString)
end

function utils.table.generateUniqueIndex()
    local index = math.random(1, 1000)

    while utils.usedIndexes[index] do
        index = math.random(1, 1000)
    end

    utils.usedIndexes[index] = true

    return index
end

function utils.table.IsIn(element, tbl)
    for _, value in ipairs(tbl) do
        if value == element then
            return true
        end
    end
    return false
end

for _, s in ipairs({ "table", "string", "math" }) do
    setmetatable(_G[s], { __index = utils[s] })
end

return utils
