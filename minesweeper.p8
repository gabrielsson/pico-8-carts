pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
MINE, EMPTY, FLAGGED, FLAGGED_MINE=0,1,2,3
SPRITE_CLOSED, SPRITE_CARET, SPRITE_BOMB, SPRITE_NUMBER, SPRITE_OPEN, SPRITE_FLAG = 32,2,34,4,16,17
OPEN,CLOSED = 0,1
STATE_SETUP, STATE_GAME, STATE_END = 0,1,2
board = {}

numberOfMines = 0
caret = {}
zoomFactor = 1
message = ""
finishedZoomOut = true
setup = false
game = {}
function _init()
  game.update = updateSetup
  game.draw = drawSetup
  zoomFactor = 1
  board.x = 10
  board.y = 10
  numberOfMines = 10
  setup = false

  camera(0,0)
end
function initGame() 
  palt(0, false)
  palt(3, true)  
  caret.x = 0
  caret.y = 0

  board.cells = {}
  for i = 0, board.x - 1 do
    board.cells[i] = {}
    for j = 0, board.y - 1 do
        board.cells[i][j] = {}
        board.cells[i][j].type = EMPTY
        board.cells[i][j].state = CLOSED
        board.cells[i][j].x = i
        board.cells[i][j].y = j
        board.cells[i][j].surroundingMines = 0
    end
  end
end
function _update()
  game.update()
end

function updateSetup()
  if(not game.setup) then 
    game.setup = {}
    game.setup.state = 0
  end
  checkSetupButtons()
end

function checkSetupButtons() 
  if (btnp(fire1)) then 
    initGame()
    game.update = updateGame
    game.draw = drawGame
    game.game = {}
    game.game.showMenu = false
  end
  if (btnp(down) and game.setup.state < 3) then 
    game.setup.state += 1
  end

  if (btnp(up) and game.setup.state > 0) then 
    game.setup.state -= 1
  end

  if (btnp(left)) then
    if(game.setup.state == 0 and board.x > 4) board.x -= 1
    if(game.setup.state == 1 and board.y > 4) board.y -= 1
    if(game.setup.state == 2 and zoomFactor > 0.5) zoomFactor -= 0.5
    if(game.setup.state == 3 and numberOfMines > 0) numberOfMines -= 1

  end

  if (btnp(right)) then
    if(game.setup.state == 0 and board.x < 25) board.x += 1
    if(game.setup.state == 1 and board.y < 25) board.y += 1
    if(game.setup.state == 2 and zoomFactor < 6) zoomFactor += 0.5
    if(game.setup.state == 3 and numberOfMines < board.x*board.y - 9) numberOfMines += 1
  end
end

function drawSetup()
  cls()
  outline("<                  >", 10, 20 * game.setup.state + 20, white, black)
  outline("x: "..board.x, 30, 20, white, black)
  outline("y: "..board.y, 30, 40, white, black)
  outline("zoom: " ..zoomFactor.."x", 30, 60, white, black)
  outline("mines: " ..numberOfMines, 30, 80, white, black)

end
function updateGame()

  checkGameButtons(caret, board.x, board.y)
  checkGameOver()
  gameWidth = board.x * 16 * zoomFactor
  gameHeight = board.y * 16 * zoomFactor
  if (gameWidth > 127 and gameHeight > 127) then 
    moveCameraX(caret.x, caret.y)
    moveCameraY(caret.x, caret.y)
  elseif (board.y * 16 * zoomFactor > 127) then 
    moveCameraY(caret.x, caret.y)
    centerCameraX()

  elseif (board.x * 16 * zoomFactor > 127) then 
    moveCameraX(caret.x, caret.y)
    centerCameraY()
  else 
    centerCamera()
  end
end

function _draw()
  game.draw()
end

function drawEnd()
  cls()
  centerCamera()
  drawGameBoard()
  if (finishedZoomOut) then 
    zoomFactor = zoomFactor * 0.995
    if (zoomFactor < 0.5) finishedZoomOut = false
  else 
    zoomFactor = zoomFactor * 1.005
    if(zoomFactor > 3) finishedZoomOut = true
  end
  camera(0,0)
  outline("PRESS ❎ TO CONTINUE", 25, 60, black, white)
  centerCamera()
