pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- Pico Shooting Range
-- by gabrielsson
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15


game = {}
score = {}

function _init() 
    game_init()

end

function _draw()
    game.draw()
end

function _update60()
    game.update()
end

function game_init() 
    game = {}
    game.targets = targets()
    game.lastShot = -100

    game.crosshair = {}
    score = {}
    game.update = game_update
    
    game.draw = game_draw
    game.crosshair.x = 64
    game.crosshair.y = 64

    game.crosshair.move = move_crosshair
    game.crosshair.move(20)
    game.shoot = shoot
end
function targets()
    targets = {}
    target = {}
    target.x = 64
    target.y = 64
    target.z = 1
    add(targets, target)
    return targets;
end

function game_draw()
    cls()

    color = dark_gray
    isDark = true
    for i = 66,1,-12 
    do 
        if isDark then 
            color = orange
        else
            color = dark_gray
        end
        circfill(64,64,i,color)
        isDark = not isDark
    end
    circfill(64,64,5,yellow)
    

    
    for v in all(score) do
        circfill(v[1],v[2],2,light_gray)
    end
    shotsLeft = 3-#score
    print("shots left "..shotsLeft, 0, 0, white)
    spr(1, game.crosshair.x -4, game.crosshair.y-4)
    if(shotsLeft > 0) then
        print("press ❎ to shoot", 32, 115, white)
    end

    
end

function game_update() 
        if btn(0) then game.crosshair.x -= 1 end
        if btn(1) then game.crosshair.x += 1 end
        if btn(2) then game.crosshair.y -= 1 end
        if btn(3) then game.crosshair.y += 1 end
        if btnp(5) and #score < 3  then 
            game.shoot() 
            sfx(0)
            game.crosshair.move(7)
            
        end
        game.crosshair.move(1)

        if #score > 2 and time() > game.lastShot + 1 then
            game.update =end_game
            game.draw = end_draw
        end
end

function end_game()
    if btnp(5) then game_init() end
end

function end_draw()
    cls()
    i = 0.5
    total = 0
    for v in all(score) do
        local d = distance(v[1],v[2],64,64)
        local s = flr(((64-d) / 64) * 10)+1
        if s < 0 then s = 0 end
        total += s
        rect(i*31,30,i*31+31,40,dark_blue)
        print(s,i*31 + 2,32,white)
        
        i += 1
    end
    
    print("total score "..total, 22,64,white)

    print("press ❎ to try again", 24, 115, white)
    


end
function distance ( x1, y1, x2, y2 )
    local dx = x1 - x2
    local dy = y1 - y2
    return sqrt( dx * dx + dy * dy )
end

function move_crosshair(factor) 
    game.crosshair.x += (rnd(4*10)/10-2)*factor
    game.crosshair.y += (rnd(4*10)/10-2)*factor
    if game.crosshair.x < 0 then game.crosshair.x = 0 end
    if game.crosshair.y < 0 then game.crosshair.x = 0 end
    if game.crosshair.x > 127 then game.crosshair.x = 127 end
    if game.crosshair.y > 127 then game.crosshair.y = 127 end
    
end

function shoot() 
    game.lastShot = time()
    add(score, {game.crosshair.x, game.crosshair.y})

end

function zspr(n,w,h,dx,dy,dz)
    sx = 8 * (n % 16)
    sy = 8 * flr(n / 16)
    sw = 8 * w
    sh = 8 * h
    dw = sw * dz
    dh = sh * dz
  
    sspr(sx,sy,sw,sh, dx,dy,dw,dh)
end

__gfx__
00000000008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800800080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800080080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003565033600306002d6502c6602660024600216401f600182301b6001a60019600176001465013650116400e6400d6300a60008600076000460001630
