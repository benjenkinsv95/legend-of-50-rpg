--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerPotIdleState = Class{__includes = EntityIdleState}

function PlayerPotIdleState:enter(params)
    print("Entering pot idle state")

    self.entity:changeAnimation('pot-idle-' .. self.entity.direction)
    -- render offset for spaced character sprite (negated in render function of state)
    self.entity.offsetY = 5
    self.entity.offsetX = 0

    self.entity.pot.x = self.entity.x
    self.entity.pot.y = self.entity.y - self.entity.pot.height + 5
end

function PlayerPotIdleState:update(dt)


    if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
       love.keyboard.isDown('up') or love.keyboard.isDown('down') then
        self.entity:changeState('pot-walk')
    end

    if love.keyboard.wasPressed('return') then
        -- TODO
        -- Throw pot
        self.entity:changeState('idle')
    end
end