end

function updateEnd() 
  checkEndButtons()
end

function drawGame()
  cls()
  width = 8

  drawGameBoard()
  drawCaret(caret.x, caret.y)
  if(game.game.showMenu) then 
    drawGameMenu(caret.x, caret.y)
  end
end
-- Randomly distribute the requested number of mines
-- around the game board leaving fx, fy free of mine
-- and number
-- params, freex and freey
function setupMines(fx, fy) 
  placedMines = 0

  while (placedMines < numberOfMines) do
    x = flr(rnd(board.x))
    y = flr(rnd(board.y))
    -- make sure first click is free

    if (board.cells[x][y].type != MINE and
        (x < fx - 1 or x > fx + 1 or y < fy - 1 or y > fy + 1)) then
      board.cells[x][y].type = MINE
      placedMines += 1
    end
  end
end

-- Keep an internal count of how many mines surround
-- each cell
function calculateMines()
  for i=0, board.x - 1 do
    for j=0, board.y - 1 do
      board.cells[i][j].surroundingMines = surroundingMines(i,j)
    end
  end
end

function markMine(x, y)
  cell = board.cells[x][y]
  printh("Marking mine "..tostr(x)..","..tostr(y))

  if (cell.state == OPEN) then
    return 
  end

  counted = countFlags(false)
  printh("Counted flags "..tostr(counted))

  if (cell.type == FLAGGED) then
      cell.type = EMPTY
  elseif (cell.type == FLAGGED_MINE) then
      cell.type = MINE
  elseif (countFlags(false) == numberOfMines) then
      return
  elseif (cell.type == MINE) then
      cell.type = FLAGGED_MINE
      printh("Setting flagged_mine "..tostr(cell.type))
  else
      cell.type = FLAGGED
      printh("Setting flagged "..tostr(cell.type))

  end
end

function countFlags(minesOnly)
  flaggedCount = 0
  for x = 0, board.x - 1 do
    for y = 0, board.y - 1 do
      type = board.cells[x][y].type
      if (not minesOnly and type == FLAGGED) then
          flaggedCount = flaggedCount + 1
      elseif (type == FLAGGED_MINE) then
        flaggedCount = flaggedCount + 1
      end
    end
  end
  return flaggedCount
end

function openCell(x, y) 
  if (not setup) then 
    setupMines(x,y)
    calculateMines()
    setup = true
    music(0, 5000)
  end
  cell = board.cells[x][y]
  printh("Open cell "..tostr(x)..","..tostr(y))
  -- Force open cells
  message = message..tostr(cell.type)..":"..tostr(cell.state).." "
  if (cell.state == OPEN) then
    forceOpenCells(x, y)
  end

  -- Dont open a flagged cell
  if (cell.type == FLAGGED or cell.type == FLAGGED_MINE) then
    return
  end
  -- Open cell up and check if its a mine
  cell.state = OPEN
  if (cell.type == MINE) then
    
    revealMines()
    game.update = updateEnd
    game.draw = drawEnd
    music(-1)
    return
  end

  -- Stop opening when we get to a cell that has mines around it
  printh("Maybe return "..tostr(cell.surroundingMines))

  if (cell.surroundingMines > 0) then
    printh("Returning "..tostr(cell.surroundingMines))

    return
  end

  
  -- Recursively open adjacent cells
  surroundingCells = getSurroundingCells(cell.x, cell.y)
  for c in all(surroundingCells) do
    if (c.state == CLOSED) then
      printh("Calling open cell "..tostr(cell.state))

      openCell(c.x, c.y)
    end
  end
end

function checkGameOver() 
  flaggedCount = countFlags(true)
  if (flaggedCount == numberOfMines) then
    game.update = updateEnd
    game.draw = drawEnd
    music(-1)
  end
end

function revealMines()
  for row = 0, board.x - 1 do
    for column = 0, board.y - 1 do
      cell = board.cells[row][column]
      if (cell.type == MINE or cell.type == FLAGGED_MINE) then
        cell.state = OPEN
      end
    end
  end
end

