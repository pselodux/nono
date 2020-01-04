-- nono v0.5
-- by 0F.digital
--
-- a 4-channel grid sequencer
-- inspired by nanoloop
--
-- outputs on midi channels
-- 1 to 4, as well as basic
-- internal voice.
--
-- controls are shown on
-- screen, but for clarity:
--
-- key1: pattern/file view
-- enc1: tempo
--
-- -- pattern view --
--
-- key2: add/cut/paste note
-- key3: cycle channel
--
-- enc2: edit position
--
-- key2+enc2: select note
-- key3+enc1: channel length
-- key3+enc2: transpose
-- channel
-- key3+enc3: shift(rotate)
-- notes on channel
--
-- -- file view --
-- 
-- key2: save selected
-- channel pattern
-- key3: load selected
-- channel pattern
--
-- enc2: select pattern
-- enc3: select channel
--
--
-- thanks to oliver wittchow for
-- making inspiring sequencing
-- interfaces. 

engine.name = "PolyPerc"

local sizex = 13
local sizey = 9
local spacingx = sizex + 2
local spacingy = sizey + 2
local centx = 64 - (sizex * 4 + 6) / 2
local centy = 32 - (sizey * 4 + 6) / 2
local level = 1
local length = {16,16,16,16}
local currentstep = {1,1,1,1}
local step = {{},
              {},
              {},
              {}}
local bpm = 120
local currentpos = 1
local notename = {"c","c:","d","d:","e","f","f:","g","g:","a","a:","b"}
local hold1 = 0
local hold2 = 0
local hold3 = 0
local copybuffer = {72,72,72,72}
local vischan = 1
local currentview = 1
local rem = 0
local movechan = 0
local channels = 4
local patterns = 8
local filebox = 8
local filepat = 1
local lastnote = {0,0,0,0}
m = midi.connect()


function init()
  for i=1,4 do
    for j=1,16 do
      table.insert(step[i], 0)
    end
  end
  counter = metro.init(count, 15 / bpm, -1)
  counter:start()
end

function savepattern()
  
end

function loadpattern()
  
end

function clearpattern(ch)
  step[ch] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  for i=1,4 do
    length[i] = 16
  end
end

function redraw()
  screen.clear()
  if currentview == 1 then
    patterndraw()
  elseif currentview == 2 then
    filedraw()
  end
  screen.update()
end

function enc(n,d)
  if currentview == 1 then
    patternenc(n,d)
  elseif currentview == 2 then
    fileenc(n,d)
  end
  redraw()
end

function key(n,z)
  if n == 1 and z == 1 then
    if currentview == 1 then
      currentview = 2
    elseif currentview == 2 then
      currentview = 1
    end
  end
  if currentview == 1 then
    patternkey(n,z)
  elseif currentview == 2 then
    filekey(n,z)
  end
  redraw()
end

function patterndraw()
  for i=1,length[vischan] do
    screen.rect(centx + spacingx * ((i-1) % 4),centy + spacingy * math.floor((i-1)/4),sizex,sizey)
    screen.level(i==currentstep[vischan] and 10 or step[vischan][i]>0 and 3 or 1)
    screen.fill()
    if step[vischan][i] > 0 then
      screen.move(centx - 6 + sizex / 2 + spacingx * ((i-1) %4), centy + 2 + sizey / 2 + spacingy * math.floor((i-1)/4))
      screen.level(0)
      screen.text(notename[(step[vischan][i]%12) + 1])
      screen.move(centx + 5 + sizex / 2 + spacingx * ((i-1) %4), centy + 2 + sizey / 2 + spacingy * math.floor((i-1)/4))
      screen.text_right(math.floor(step[vischan][i]/12))
    end
    if i == currentpos then
      screen.rect((centx + spacingx * ((currentpos-1) %4)), (centy + spacingy * math.floor((currentpos-1)/4)),sizex+1, sizey+1)
      screen.level(10)
      screen.stroke()
    end
  end
  screen.level(10)
  screen.move(8,8)
  screen.text(vischan)
  if hold2 == 0 and step[vischan][currentpos] == 0 then
    screen.level(1)
    screen.move(8,62)
    screen.text_center("add")
  elseif hold2 == 0 and step[vischan][currentpos] > 0 then
    screen.level(1)
    screen.move(8,62)
    screen.text_center("cut")
  end
  if hold3 == 0 then
    screen.level(10)
    screen.move(120,8)
    screen.text_right(bpm)
  end
  if hold3 == 0 and hold2 == 0 then
    screen.level(1)
    screen.move(30,62)
    screen.text_center("chn")
  end
  if hold2 == 0 and hold3 == 0 then
    screen.level(1)
    screen.move(82,62)
    screen.text_center("pos")
  elseif hold2 == 1 and hold3 == 0 then
    screen.level(1)
    screen.move(82,62)
    screen.text_center("note")
  elseif hold2 == 0 and hold3 == 1 then
    screen.level(1)
    screen.move(114,8)
    screen.text_center("length")
    screen.move(82,62)
    screen.text_center("trnsp")
    screen.move(114,62)
    screen.text_center("rotate")
  end
