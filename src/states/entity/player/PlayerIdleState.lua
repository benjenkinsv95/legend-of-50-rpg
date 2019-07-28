--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerIdleState = Class{__includes = EntityIdleState}

function PlayerIdleState:enter(params)
    
    -- render offset for spaced character sprite (negated in render function of state)
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

function PlayerIdleState:getPotAhead()
   -- keep track of current location
   local prevX = self.entity.x
   local prevY = self.entity.y

   -- move entity in direction
   if self.entity.direction == 'left' then
       self.entity.x = self.entity.x - 5
   elseif self.entity.direction == 'right' then
       self.entity.x = self.entity.x + 5
   elseif self.entity.direction == 'up' then
       self.entity.y = self.entity.y - 5
   elseif self.entity.direction == 'down' then
       self.entity.y = self.entity.y + 5
   end

   -- check if colliding with pot
   local potAhead = nil

   if self.dungeon ~= nil then 
       for k, object in pairs(self.dungeon.currentRoom.objects) do
           if object.type == 'pot' and self.entity:collides(object) then
               potAhead = object
           end
       end
   end
   
   -- reset location
   self.entity.x = prevX
   self.entity.y = prevY

   return potAhead
end

function PlayerIdleState:isPotAhead()
    return self:getPotAhead() ~= nil
end

function PlayerIdleState:update(dt)
    if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
       love.keyboard.isDown('up') or love.keyboard.isDown('down') then
        self.entity:changeState('walk')
    end

    if love.keyboard.wasPressed('space') then
        self.entity:changeState('swing-sword')
    end

    if love.keyboard.wasPressed('return') then
        print('Enter pressed')
        if self:isPotAhead() then
            self.entity.pot = self:getPotAhead()
            self.entity:changeState('pot-lift')
        end 
    end
end