function forceOpenCells(x, y)
  cell =  board.cells[x][y]
  printh("Force open cell "..tostr(x)..","..tostr(y))

  surroundingCells = getSurroundingCells(cell.x, cell.y)
  surroundingFlagged = 0
  
  for c in all(surroundingCells) do
    if (c.type == FLAGGED or c.type == FLAGGED_MINE) then
      surroundingFlagged = surroundingFlagged + 1
      printh("Flagging "..tostr(x)..","..tostr(y))

    end
  end
  
  printh("Bombs around "..tostr(cell.surroundingMines))

  -- Return if the correct number hasnt been marked
  if (surroundingFlagged < cell.surroundingMines) return

  -- Open the adjacent cells
  for c in all(surroundingCells) do
      if (c.state == CLOSED) openCell(c.x, c.y)
  end
end

-- Calculate how many mines are directly adjacent to
-- the specified cell.
--
-- param cell - the cell to check
-- return the number of mines adjacent to the cell (0..8)
function surroundingMines(x,y)  
  surroundingCells = getSurroundingCells(x, y)
  mineCount = 0
  for c in all(surroundingCells) do
    if (c.type == MINE) then
      mineCount = mineCount + 1
    end
  end     
  
  return mineCount
end

function getSurroundingCells(x,y)
  surrounding = {}
  
  if (x > 0) then
    add(surrounding, board.cells[x - 1][y])
    if (y > 0) then
        add(surrounding, board.cells[x - 1][y - 1])
    end
    if (y < board.y - 1) then
      add(surrounding, board.cells[x - 1][y + 1])
    end
  end
  if (x < board.x - 1) then
    add(surrounding, board.cells[x + 1][y])
    if (y < board.y - 1) add(surrounding, board.cells[x + 1][y + 1])
    if (y > 0) add(surrounding, board.cells[x + 1][y - 1])
  end
  if (y > 0) add(surrounding, board.cells[x][y - 1])
  if (y < board.y - 1) add(surrounding, board.cells[x][y + 1])

  return surrounding
end

function centerCamera() 
  cx = ((board.x*16 *zoomFactor) - 127 / 2) - board.x*16 *zoomFactor/2
  cy = ((board.y*16 *zoomFactor) - 127 / 2) - board.y*16 *zoomFactor/2

  camera(flr(cx), flr(cy))
end

function centerCameraX() 
  cx = ((board.x*16 *zoomFactor) - 127 / 2) - board.x*16 *zoomFactor/2
  cy = peek(0x5f2a)+peek(0x5f2b)*256

  camera(flr(cx), cy)
end

function centerCameraY() 
  cx = peek(0x5f28)+peek(0x5f29)*256
  cy = ((board.y*16 *zoomFactor) - 127 / 2) - board.y*16 *zoomFactor/2

  camera(cx, flr(cy))
end

function moveCameraY()
  currentCameraX=peek(0x5f28)+peek(0x5f29)*256
  currentCameraY=peek(0x5f2a)+peek(0x5f2b)*256
  screenWidth = 127
  cellWidth = 16 * zoomFactor
  -- calculate the new x,y
  y = ((board.y*cellWidth - screenWidth) / (board.y -1) ) * caret.y

  -- smooth transition
  if(y < currentCameraY) currentCameraY -=1
  if(y > currentCameraY) currentCameraY +=1

  -- setting the camera position with this call
  -- (0,0) shows px from 0-127
  -- (-127, -127) scrolls the camera so it shows 127-255
  camera(currentCameraX, currentCameraY)
end

function moveCameraX()
  currentCameraX=peek(0x5f28)+peek(0x5f29)*256
  currentCameraY=peek(0x5f2a)+peek(0x5f2b)*256

  screenWidth = 127
  cellWidth = 16 * zoomFactor
  -- calculate the new x,y
  x = ((board.x*cellWidth - screenWidth) / (board.x -1) ) * caret.x

  
  -- smooth transition
  if(x < currentCameraX) currentCameraX -=1
  if(x > currentCameraX) currentCameraX +=1

  -- setting the camera position with this call
  -- (0,0) shows px from 0-127
  -- (-127, -127) scrolls the camera so it shows 127-255
  camera(currentCameraX, currentCameraY)
end



function outline(s,x,y,c1,c2)
	for i=0,2 do
	 for j=0,2 do
	  if not(i==1 and j==1) then
	   print(s,x+i,y+j,c1)
	  end
	 end
	end
	print(s,x+1,y+1,c2)
