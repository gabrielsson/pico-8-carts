pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
MINE, EMPTY, FLAGGED, FLAGGED_MINE=0,1,2,3
SPRITE_CLOSED, SPRITE_CARET, SPRITE_BOMB, SPRITE_NUMBER, SPRITE_OPEN, SPRITE_FLAG = 1,2,3,4,16,17
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
  gameWidth = board.x * 8 * zoomFactor
  gameHeight = board.y * 8 * zoomFactor
  if (gameWidth > 127 and gameHeight > 127) then 
    moveCameraX(caret.x, caret.y)
    moveCameraY(caret.x, caret.y)
  elseif (board.y * 8 * zoomFactor > 127) then 
    moveCameraY(caret.x, caret.y)
    centerCameraX()

  elseif (board.x * 8 * zoomFactor > 127) then 
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
  _drawGameBoard()
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
  _drawGameBoard()
  _drawCaret(caret.x, caret.y)
end
-- Randomly distribute the requested number of mines
-- around the game board leaving fx, fy free of mine
-- and number
-- params, freex and freey
function _setupMines(fx, fy) 
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
function _calculateMines()
  for i=0, board.x - 1 do
    for j=0, board.y - 1 do
      board.cells[i][j].surroundingMines = _surroundingMines(i,j)
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
    _setupMines(x,y)
    _calculateMines()
    setup = true
    music(0)
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
function _surroundingMines(x,y)  
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
  cx = ((board.x*8*zoomFactor) - 127 / 2) - board.x*8*zoomFactor/2
  cy = ((board.y*8*zoomFactor) - 127 / 2) - board.y*8*zoomFactor/2

  camera(flr(cx), flr(cy))
end

function centerCameraX() 
  cx = ((board.x*8*zoomFactor) - 127 / 2) - board.x*8*zoomFactor/2
  cy = peek(0x5f2a)+peek(0x5f2b)*256

  camera(flr(cx), cy)
end

function centerCameraY() 
  cx = peek(0x5f28)+peek(0x5f29)*256
  cy = ((board.y*8*zoomFactor) - 127 / 2) - board.y*8*zoomFactor/2

  camera(cx, flr(cy))
end

function moveCameraY()
  currentCameraX=peek(0x5f28)+peek(0x5f29)*256
  currentCameraY=peek(0x5f2a)+peek(0x5f2b)*256
  screenWidth = 127
  cellWidth = 8 * zoomFactor
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
  cellWidth = 8 * zoomFactor
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

function _drawGameBoard()
  for row = 0, board.x - 1 do
    for column = 0, board.y - 1 do
      cell = board.cells[row][column]
      if (cell.state == CLOSED) then
        _drawCell(SPRITE_CLOSED, row, column)
        if (cell.type == FLAGGED or cell.type == FLAGGED_MINE) then 
          _drawCell(SPRITE_FLAG, row, column)
        end
      else
        _drawCell(SPRITE_OPEN, row, column)
        if (cell.type == MINE) then
          _drawCell(SPRITE_BOMB, row, column)
        elseif (cell.surroundingMines > 0) then 
          _drawCell(cell.surroundingMines + SPRITE_NUMBER,row,column)
        end
      end
    end
  end
end

function _drawCell(n,x,y)
  zspr(n,1,1,x*8*zoomFactor,y*8*zoomFactor, zoomFactor)
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

function _drawCaret(x, y)
  _drawCell(2,x,y)
end
function checkEndButtons()
  if (btnp(fire1)) then 
    _init()
  end 
  return 
end
function checkGameButtons(caret, maxx, maxy) 
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

  if (btnp(fire1)) then 
    message = " "
    openCell(caret.x, caret.y)
  end

  if (btnp(fire2)) then 
    markMine(caret.x, caret.y)
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
__sfx__
011900001815000000306051c1401d140000001c1400000018140000001c140000001d1400000030605000001d140000003060521140241400000021140000001d14000000211400000024140000003060500000 00
011900003660536615366053661536605366153660536615366053661536605366153660536615366053660536605366153660536615366053661530605366153660536615306053661536605366153660530615 01
011900000c13000000000000000030605000000c130000000c1300000030605000003060500000000000000005140000000000000000051400000005140000000514000000366050000005140000000000000000 02
011900003060500000000000000000000000003060500000306050000000000000000000000000000000000030605000000000000000306050000036605000003060500000000000000030605000000000000000 03
011900002414000000306052314021140000001f1300000026140000003060524140231400000030605000001814000000306051c1401d140000001c140000001a140000001c1400000018140000003060500000 04
01190000366053661536605366153660536615366053661536605366153660536615071403661536605366053660536615366053661536605366153060536615366053661530605366150c140366153660530615 05
01190000071500000007140000000715000000306050000007150000000000000000071400000000000000000c140000000c130000000c1400000036605000000c1400000036605000000c140000000000000000 06
011900003060500000000000000030605000000000000000306050000000000000003660500000000000000030605000000000000000306050000000000000003060500000000000000036605000000000000000 07
011900002414000000306052314021140000001f14000000261400000030605241402414000000306050000029140000002814000000261400000024130000002d140000002b1400000005140000003060500000 08
01190000366053661536605366150c140366153660536615366053661536605366150c13036615366053660536605366153660536615366053661530605366153660536615306053661536605366153660530615 09
011900000c1400000000000000000c1400000030605000000c1400000000000000000c1400000000000000000513000000051400000005140000003660500000051400000036605000002b150000000000000000 0a
011900003060500000000000000036605000000000000000306050000000000000003660500000000000000030605000003060500000306050000000000000003060500000000000000030605000000000000000 0b
011900001814000000306051a1401c140000001813000000211400000030605000001f1500000030605000001c140000001d1401f1401d150000001c130000001a140000001c1400000018140000003060500000 0c
01190000071400000000000000000714000000306050000007140000000000000000306050000000000000000c1300000030605000000b140000000714000000051400000007140000000c130000000000000000 0d
011900003060500000000000000030605000000000000000306050000000000000000000000000000000000030605000000000000000306050000036605000003060500000366050000030605000000000000000 0e
011900002114000000306052114021150000001f140000001d140000001d140000001d140000001c140000001f140000002115000000231500000024140000002614000000241400000024150000003060500000 0f
011900003660536615366053661505140366153660536615366053661536605366150514036615366053660536605366153660536615366053661530605366153660536615306053661536605366153660530615 10
011900000514000000000000000005140000003060500000051400000030605000000514000000306050000007150000000714000000071400000036605000000713000000366050000007150000000000000000 11
0119000018140000001c140000001f140000001d140000001c140000001a14000000181400000030605000001c15000000306051d1501f140000001d1500000021140000001f140000001f140000003060500000 12
011900000c140000000c1400000030605000000c140000000c1400000030605000003060500000000000000005140000000514000000051400000036605000000714000000071400000007140000000000000000 13
011900003060500000306050000000000000003060500000306050000000000000000000000000000000000030605000000000000000306050000000000000003060500000366050000030605000000000000000 14
0119000018140000001c140000001d140000001c140000001a140000001d1400000021150000001f140000001d140000002114000000241400000023140000002614000000241400000030605000003060500000 15
011900000c140000000c130000000c1400000030605000000c140000000b1400000009140000000514000000071400000007140000000714000000071400000005140000000c140000000c130000000000000000 16
011900003060500000306050000030605000000000000000306050000030605000003060500000306050000030605000003060500000306050000036605000003060500000366050000024150000000000000000 17
__music__
01 00010203 0
00 04050607 1
00 08090a0b 2
00 0c010d0e 3
00 0f10110b 4
00 12011314 5
02 15011617 6


