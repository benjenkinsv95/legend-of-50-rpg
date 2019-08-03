--[[
    GD50
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelUpState = Class{__includes = BaseState}

function LevelUpState:enter(def)
    self.attackLevel = def.attackLevel or 1
    self.defenseLevel = def.defenseLevel or 1
    self.healthLevel = def.healthLevel or 1
    self.exp = def.exp or 0
    self.expToLevel = def.expToLevel or 10

    self.totalLevel = (self.attackLevel + self.defenseLevel + self.healthLevel) - 2
    

    self.menu = Menu {
        x = VIRTUAL_WIDTH / 3,
        y = VIRTUAL_HEIGHT / 3 + 32,
        width = VIRTUAL_WIDTH / 3,
        height = VIRTUAL_HEIGHT / 2.6,
        items = {
            {
                text = 'ATK: ' .. self.attackLevel .. ' -> ' .. (self.attackLevel + 1),
                onSelect = function()
                    gStateMachine:change('play', {
                        attackLevel = self.attackLevel + 1,
                        defenseLevel = self.defenseLevel,
                        healthLevel = self.healthLevel,
                        exp = self.exp,
                        expToLevel = self.expToLevel
                    }) 
                end
            },
            {
                text = 'DEF: ' .. self.defenseLevel .. ' -> ' .. (self.defenseLevel + 1),
                onSelect = function()
                    gStateMachine:change('play', {
                        attackLevel = self.attackLevel,
                        defenseLevel = self.defenseLevel + 1,
                        healthLevel = self.healthLevel,
                        exp = self.exp,
                        expToLevel = self.expToLevel
                    }) 
                end
            },
            {
                text = 'HP:  ' .. self.healthLevel .. ' -> ' .. (self.healthLevel + 1),
                onSelect = function()
                    gStateMachine:change('play', {
                        attackLevel = self.attackLevel,
                        defenseLevel = self.defenseLevel,
                        healthLevel = self.healthLevel + 1,
                        exp = self.exp,
                        expToLevel = self.expToLevel
                    }) 
                end
            }
        }
    }


    gSounds['music']:stop()
    gSounds['victory-music']:setLooping(true)
    gSounds['victory-music']:play()

    gSounds['levelup']:play()


end

function LevelUpState:exit() 
    gSounds['victory-music']:stop()
    gSounds['music']:setLooping(true)
    gSounds['music']:play()
end

function LevelUpState:update(dt)
    self.menu:update(dt)
end

function LevelUpState:render()
    love.graphics.draw(gTextures['background'], 0, 0, 0, 
        VIRTUAL_WIDTH / gTextures['background']:getWidth(),
        VIRTUAL_HEIGHT / gTextures['background']:getHeight())

    love.graphics.setFont(gFonts['zelda'])
    love.graphics.setColor(34, 34, 34, 255)
    
    love.graphics.printf('Level Up!', 2, VIRTUAL_HEIGHT / 3 - 30, VIRTUAL_WIDTH, 'center')

    love.graphics.setColor(255, 215, 0, 255)
    love.graphics.printf('Level Up!', 0, VIRTUAL_HEIGHT / 3 - 32, VIRTUAL_WIDTH, 'center')

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setFont(gFonts['zelda-xsmall'])
    self.menu:render()
end