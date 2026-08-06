player = {
    x = 400,
    y = 300,
    speed = 250,
    size = 40
}

coin = {
    x = 100,
    y = 100,
    size = 20
}

score = 0

function love.update(dt)

    if love.keyboard.isDown("w") then
        player.y = player.y - player.speed * dt
    end

    if love.keyboard.isDown("s") then
        player.y = player.y + player.speed * dt
    end

    if love.keyboard.isDown("a") then
        player.x = player.x - player.speed * dt
    end

    if love.keyboard.isDown("d") then
        player.x = player.x + player.speed * dt
    end

    if player.x < coin.x + coin.size and
       player.x + player.size > coin.x and
       player.y < coin.y + coin.size and
       player.y + player.size > coin.y then

        score = score + 1

        coin.x = math.random(20, 760)
        coin.y = math.random(20, 560)

    end

end

function love.draw()

    love.graphics.setColor(0, 0.6, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", coin.x, coin.y, coin.size)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Scores: "..score, 10, 10)
    love.graphics.print("X: " .. math.floor(player.x) .. " Y: " .. math.floor(player.y), 120, 10)

end