end

function patternenc(n,d)
  rem = d ~=0 and 0
  movechan = d ~=0 and 0
  if n == 1 and hold3 == 1 then
    length[vischan] = util.clamp(length[vischan] + d, 1, 16)
    if currentpos > length[vischan] then
      currentpos = length[vischan]
    end
    if currentstep[vischan] > length[vischan] then
      currentstep[vischan] = 1
    end
  elseif n == 1 and hold3 == 0 then
    counter.time = 15 / bpm
    bpm = util.clamp(bpm + d, 10, 500)
  elseif n == 2 and hold3 == 0 and hold2 == 0 and hold3 == 0 then
    currentpos = util.clamp(currentpos + d, 1, length[vischan])
  elseif n == 2 and hold3 == 0 and hold2 == 1 then
    step[vischan][currentpos] = util.clamp(step[vischan][currentpos] + d, 24, 96)
  end
  if n == 2 and hold3 == 1 then
    for i=1,length[vischan] do
      if step[vischan][i] > 0 then
        step[vischan][i] = util.clamp(step[vischan][i] + d, 24, 96)
      end
    end
  end
  if n == 3 and hold3 == 1 and d > 0 then
    table.insert(step[vischan], 1, step[vischan][16])
    table.remove(step[vischan], 17)
  elseif n == 3 and hold3 == 1 and d < 0 then
    table.insert(step[vischan], step[vischan][1])
    table.remove(step[vischan], 1)    
  end
end

function patternkey(n,z)
  if n == 2 and z == 1 and step[vischan][currentpos] > 0 then
    rem = 1
    hold2 = 1
  elseif n == 2 and z == 0 and step[vischan][currentpos] > 0 and rem == 1 then
    copybuffer[vischan] = step[vischan][currentpos]
    step[vischan][currentpos] = 0
    rem = 0
    hold2 = 0
  elseif n == 2 and z == 1 and step[vischan][currentpos] < 1 then
    step[vischan][currentpos] = copybuffer[vischan]
    hold2 = 1
  elseif n == 2 and z == 0 then
    hold2 = 0
  end
  if n == 3 and z == 1 then
    movechan = 1
    hold3 = 1
  elseif n == 3 and z == 0 and movechan == 1 then
    if vischan == 4 then
      vischan = 1
    else
      vischan = vischan + 1
    end
    movechan = 0
    hold3 = 0
  elseif n == 3 and z == 0 then
    hold3 = 0
  end
end

function filedraw()
  for i=1,channels do
    for j=1,patterns do
      screen.move(22 + (j*9),12 + (i*9))
      screen.level(file_exists(_path.data .. i .. "-" .. j .. ".no")==true and 10 or 2)
      screen.text_right(j)
      if vischan == i and filepat == j then
        screen.rect(17 + (j*9),6+(i*9), filebox-1, filebox)
        screen.level(10)
        screen.stroke()
      end
    end
  end
  screen.level(10)
  screen.move(120,8)
  screen.text_right(bpm)
  screen.level(1)
  screen.move(0,62)
  screen.text("save")
  screen.move(24,62)
  screen.text("load")
  screen.move(82,62)
  screen.text_center("pat")
  screen.move(114,62)
  screen.text_center("chn")
end

function file_exists(name)
      local f=io.open(name)
      if f ~=nil then io.close(f) return true else return false end
end

function fileenc(n,d)
  if n == 1 then
    counter.time = 15 / bpm
    bpm = util.clamp(bpm + d, 10, 500)
  end
  if n == 2 then
    filepat = util.clamp(filepat + d, 1, patterns)
  end
  if n == 3 then
    vischan = util.clamp(vischan + d, 1, channels)
  end
end

function filekey(n,z)
  local loaddata = {{},{}}
  if n == 2 and z == 1 then
    savedata = {step[vischan], length[vischan]}
    tab.save(savedata, _path.data .. vischan .. "-" .. filepat .. ".no")
  end
  if n == 3 and z == 1 then
    loaddata = tab.load(_path.data .. vischan .. "-" .. filepat .. ".no")
    if loaddata ~= nil then
      step[vischan] = loaddata[1]
      length[vischan] = loaddata[2]
    else
      clearpattern(vischan)
    end
  end
end

function midi_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end

function count()
  for i=1,4 do
    currentstep[i] = (currentstep[i] % length[i]) + 1
    if lastnote[i] > 0 then
      m:note_off(lastnote[i],127,i)
      lastnote[i] = 0
    end
    if step[i][currentstep[i]] > 0 then
      engine.hz(midi_to_hz(step[i][currentstep[i]]))
      m:note_on((step[i][currentstep[i]]),127,i)
      lastnote[i] = step[i][currentstep[i]]
    end
  end
  if currentpos > length[vischan] then
    currentpos = length[vischan]
  end
  redraw()
end