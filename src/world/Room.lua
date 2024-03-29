--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Room = Class{}

function Room:init(player)
    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT

    -- reference to player for collisions, etc.
    self.player = player

    self.tiles = {}
    self:generateWallsAndFloors()

    -- entities in the room
    self.entities = {}
    self:generateEntities()

    -- game objects in the room
    self.objects = {}
    self:generateObjects()

    -- doorways that lead to other dungeon rooms
    self.doorways = {}
    table.insert(self.doorways, Doorway('top', false, self))
    table.insert(self.doorways, Doorway('bottom', false, self))
    table.insert(self.doorways, Doorway('left', false, self))
    table.insert(self.doorways, Doorway('right', false, self))

    

    -- used for centering the dungeon rendering
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y

    -- used for drawing when this room is the next room, adjacent to the active
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0
end

function Room:getTypesFor(level, expRemaining)
    local types = {}
    for type, entityDef in pairs(ENTITY_DEFS) do
        print_r(type)
        print_r(entityDef)

        if entityDef['firstLevel'] and entityDef['firstLevel'] <= level and entityDef['expReward'] <= expRemaining then
            table.insert(types, type)
        end

    end

    if #types == 0 then
        table.insert(types, 'slime')
    end
    return types
end

--[[
    Randomly creates an assortment of enemies for the player to fight.
]]
function Room:generateEntities()

    
    local EXPERIENCE_PERCENT = 0.65
    local minimumExpToGenerate = math.ceil(EXPERIENCE_PERCENT * self.player.expToLevel)
    local expGenerated = 0
    local i = 1

    while expGenerated < minimumExpToGenerate do
        local types = self:getTypesFor(self.player:getLevel(), minimumExpToGenerate - expGenerated)
        local type = types[math.random(#types)]
        local entityDef = ENTITY_DEFS[type]
        local entity = Entity {
            animations = entityDef.animations,
            walkSpeed = entityDef.walkSpeed or 20,

            -- ensure X and Y are within bounds of the map
            x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
            y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16),
            
            width = 16,
            height = 16,

            baseHealth = entityDef.baseHealth or 1,
            baseAttack = entityDef.baseAttack or 1,
            baseDefense = entityDef.baseDefense or 0,
            expReward = entityDef.expReward or 1,
            hasHealthbar = entityDef.hasHealthbar,
            minimumDamageInflicted = entityDef.minimumDamageInflicted or 0,
        }

        table.insert(self.entities, entity)

        entity.stateMachine = StateMachine {
            ['walk'] = function() return EntityWalkState(entity) end,
            ['idle'] = function() return EntityIdleState(entity) end
        }

        entity:changeState('walk')
        expGenerated = expGenerated + entityDef.expReward 
        i = i + 1
    end
end

--[[
    Creates a switch in a random location.
]]
function Room:generateSwitch()
    local switch = GameObject(
        GAME_OBJECT_DEFS['switch'],
        math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                    VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
        math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
    )

    -- define a function for the switch that will open all doors in the room
    switch.onCollide = function()
        if switch.state == 'unpressed' then
            switch.state = 'pressed'
            
            -- open every door in the room if we press the switch
            for k, doorway in pairs(self.doorways) do
                doorway.open = true
            end

            gSounds['door']:play()
        end
    end

    -- add to list of objects in scene (only one switch for now)
    table.insert(self.objects, switch)
end

--[[
    Randomly creates an assortment of obstacles for the player to navigate around.
]]
function Room:generateObjects()
    self:generateSwitch()
    self:generatePots()
end

--[[
    Create pots in a random location.
]]
function Room:generatePots()
    local randomNumberOfPots = math.random(1, 4)
    for i = 1, randomNumberOfPots do
        local pot = GameObject(
            GAME_OBJECT_DEFS['pot'],
            math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                        VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
            math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                        VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
        )

        -- TODO: Can I delete?
        pot.onCollide = function()   
        end

        table.insert(self.objects, pot)
    end
end


--[[
    Generates the walls and floors of the room, randomizing the various varieties
    of said tiles for visual variety.
]]
function Room:generateWallsAndFloors()
    for y = 1, self.height do
        table.insert(self.tiles, {})

        for x = 1, self.width do
            local id = TILE_EMPTY

            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER
            
            -- random left-hand walls, right walls, top, bottom, and floors
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
            else
                id = TILE_FLOORS[math.random(#TILE_FLOORS)]
            end
            
            table.insert(self.tiles[y], {
                id = id
            })
        end
    end
end

function Room:levelUp()
    local remainingExp = self.player.exp - self.player.expToLevel
    -- 1.25 more exp needed to level, rounded to the nearest multiple of 5
    local nextExpToLevel = 5 * (round((self.player.expToLevel * 1.25) / 5))
    gStateMachine:change('level-up', {
        attackLevel = self.player.attackLevel,
        defenseLevel = self.player.defenseLevel,
        healthLevel = self.player.healthLevel,
        exp = remainingExp,
        expToLevel = nextExpToLevel
    })
end

function Room:playerKilled(entity)
    self:generateHeartsAround(entity)
    
    self.player.exp = self.player.exp + entity.expReward
    if self.player.exp >= self.player.expToLevel then 
        self:levelUp()
    end
end

function Room:update(dt)
    
    -- don't update anything if we are sliding to another room (we have offsets)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)

    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        -- remove entity from the table if health is <= 0
        if entity.health <= 0 then
            -- if the entity is going to die
            if not entity.dead then
                self:playerKilled(entity)
            end
            entity.dead = true
            
        elseif not entity.dead then
            entity:processAI({room = self, player = self.player}, dt)
            entity:update(dt)
        end

        -- collision between the player and entities in the room
        if not entity.dead and self.player:collides(entity) and not self.player.invulnerable then
            if self.player:canDamage(entity.baseAttack) then 
                gSounds['hit-player']:play()
            else
                gSounds['ooof']:play()
            end
            
            self.player:damage(entity.baseAttack)
            self.player:goInvulnerable(1.5)

            if self.player.health == 0 then
                gStateMachine:change('game-over')
            end
        end
    end

    for k, object in pairs(self.objects) do
        object:update(dt)

        -- trigger collision callback on object
        if self.player:collides(object) then
            object:onCollide()
        end
    end

    self:removePots()
end

function Room:removePots()
    local potsToRemove = {}
    for k, object in pairs(self.objects) do
        if object.type == "pot" and object.projectile then
            local pot = object
            local collidedEntity = self:collidedEntity(pot)

            if pot:isProjectileTooFar() then
                print("Travelled too far")
                table.insert(potsToRemove, pot)
                gSounds['hit-enemy']:play()
            elseif not pot:isInBounds() then
                print("Not in bounds")
                table.insert(potsToRemove, pot)
                gSounds['hit-enemy']:play()
            elseif collidedEntity ~= nil then 
                print("Collided enemy")
                local attack = self.player.baseAttack + (self.player.attackLevel - 1)
                collidedEntity:damage(attack)
                table.insert(potsToRemove, pot)

                if collidedEntity:canDamage(attack) then 
                    gSounds['hit-enemy']:play()
                else
                    gSounds['ooof']:play()
                end
            end
        end
    end

    for k, pot in pairs(potsToRemove) do
        removeFromTable(self.objects, pot)
    end
end

function Room:collidedEntity(obj)
    for k, e in pairs(self.entities) do
        if obj ~= e and e:collides(obj) then
            return e
        end
    end
end

function Room:generateHeartXAround(entity)
    local MIN_HEART_X = MAP_RENDER_OFFSET_X + TILE_SIZE
    local MAX_HEART_X = VIRTUAL_WIDTH - TILE_SIZE * 2 - 16
    local x = entity.x + math.random(-TILE_SIZE, TILE_SIZE)
    return clamp(x, MIN_HEART_X, MAX_HEART_X)
end

function Room:generateHeartYAround(entity)
    local MIN_HEART_Y = MAP_RENDER_OFFSET_Y + TILE_SIZE
    local MAX_HEART_Y = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16
    local y = entity.y + math.random(-TILE_SIZE, TILE_SIZE)
    return clamp(y, MIN_HEART_Y, MAX_HEART_Y)
end

function Room:generateHeartsAround(entity)
    print("Deadddddd")


    -- Generate up to 3 hearts
     for i = 1, 3 do
        -- A 16% chance for each heart
        if math.random(1, 6) == 1 then 
            local heart = GameObject(
                GAME_OBJECT_DEFS['heart'],
                self:generateHeartXAround(entity),
                self:generateHeartYAround(entity)
            )

            -- Keep generating x && y pairs until the heart doesnt collide with the player
            -- FIXME: We can still generate a heart that is instantly collided with... 
            -- 1. I'm not sure if there is a bug with the `collides`
            -- 2. Or possibly we need to check which direction the player is walking in
            while self.player:collides(entity) do
                entity.x = self:generateHeartXAround(entity)
                entity.y = self:generateHeartYAround(entity)
            end
    
            heart.onCollide = function()
                gSounds['pickup']:play()
                self.player:setHealth(self.player.health + 2)
                removeFromTable(self.objects, heart)
            end
            
            table.insert(self.objects, heart)
        end
    end
end 

function Room:render()
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX, 
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
        end
    end

    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly
    for k, doorway in pairs(self.doorways) do
        doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, object in pairs(self.objects) do
        object:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, entity in pairs(self.entities) do
        if not entity.dead then entity:render(self.adjacentOffsetX, self.adjacentOffsetY) end
    end

    -- stencil out the door arches so it looks like the player is going through
    love.graphics.stencil(function()
        
        -- left
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- right
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- top
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        
        --bottom
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)
    
    if self.player then
        self.player:render()
    end

    love.graphics.setStencilTest()

    --
    -- DEBUG DRAWING OF STENCIL RECTANGLES
    --

    -- love.graphics.setColor(255, 0, 0, 100)
    
    -- -- left
    -- love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
    -- TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- right
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
    --     MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- top
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

    -- --bottom
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    
    -- love.graphics.setColor(255, 255, 255, 255)
end