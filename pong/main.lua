WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

AI_PADDLE_SPEED = 100

ai_difficulty = math.random(0.01, 1)

Class = require 'class'
push = require 'push'

require 'Ball'
require 'Paddle'


--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]

function love.load()
    math.randomseed(os.time())

    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')

    -- more 'retro-looking' font object we can use for any text
    smallFont = love.graphics.newFont('font.ttf', 8)

    victoryFont = love.graphics.newFont('font.ttf', 24)

    scoreFont = love.graphics.newFont('font.ttf', 32)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['point_scored'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }


    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })

    --keeping track of player score
    player1Score = 0
    player2Score = 0

    servingPlayer = math.random(2) == 1 and 1 or 2
    winningPlayer = 0

    --instantiate paddles
    paddle1 = Paddle(5, 20, 5, 20)
    paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    --insantiate ball position
    ball = Ball(VIRTUAL_WIDTH/2 - 2, VIRTUAL_HEIGHT/2 - 2, 5, 5)

    if servingPlayer == 1 then
        ball.dx = 100
    else
        ball.dx = -100
    end
    --declaring gameState
    gameState = 'start'

end


function love.resize(w, h)
    push:resize(w, h)
end

--[[
    update functions reiterated throughout gameplay
    movement and controls
]]
function love.update(dt)

    if gameState == 'play' then

        ball:update(dt)

        aiDelta = (ball.y + ball.width/2) - (paddle1.y + paddle1.width/2)

        -- AI movement
        if aiDelta > paddle1.width then
            paddle1.dy = AI_PADDLE_SPEED
        elseif aiDelta < -paddle1.width then
            paddle1.dy = -AI_PADDLE_SPEED
        else
            paddle1.dy = 0
        end

        --player 2 movement
        if love.keyboard.isDown('up') then
            paddle2.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('down') then
            paddle2.dy = PADDLE_SPEED
        else
            paddle2.dy = 0
        end

        if ball.x <= 0 then
            player2Score = player2Score + 1
            servingPlayer = 1
            ball:reset()

            sounds['point_scored']:play()

            if player2Score >= 10 then
                gameState = 'victory'
                winningPlayer = 'PLAYER 1'
            else
                ball.dx = 100
                gameState = 'serve'
            end
        elseif ball.x >= VIRTUAL_WIDTH - 4 then
            player1Score = player1Score + 1
            servingPlayer = 2
            ball:reset()

            sounds['point_scored']:play()

            if player1Score >= 10 then
                gameState = 'victory'
                winningPlayer = 'ROBOT'
            else
                ball.dx = -100
                gameState = 'serve'
            end
        end

        if ball:collides(paddle1) then
            --deflect to right
            ball.dx = -ball.dx * 1.08
            ball.x = paddle1.x + 5

            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        if ball:collides(paddle2) then
            --deflect ball to left
            ball.dx = -ball.dx * 1.08
            ball.x = paddle2.x - 4

            sounds['paddle_hit']:play()

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        if ball.y <= 0 then
            --deflect ball down
            ball.dy = -ball.dy
            ball.y = 0

            sounds['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.dy = -ball.dy
            ball.y = VIRTUAL_HEIGHT - 4

            sounds['wall_hit']:play()
        end

        paddle1:AIupdate(dt)
        paddle2:update(dt)
    end
end


--[[
    Keyboard handling, called by LOVE each frame;
    passes in the kwy we pressed so we can access
]]
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'victory' then
            gameState = 'start'
            player1Score = 0
            player2Score = 0
        elseif gameState == 'serve' then
            ai_difficulty = math.random(0.5, 3)
            gameState = 'play'
        end
    end
end

--[[
    Called after update by LOVE, used to draw anything to the screen, updated or otherwise.
]]
function love.draw()
    -- begin rendering at virtual resolution
    push:apply('start')

    --background
    love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 255 / 255)

    --pong text
    love.graphics.setFont(smallFont)

    -- scores
    love.graphics.setFont(scoreFont)
    love.graphics.print(player1Score, VIRTUAL_WIDTH/2 - 50, VIRTUAL_HEIGHT/3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH/2 + 30, VIRTUAL_HEIGHT/3)

    love.graphics.setFont(smallFont)
    if gameState == 'start' then
        love.graphics.printf("Welcome to Pong!", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Play", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.printf("Player " .. tostring(servingPlayer) .. "'s turn!", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press Enter to Serve", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'victory' then
        --draw victory message
        love.graphics.setFont(victoryFont)
        love.graphics.printf(tostring(winningPlayer) .. " wins!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press Enter to Restart", 0, 42, VIRTUAL_WIDTH, 'center')
    end

    --paddles
    paddle1:render()
    paddle2:render()

    --ball
    ball:render()

    --FPS counter
    displayFPS()

    -- end rendering at virtual resolution
    push:apply('end')
end


function displayFPS()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print('FPS: '..tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(1,1,1,1)
end
