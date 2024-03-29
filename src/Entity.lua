--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Entity = Class{}

function Entity:init(def)

    -- in top-down games, there are four directions instead of two
    self.direction = 'down'

    self.animations = self:createAnimations(def.animations)

    -- dimensions
    self.x = def.x
    self.y = def.y
    self.width = def.width
    self.height = def.height

    -- drawing offsets for padded sprites
    self.offsetX = def.offsetX or 0
    self.offsetY = def.offsetY or 0

    self.walkSpeed = def.walkSpeed

    
    self.baseHealth = def.baseHealth or 1
    self.baseAttack = def.baseAttack or 1
    self.baseDefense = def.baseDefense or 0
    self.health = self.baseHealth 

    self.healthLevel = def.healthLevel or 1
    self.attackLevel = def.attackLevel or 1
    self.defenseLevel = def.defenseLevel or 1

    self.exp = def.exp
    self.expToLevel = def.expToLevel
    self.expReward = def.expReward

    -- flags for flashing the entity when hit
    self.invulnerable = false
    self.invulnerableDuration = 0
    self.invulnerableTimer = 0

    -- timer for turning transparency on and off, flashing
    self.flashTimer = 0

    -- how much damage should be inflicted if defense is too high
    self.minimumDamageInflicted = def.minimumDamageInflicted or 0

    self.dead = false

    self.hasHealthbar = def.hasHealthbar == nil and true or def.hasHealthbar
    self.healthBar = ProgressBar {
        x = self.x - self.offsetX,
        y = self.y + self.height + 2,
        width = self.width,
        height = 4,
        color = {r = 32, g = 189, b = 32},
        backgroundColor = {r = 189, g = 32, b = 32},
        value = self.health,
        max = self:maxHealth()
    }
end

function Entity:createAnimations(animations)
    local animationsReturned = {}

    for k, animationDef in pairs(animations) do
        animationsReturned[k] = Animation {
            texture = animationDef.texture or 'entities',
            frames = animationDef.frames,
            interval = animationDef.interval
        }
    end

    return animationsReturned
end

--[[
    AABB with some slight shrinkage of the box on the top side for perspective.
]]
function Entity:collides(target)
    return not (self.x + self.width < target.x or self.x > target.x + target.width or
                self.y + self.height < target.y or self.y > target.y + target.height)
end

function Entity:damageAmount(baseDmg)
    return math.max(baseDmg - (self.baseDefense + self.defenseLevel - 1), 0) + self.minimumDamageInflicted
end

function Entity:canDamage(baseDmg)
    return self:damageAmount(baseDmg) ~= 0
end

function Entity:damage(baseDmg)
    local prevHealth = self.health
    self.health = math.max(self.health - self:damageAmount(baseDmg), 0)
    print('Damaging: ' .. prevHealth .. ' - ' .. self:damageAmount(baseDmg) .. ' = '.. self.health)
end

function Entity:goInvulnerable(duration)
    self.invulnerable = true
    self.invulnerableDuration = duration
end

function Entity:changeState(name)
    self.stateMachine:change(name)
end

function Entity:changeAnimation(name)
    self.currentAnimation = self.animations[name]
end

function Entity:maxHealth()
    return self.baseHealth + ((self.healthLevel - 1) * 2)
end

function Entity:update(dt)
    if self.invulnerable then
        self.flashTimer = self.flashTimer + dt
        self.invulnerableTimer = self.invulnerableTimer + dt

        if self.invulnerableTimer > self.invulnerableDuration then
            self.invulnerable = false
            self.invulnerableTimer = 0
            self.invulnerableDuration = 0
            self.flashTimer = 0
        end
    end

    self.stateMachine:update(dt)

    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end

    self.healthBar.x = self.x - self.offsetX
    self.healthBar.y = self.y + self.height + 2
    self.healthBar.value = self.health
    self.healthBar.max = self:maxHealth()
end

function Entity:processAI(params, dt)
    self.stateMachine:processAI(params, dt)
end

function Entity:render(adjacentOffsetX, adjacentOffsetY)
    
    -- draw sprite slightly transparent if invulnerable every 0.04 seconds
    if self.invulnerable and self.flashTimer > 0.06 then
        self.flashTimer = 0
        love.graphics.setColor(255, 255, 255, 64)
    end

    self.x, self.y = self.x + (adjacentOffsetX or 0), self.y + (adjacentOffsetY or 0)
    self.stateMachine:render()
    if self.hasHealthbar then
        self.healthBar:render()
    end
    love.graphics.setColor(255, 255, 255, 255)
    self.x, self.y = self.x - (adjacentOffsetX or 0), self.y - (adjacentOffsetY or 0)
end