--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayState = Class{__includes = BaseState}
FULL_HEART_FRAME = 5
HALF_HEART_FRAME = 3
EMPTY_HEART_FRAME = 1

function PlayState:init()
    local playerDef = ENTITY_DEFS['player']
    
    self.player = Player {
        animations = playerDef.animations,
        walkSpeed = playerDef.walkSpeed,
        baseAttack = playerDef.baseAttack,
        baseDefense = playerDef.baseDefense,
        attackLevel = 1,
        defenseLevel = 1,
        healthLevel = 1,
        exp = 0,
        expToLevel = 10,
        
        x = VIRTUAL_WIDTH / 2 - 8,
        y = VIRTUAL_HEIGHT / 2 - 11,
        
        width = 16,
        height = 22,

        -- one heart == 2 health
        health = PLAYER_BASE_MAX_HEALTH,

        -- rendering and collision offset for spaced sprites
        offsetY = 5
    }

    self.dungeon = Dungeon(self.player)
    self.currentRoom = Room(self.player)
    
    self.player.stateMachine = StateMachine {
        ['walk'] = function() return PlayerWalkState(self.player, self.dungeon) end,
        ['idle'] = function() return PlayerIdleState(self.player, self.dungeon) end,
        ['swing-sword'] = function() return PlayerSwingSwordState(self.player, self.dungeon) end,
        ['pot-lift'] = function() return PlayerPotLiftState(self.player, self.dungeon) end,
        ['pot-walk'] = function() return PlayerPotWalkState(self.player, self.dungeon) end,
        ['pot-idle'] = function() return PlayerPotIdleState(self.player, self.dungeon) end
    }
    self.player:changeState('idle')
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    self.dungeon:update(dt)
end

function PlayState:render()
    -- render dungeon and all entities separate from hearts GUI
    love.graphics.push()
    self.dungeon:render()
    love.graphics.pop()

    -- draw player hearts, top of screen
    local healthLeft = self.player.health
    local heartFrame = EMPTY_HEART_FRAME
    
    local numHearts = 3 + (self.player.healthLevel - 1)
    for i = 1, numHearts do
        if healthLeft > 1 then
            heartFrame = FULL_HEART_FRAME
        elseif healthLeft == 1 then
            heartFrame = HALF_HEART_FRAME
        else
            heartFrame = EMPTY_HEART_FRAME
        end

        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][heartFrame],
            (i - 1) * (TILE_SIZE + 1), 2)
        
        healthLeft = healthLeft - 2
    end

    -- draw attack & defense
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('ATK-', VIRTUAL_WIDTH - 100, 2, 25, 'left')
    love.graphics.printf(self.player.attackLevel, VIRTUAL_WIDTH - 100, 2, 25, 'right')

    love.graphics.printf('DEF-', VIRTUAL_WIDTH - 100, 11, 25, 'left')
    love.graphics.printf(self.player.defenseLevel, VIRTUAL_WIDTH - 100, 11, 25, 'right')

    love.graphics.printf('NEXT LEVEL', VIRTUAL_WIDTH - 60, 2, 55, 'center')
    love.graphics.printf(self.player.exp .. ' / ' .. self.player.expToLevel, VIRTUAL_WIDTH - 60, 11, 55, 'center')
end