end

function drawGameBoard()
  for row = 0, board.x - 1 do
    for column = 0, board.y - 1 do
      cell = board.cells[row][column]
      if (cell.state == CLOSED) then
        drawCell(SPRITE_CLOSED, row, column)
        if (cell.type == FLAGGED or cell.type == FLAGGED_MINE) then 
          drawCell(SPRITE_FLAG, row, column)
        end
      else
        drawCell(SPRITE_OPEN, row, column)
        if (cell.type == MINE) then
          drawCell(SPRITE_BOMB, row, column)
        elseif (cell.surroundingMines > 0) then 
          drawCell(cell.surroundingMines + SPRITE_NUMBER,row,column)
        end
      end
    end
  end
end

function drawCell(n,x,y)
  zspr(n,2,2,x*16 *zoomFactor,y*16 *zoomFactor, zoomFactor)
end

function zspr(n,w,h,dx,dy,dz)
  sx = 16 * (n % 16)
  sy = 16 * flr(n / 16)
  sw = 16 * w
  sh = 16 * h
  dw = sw * dz
  dh = sh * dz

  sspr(sx,sy,sw,sh, dx,dy,dw,dh)
end

function drawCaret(x, y)
  drawCell(SPRITE_CARET,x,y)
end

function drawGameMenu(x, y)

  
  --vzoom in

  -- draw four circles
  cx = x * 16 * zoomFactor
  cy = y * 16 * zoomFactor
  r = 16 * zoomFactor
  d = 13 * zoomFactor

   -- center camera
  

  circfill(cx - d + 4, cy + 4,r,dark_gray)
  circfill(cx + d + 4, cy + 4,r,dark_gray)
  circfill(cx + 4, cy - d + 4,r,dark_gray)
  circfill(cx + 4, cy + d + 4,r,dark_gray)
  zspr(SPRITE_BOMB,2,2,cx - d,cy,zoomFactor)
  zspr(SPRITE_FLAG,2,2,cx + d,cy,zoomFactor)

  -- blit the sprites
  
 
  
end

function checkEndButtons()
  if (btnp(fire1)) then 
    _init()
  end 
  return 
end
function checkGameButtons(caret, maxx, maxy)
  game.game.showMenu = false
  if((btn(fire1) or btn(fire2))) then
    game.game.showMenu = true
  end

  if(game.game.showMenu) then
    if (btnp(left)) then 
      message = " "
      openCell(caret.x, caret.y)
      
    end
  
    if (btnp(right)) then 
      markMine(caret.x, caret.y)
      
    end
    if (btnp(up)) then 
      zoomFactor = zoomFactor * 1.1
    end
  
    if (btnp(down)) then 
      zoomFactor = zoomFactor * 0.9
    end
  else 
    if (btnp(left) and caret.x > 0) then 
      caret.x -= 1 
    end
    if (btnp(right) and caret.x < maxx - 1) then 
      caret.x += 1

    end
    if (btnp(up) and caret.y > 0) then 
      caret.y -= 1

    end

    if (btnp(down) and caret.y < maxy - 1) then 
      caret.y += 1
    end
  end


end


