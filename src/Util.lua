--[[
    GD50
    Legend of Zelda

    Util Class

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

--[[
    Given an "atlas" (a texture with multiple sprites), as well as a
    width and a height for the tiles therein, split the texture into
    all of the quads by simply dividing it evenly.
]]
function GenerateQuads(atlas, tilewidth, tileheight)
    local sheetWidth = atlas:getWidth() / tilewidth
    local sheetHeight = atlas:getHeight() / tileheight

    local sheetCounter = 1
    local spritesheet = {}

    for y = 0, sheetHeight - 1 do
        for x = 0, sheetWidth - 1 do
            spritesheet[sheetCounter] =
                love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth,
                tileheight, atlas:getDimensions())
            sheetCounter = sheetCounter + 1
        end
    end

    return spritesheet
end

--[[
    Recursive table printing function.
    https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
]]
function print_r ( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end


-- Get index from table function heavily based on:
-- https://stackoverflow.com/a/52922737
local function getIndex(tab, value)
    local index = nil
    for i, v in ipairs (tab) do 
        if (v == value) then
          index = i 
        end
    end
    return index
end

-- Remove element from table function heavily based on:
-- https://stackoverflow.com/a/52922737
function removeFromTable(tab, value)
    local idx = getIndex(tab, value)
    if idx == nil then 
        print("Key does not exist")
    else
        table.remove(tab, idx)
    end
end

function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function tableContainsValue(tab, value)
    return getIndex(tab, value) ~= nil
end

function round(value) 
    return math.floor(value + 0.5)
end