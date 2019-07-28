--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GameObject = Class{}

function GameObject:init(def, x, y)
    
    -- string identifying this object type
    self.type = def.type

    self.texture = def.texture
    self.frame = def.frame or 1

    -- whether it acts as an obstacle or not
    self.solid = def.solid

    self.defaultState = def.defaultState
    self.state = self.defaultState
    self.states = def.states

    -- dimensions
    self.x = x
    self.y = y
    self.width = def.width
    self.height = def.height

    -- default empty collision callback
    self.onCollide = function() end

    -- projectile
    self.projectile = def.projectile or false
    self.maxProjectileDistance = def.maxProjectileDistance or TILE_SIZE * 4
    self.dx = def.dx or 0
    self.dy = def.dy or 0
    self.distanceTravelled = 0

    self.dead = false
end

function GameObject:isInBounds()
    local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) 
            + MAP_RENDER_OFFSET_Y - TILE_SIZE

    local inBoundsLeft = self.x > MAP_RENDER_OFFSET_X + TILE_SIZE
    local inBoundsRight = self.x + self.width < VIRTUAL_WIDTH - TILE_SIZE * 2
    local inBoundsTop = self.y > MAP_RENDER_OFFSET_Y + TILE_SIZE - self.height / 2
    local inBoundsBottom = self.y + self.height < bottomEdge
    return inBoundsLeft and inBoundsRight and inBoundsTop and inBoundsBottom
end

function GameObject:isProjectileTooFar()
    return self.distanceTravelled > self.maxProjectileDistance
end

function GameObject:update(dt)
    if self.projectile then 
        self.x = self.x + self.dx * dt
        self.y = self.y + self.dy * dt
        self.distanceTravelled = self.distanceTravelled + math.abs(self.dx * dt) + math.abs(self.dy * dt)
    end
end

function GameObject:render(adjacentOffsetX, adjacentOffsetY)
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.states[self.state].frame or self.frame],
        self.x + adjacentOffsetX, self.y + adjacentOffsetY)
end