__gfx__
00000000555555558888888833333398333333333333333333333333333333333333333333333333333333333333333333333333000000000000000000000000
000000005666666d8333333e33011303333333333333133333444333333883333333113333444433333bb3333333333333333333000000000000000000000000
000000005666666d8333333e3001cc3333333333333113333433343333833833333131333343333333b333333333333333333333000000000000000000000000
000000005666666d8333333e30011c1333333333333313333333433333338333331331333344433333bbbb333333333333333333000000000000000000000000
000000005666666d8333333e3000111333333333333313333334333333333833331111133333343333b33b333333333333333333000000000000000000000000
000000005666666d8333333e3000000333333333333313333343333333833833333331333333343333b33b333333333333333333000000000000000000000000
000000005666666d8333333e3300003333333333333111333444443333388333333331333344433333bbbb333333333333333333000000000000000000000000
00000000ddddddddeeeeeeee33333333333333333333333333333333333333333333333333333333333333333333333333333333000000000000000000000000
77777777333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666667333703330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666667338803330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666667377703330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666667333303330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666667333303330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76666667330000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777773333333333333a88000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777753333330000331393000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553333000000001133000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
776666666666665533300011cc100333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553300111cc7c10033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
776666666666665533000111cc7c1033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553000001111cc1003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553000000011111003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553000000001111003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553000000000111003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553300000000001033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553300000000000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553330000000000333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77666666666666553333000000003333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
75555555555555553333330000333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555553333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011700001813000000306051c1301d120000001c1300000018120000001c120000001d1300000030605000001d130000003060521130241300000021130000001d13000000211200000024130000003060500000
011700003660536615366053661536605366153660536615366053661536605366153660536615366053660536605366153660536615366053661530605366153660536615306053661536605366153660530615
011700000c12000000000000000030605000000c120000000c1200000030605000003060500000000000000005130000000000000000051200000005120000000513000000366050000005120000000000000000
011700003060500000000000000000000000003060500000306050000000000000000000000000000000000030605000000000000000306050000036605000003060500000000000000030605000000000000000
011700002413000000306052312021130000001f1200000026130000003060524120231200000030605000001813000000306051c1201d130000001c130000001a120000001c1300000018120000003060500000
01170000366053661536605366153660536615366053661536605366153660536615071303661536605366053660536615366053661536605366153060536615366053661530605366150c120366153660530615
01170000071300000007130000000713000000306050000007130000000000000000071300000000000000000c120000000c120000000c1200000036605000000c1200000036605000000c120000000000000000
011700003060500000000000000030605000000000000000306050000000000000003660500000000000000030605000000000000000306050000000000000003060500000000000000036605000000000000000
011700002413000000306052312021120000001f13000000261300000030605241302412000000306050000029130000002812000000261200000024120000002d130000002b1300000005120000003060500000
01170000366053661536605366150c120366153660536615366053661536605366150c12036615366053660536605366153660536615366053661530605366153660536615306053661536605366153660530615
011700000c1200000000000000000c1200000030605000000c1200000000000000000c1200000000000000000512000000051200000005120000003660500000051300000036605000002b130000000000000000
011700003060500000000000000036605000000000000000306050000000000000003660500000000000000030605000003060500000306050000000000000003060500000000000000030605000000000000000
011700001812000000306051a1201c120000001812000000211200000030605000001f1300000030605000001c120000001d1201f1201d130000001c120000001a120000001c1200000018120000003060500000
01170000071300000000000000000713000000306050000007130000000000000000306050000000000000000c1200000030605000000b120000000712000000051300000007120000000c120000000000000000
011700003060500000000000000030605000000000000000306050000000000000000000000000000000000030605000000000000000306050000036605000003060500000366050000030605000000000000000
011700002113000000306052112021130000001f130000001d130000001d130000001d130000001c130000001f130000002113000000231300000024130000002613000000241200000024130000003060500000
011700003660536615366053661505120366153660536615366053661536605366150512036615366053660536605366153660536615366053661530605366153660536615306053661536605366153660530615
011700000512000000000000000005130000003060500000051200000030605000000512000000306050000007130000000712000000071300000036605000000712000000366050000007130000000000000000
0117000018130000001c130000001f130000001d130000001c120000001a13000000181200000030605000001c13000000306051d1301f130000001d1300000021130000001f130000001f130000003060500000
011700000c120000000c1200000030605000000c120000000c1200000030605000003060500000000000000005120000000512000000051300000036605000000712000000071200000007120000000000000000
011700003060500000306050000000000000003060500000306050000000000000000000000000000000000030605000000000000000306050000000000000003060500000366050000030605000000000000000
0117000018130000001c120000001d130000001c130000001a120000001d1300000021130000001f120000001d130000002113000000241200000023130000002613000000241300000030605000003060500000
011700000c120000000c120000000c1200000030605000000c120000000b1200000009120000000512000000071300000007120000000712000000071200000005120000000c120000000c120000000000000000
011700003060500000306050000030605000000000000000306050000030605000003060500000306050000030605000003060500000306050000036605000003060500000366050000024130000000000000000
__music__
01 00010203
00 04050607
00 08090a0b
00 0c010d0e
00 0f10110b
00 12011314
02 15011617

