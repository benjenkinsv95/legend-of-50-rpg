
function throwPot(player)
    local speed = 128
    player:changeState('idle')
    player.pot.projectile = true

    if player.direction == 'left' then
        player.pot.dx = -speed
    elseif player.direction == 'right' then
        player.pot.dx = speed
    elseif player.direction == 'up' then
        player.pot.dy = -speed
    elseif player.direction == 'down' then
        player.pot.dy = speed
    end
end