pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- Pico Shooting Range
-- by gabrielsson
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15


game = {}
level = 1
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
    game.start = time()

    game.targets = targets(level)
    game.rows = rows(4)
    game.lastShot = -100

    game.update = game_update
    
    game.draw = game_draw

    game.crosshair = {
        x = 64,
        y = 64,
        move = function(self) 
            self.x += (rnd(2*10)/10-1)
            self.y += (rnd(2*10)/10-1)
            if self.x < 0 then self.x = 0 end
            if self.y < 0 then self.y = 0 end
            if self.x > 127 then self.x = 127 end
            if self.y > 127 then self.y = 127 end
        end,
        recoil = function(self)
            local y = self.y
            self:move()
            self.y -= 10*abs(y - self.y)
        end
    }

    game.crosshair:move()
    game.shoot = shoot
end

function rows(n)
    local rows = {}
    
    
    for i = 1, n do
        direction = 1
        
        if (n % 2 < 1) then direction = -1 end
        
        offsetX = 10 * (n-i)
        offsetY = 30
        lineLength = 127-offsetX*2
        add(rows, {
            y = offsetY*i,
            x = offsetX,
            length = lineLength,
            speed = lineLength/127
        })
    end
    return rows
end
function targets(n)
    local distanceBetween = (127/(n+1))
    local targets = {}
    for i=1,n do
        add(targets, {
            x = rnd(96) + 16,
            y = distanceBetween*i,
            z = (i / n)*2 + 1,
            direction = rnd(1.2) - 0.6,
            draw = function(self)
                target_draw(self)
            end,
            update = function(self)
                if self.x > 127 or self.x < 0 then self.direction *= -1 end
                if not self.isHit then self.x += self.direction end
            end
        })       
    end
    
    return targets;
end
function game_draw()
    cls()
    draw_bg()
    for target in all(game.targets) do
        target:draw()
    end
    
    l = targetsLeft()
    for row in all(game.rows) do
        line(row.x,row.y,row.x+row.length,row.y,blue)
        
    end
    levelTime =  10 - (time()- game.start)
    print("time left "..levelTime, 0, 0, white)
    spr(1, game.crosshair.x -4, game.crosshair.y-4)
    if(l > 0) then
        print("press ❎ to shoot", 32, 115, white)
    end
end
function draw_bg() 
    local a = {x=64, y= -60}
    local b = {x=-80,y=127}
    local c = {x=207,y=127}
    fill_tri(a,b,c,orange)


end

function target_draw(target)
    local a = {x=target.x, y=target.y+(5*target.z)}
    local b = {x=target.x-(5*target.z),y=target.y+(9*target.z)}
    local c = {x=target.x+(5*target.z),y=target.y+(9*target.z)}
    fill_tri(a,b,c,dark_green)
    
    if not target.isHit then 
        circfill(target.x,target.y,9*target.z,red)
        circ(target.x,target.y,9*target.z,black)

        circfill(target.x,target.y,6*target.z,white)
        circfill(target.x,target.y,3*target.z,red)
    else 
        line(target.x - (9*target.z),target.y+(5*target.z) + 1,target.x + (9*target.z),target.y+(5*target.z) + 1,black)
        line(target.x - (9*target.z),target.y+(5*target.z),target.x + (9*target.z),target.y+(5*target.z),red)
    end
end

fill_tri = function(a,b,c,col)
color(col)
    if (b.y-a.y > 0) dx1=(b.x-a.x)/(b.y-a.y) else dx1=0;
    if (c.y-a.y > 0) dx2=(c.x-a.x)/(c.y-a.y) else dx2=0;
    if (c.y-b.y > 0) dx3=(c.x-b.x)/(c.y-b.y) else dx3=0;
    local e = {x=a.x, y=a.y};
    local s = {x=a.x, y=a.y}
    if (dx1 > dx2) then
        while(s.y<=b.y) do
            s.y+=1;
            e.y+=1;
            s.x+=dx2;
            e.x+=dx1;
            line(s.x,s.y,e.x,s.y);
        end
        e.x = b.x
        e.y = b.y
        while(s.y<=c.y) do
            s.y+=1;
            e.y+=1;
            s.x+=dx2;
            e.x+=dx3;
            line(s.x,s.y,e.x,s.y);
        end
    else
        while(s.y<b.y)do
            s.y+=1;e.y+=1;s.x+=dx1;e.x+=dx2;
            line(s.x,s.y,e.x,e.y);
        end
        s.x=b.x
        s.y=b.y
        while(s.y<=c.y)do
            s.y+=1;e.y+=1;s.x+=dx3;e.x+=dx2;
            line(s.x,s.y,e.x,e.y);
        end
    end
end

function game_update() 
        if btn(0) then game.crosshair.x -= 1 end
        if btn(1) then game.crosshair.x += 1 end
        if btn(2) then game.crosshair.y -= 1 end
        if btn(3) then game.crosshair.y += 1 end
        if btnp(5) and targetsLeft() > 0  then 
            game.shoot() 
            sfx(0)
            game.crosshair:recoil(8)
            
        end
        for target in all(game.targets) do
            target:update()
        end
        game.crosshair:move(1)
        if targetsLeft() < 1 and time() > game.lastShot + 1 then
            game.update =end_game
            game.draw = end_draw
            game.time = time() - 1
        end
end

function end_game()
    if btnp(5) then 
        if gameOver then
            level = 1
            gameOver = false
        else 
            level +=1
        end
        game_init() 
    end
end

function end_draw()
    cls()
    i = 0.5
    total = game.time - game.start
    if( total > 10) then 
        gameOver = true

        col = red 
        print("total time "..(game.time-game.start), 22,64,col)
        print("❎ game over at level "..level, 12, 115, col)
    else
        col = green
        print("total time "..(game.time-game.start), 22,64,col)
        print("❎ next level "..level +1, 27, 115, col)
    end
end
function distance ( x1, y1, x2, y2 )
    local dx = x1 - x2
    local dy = y1 - y2
    return sqrt( dx * dx + dy * dy )
end

function shoot() 
    game.lastShot = time()
    check_hit(game.crosshair.x, game.crosshair.y) 
end

function check_hit(x,y) 
    for i=#game.targets,1,-1 do
        if not game.targets[i].isHit then 
            if distance(x,y,game.targets[i].x,game.targets[i].y) < 9*game.targets[i].z then
                game.targets[i].isHit = true
                break
            end
        end
    end
end

function targetsLeft() 
    local left = 0
    for target in all(game.targets) do
        if not target.isHit then left += 1 end
    end

    return left
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
00000000002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000200000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000220000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000220000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000200000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003565033600306002d6502c6602660024600216401f600182301b6001a60019600176001465013650116400e6400d6300a600086000760004600016300000000000000000000000000000000000000000
