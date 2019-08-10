--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

EntityWalkState = Class{__includes = BaseState}

function EntityWalkState:init(entity, dungeon)
    self.entity = entity
    self.entity:changeAnimation('walk-down')

    self.dungeon = dungeon

    -- used for AI control
    self.moveDuration = 0
    self.movementTimer = 0

    -- keeps track of whether we just hit a wall
    self.bumped = false

    -- An entity can target the player, if so, they will target for numTargetedMoves in a row
    self.numTargetedMoves = 0

    -- There is a timer for how often the player should flash red
    self.targetedFlashTimer = 0

    -- If the color should be red or normal. This property alternates.
    self.targetedFlashColor = true
end

function EntityWalkState:collidedSolidObjects()
    if self.dungeon == nil then 
        return {}
    end

    local collidedObjects = {}

    for k, object in pairs(self.dungeon.currentRoom.objects) do
        if object.solid and self.entity:collides(object) then
            table.insert(collidedObjects, object)
        end
    end
    
    return collidedObjects
end



function EntityWalkState:update(dt)
    

    -- Keep track of location in case we hit a solid object
    local prevX = self.entity.x
    local prevY = self.entity.y
    
    -- assume we didn't hit a wall
    self.bumped = false

    -- boundary checking on all sides, allowing us to avoid collision detection on tiles
    if self.entity.direction == 'left' then
        self.entity.x = self.entity.x - self.entity.walkSpeed * dt
        
        if self.entity.x <= MAP_RENDER_OFFSET_X + TILE_SIZE then 
            self.entity.x = MAP_RENDER_OFFSET_X + TILE_SIZE
            self.bumped = true
        end
    elseif self.entity.direction == 'right' then
        self.entity.x = self.entity.x + self.entity.walkSpeed * dt

        if self.entity.x + self.entity.width >= VIRTUAL_WIDTH - TILE_SIZE * 2 then
            self.entity.x = VIRTUAL_WIDTH - TILE_SIZE * 2 - self.entity.width
            self.bumped = true
        end
    elseif self.entity.direction == 'up' then
        self.entity.y = self.entity.y - self.entity.walkSpeed * dt

        if self.entity.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - self.entity.height / 2 then 
            self.entity.y = MAP_RENDER_OFFSET_Y + TILE_SIZE - self.entity.height / 2
            self.bumped = true
        end
    elseif self.entity.direction == 'down' then
        self.entity.y = self.entity.y + self.entity.walkSpeed * dt

        local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) 
            + MAP_RENDER_OFFSET_Y - TILE_SIZE

        if self.entity.y + self.entity.height >= bottomEdge then
            self.entity.y = bottomEdge - self.entity.height
            self.bumped = true
        end
    end

    local collidedSolidObjects = self:collidedSolidObjects()
    if #collidedSolidObjects > 0 then
        print('colliding')
        self.entity.x = prevX
        self.entity.y = prevY
        self.bumped = true
    
        for k, object in pairs(collidedSolidObjects) do
            self.entity:changeState('idle')
            object.onCollide()
        end
    end
end


function EntityWalkState:targetPlayerMove(player)
    local moves = {}
    local horizontalMove = self.entity.x < player.x 
        and { direction = 'right', duration = math.abs(self.entity.x - player.x) / self.entity.walkSpeed }
        or { direction = 'left', duration = math.abs(self.entity.x - player.x) / self.entity.walkSpeed }
    local verticalMove = self.entity.y < player.y
        and { direction = 'down', duration = math.abs(self.entity.y - player.y) / self.entity.walkSpeed }
        or { direction = 'up', duration = math.abs(self.entity.y - player.y) / self.entity.walkSpeed }
    
    local move = horizontalMove.duration > verticalMove.duration and horizontalMove or verticalMove
    self.entity.direction = move.direction
    self.moveDuration = math.random(math.floor(move.duration))
    self.entity:changeAnimation('walk-' .. tostring(self.entity.direction))
    self.numTargetedMoves = self.numTargetedMoves - 1

    if self.numTargetedMoves <= 0 then
        self.entity.walkSpeed = self.entity.walkSpeed / 1.5
    end
end

function EntityWalkState:processAI(params, dt)
    if self.numTargetedMoves > 0 then
        self.targetedFlashTimer = self.targetedFlashTimer + dt
    else
        self.targetedFlashTimer = 0
    end

    local room = params.room
    local player = params.player
    local directions = {'left', 'right', 'up', 'down'}

    if self.moveDuration == 0 or self.bumped then
        
        -- set an initial move duration and direction
        self.moveDuration = math.random(5)
        self.entity.direction = directions[math.random(#directions)]
        self.entity:changeAnimation('walk-' .. tostring(self.entity.direction))
    elseif self.movementTimer > self.moveDuration then
        self.movementTimer = 0

        -- chance to go idle
        local rand = math.random(5)
        if self.numTargetedMoves > 0 then
            self:targetPlayerMove(player)
        elseif rand == 1 then
            self.entity:changeState('idle')
        elseif rand <= 3 then
            self.numTargetedMoves = math.random(5)
            self.entity.walkSpeed = self.entity.walkSpeed * 1.5
            self:targetPlayerMove(player)
        else
            self.entity.direction = directions[math.random(#directions)]
            self.moveDuration = math.random(5)
            self.entity:changeAnimation('walk-' .. tostring(self.entity.direction))
        end
    end

    self.movementTimer = self.movementTimer + dt
end

function EntityWalkState:render()
    local anim = self.entity.currentAnimation
    if self.numTargetedMoves > 0 then
        if self.targetedFlashTimer < 1 then
            if self.targetedFlashColor then 
                love.graphics.setColor(255, 0, 0, 192)  
            end
        else 
            self.targetedFlashTimer = 0
            self.targetedFlashColor = not self.targetedFlashColor
        end
        
    end

    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.entity.x - self.entity.offsetX), math.floor(self.entity.y - self.entity.offsetY))
    
    -- debug code
    -- love.graphics.setColor(255, 0, 255, 255)
    -- love.graphics.rectangle('line', self.entity.x, self.entity.y, self.entity.width, self.entity.height)
    -- love.graphics.setColor(255, 255, 255, 255)
end