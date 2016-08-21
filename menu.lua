----------------------------------------------------------------------
-- Menu system
----------------------------------------------------------------------

local landscape_menu=true   -- should always be true

local ipos=-4
local time=0.7

local flashKey=1
local Keys={37,39,17}   -- default left, right, jump (ctrl)

KeyString={}
for i=1,255 do
  KeyString[i]="???"
end

for i=32,127 do
  KeyString[i]=string.char(i)
end

KeyString[16]="SHIFT"
KeyString[17]="CTRL"
KeyString[18]="ALT"
KeyString[32]="SPC"
KeyString[27]="ESC"
KeyString[37]="LEFT"
KeyString[39]="RIGHT"
KeyString[38]="UP"
KeyString[40]="DOWN"
KeyString[13]="ENTER"
KeyString[9]="TAB"
KeyString[8]="BSPACE"
KeyString[20]="C LOCK"
KeyString[219]="["
KeyString[221]="]"
KeyString[186]=";"
KeyString[192]="'"
KeyString[222]="#"
KeyString[188]=","
KeyString[190]="."
KeyString[191]="/"
KeyString[189]="-"
KeyString[187]="="
KeyString[223]="|"
KeyString[220]="\\"


function showbuttons(quick)
  if quick then
    rbutton:setScale(1,1)
    lbutton:setScale(1,1)

    rjbutton:setScale(1,1)
    ljbutton:setScale(1,1)
  else
    GTween.new(rbutton,1,{scaleX=1,scaleY=1},{ease=easing.outBounce})
    GTween.new(lbutton,1,{scaleX=1,scaleY=1},{ease=easing.outBounce})

    GTween.new(rjbutton,1,{scaleX=1,scaleY=1},{ease=easing.outBounce})
    GTween.new(ljbutton,1,{scaleX=1,scaleY=1},{ease=easing.outBounce})
  end
end

function hidebuttons()
  rbutton:setScale(0)
  lbutton:setScale(0)

  rjbutton:setScale(0)
  ljbutton:setScale(0)
end

local menu
local kill
local controls="left"
local controls_ht="down"
local menu_first=true
local nscale

-- touch listeners:
-- menu_start
-- menu_play
-- menu_edit
-- menu_options
-- options_controls
-- options_music
-- options_fx
-- options_manage
-- manage_prev
-- manage_next
-- goto_level
-- rmlevel
-- rmComplete
-- menu_credits
-- main_menu       (also callable from main.lua)

-- needs
-- lbutton,rbutton,ljbutton,rjbutton,inctext,dectext,inclevel,declevel
-- music, currmusic, musicstat, fxstat, trans

local frame=0

function menu_update(event)
  if graphics=="space" or graphics=="xmas" then
    nebula:setRotation(nebula:getRotation()-0.05)
  else
    updateStars()
  end

  if menu.name=="redefine_keys" then
    local r=math.sin(frame*0.1)^2
    menu:getChildAt(flashKey):getChildAt(2):setAlpha(r)
  end

  if menu.moving then
    menu:setY(100*math.sin(frame*0.01))
  end

  frame=frame+1
end

function updateStars()

  if landscape then
    for i=1,50 do
      local star=nebula:getChildAt(i)
      local y=star:getY()

      y=y+0.3
      if (y>screenw+50) then
        y=-50
      end

      star:setY(y)
    end
  else
    for i=1,50 do
      local star=nebula:getChildAt(i)
      local y=star:getY()

      y=y+0.3
      if (y>screenh+50) then
        y=-50
      end

      star:setY(y)
    end
  end

end

function menu_start(self,event)
  if self:hitTestPoint(event.x,event.y) then
    menu:removeFromParent()
    menu=nil

    menu_first=true
    stage:removeEventListener(Event.ENTER_FRAME, menu_update)

    showbuttons()

    ncoll=0
    trans=2
    loadlevel()
  end
end

----------------------------------------------------------------------

function menu_play(self,event)

  if (not self) or self:hitTestPoint(event.x,event.y) then
    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end

    menu=Sprite.new()
    menu.name="play"

    menu:addChild(Bitmap.new(help_tex))     -- display.newImage("help.png",0,0,true))

    menu:getChildAt(1):setAnchorPoint(0.5,0.5)
    menu:setAlpha(0)

    if landscape and landscape_menu then
--	 menu:getChildAt(1):setRotation(90)
      menu.moving=true
      menu:getChildAt(1):setPosition(240,160)
    else
      menu:getChildAt(1):setPosition(160,240)
    end

    stage:addChild(menu)

    GTween.new(menu,time,{alpha=1})
    GTween.new(ego,time,{x=430,y=50})

    kill=display.newImage("x.png",450,290)
    kill:addEventListener(Event.MOUSE_DOWN,main_menu,kill)

  end
end

----------------------------------------------------------------------

function menu_edit(self,event)

  if (not self) or self:hitTestPoint(event.x,event.y) then
    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end

    menu=Sprite.new()
    menu.name="edit"
    stage:addChild(menu)

    menu:addChild(Bitmap.new(howtoedit_tex))    -- display.newImage("howtoedit.png",0,0,true))
    menu:getChildAt(1):setAnchorPoint(0.5,0.5)
    menu:setAlpha(0)

    if landscape and landscape_menu then
      menu.moving=true
      menu:getChildAt(1):setPosition(240,160)
    else
      menu:getChildAt(1):setPosition(160,240)
    end

    GTween.new(menu,time,{alpha=1})
    GTween.new(ego,time,{x=50,y=50})

    kill=display.newImage("x.png",450,290)
    kill:addEventListener(Event.MOUSE_DOWN,main_menu,kill)
  end
end

----------------------------------------------------------------------

local noptions=7

function menu_options(self,event)
  local yst,pitch

  if (not self) or self:hitTestPoint(event.x,event.y) then
    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end

    if landscape and landscape_menu then
      GTween.new(ego,time,{x=50,y=160})
    else
      GTween.new(ego,time,{x=screenw/2,y=50})
    end

    menu=Sprite.new()
    menu.name="options"
    stage:addChild(menu)

    for i=1,noptions do
      menu:addChild(display.newGradRect(280,40, 255,0,0))
    end

    if string.sub(osname,1,7)=="Windows" or osname=="Win32" then
      menu:addChild(vtext(myfont,"REDEFINE KEYS"))
    else
      menu:addChild(vtext(myfont,"ADJUST CONTROLS"))
    end

    if (landscape) then
      menu:addChild(vtext(myfont,"LANDSCAPE"))
    else
      menu:addChild(vtext(myfont,"PORTRAIT"))
    end

    menu:addChild(vtext(myfont,"MUSIC: "..musicstat))
    menu:addChild(vtext(myfont,"SOUND FX: "..fxstat))
    menu:addChild(vtext(myfont,"MANAGE LEVELS"))
    menu:addChild(vtext(myfont,"GRAPHICS: "..graphics))

    menu:addChild(vtext(myfont,"RESET GAME"))

    yst=100
    pitch=50

    for i=1,noptions do
      y=yst+(i-1)*pitch
      menu:getChildAt(i):setPosition(160,y)
      menu:getChildAt(i+noptions):setPosition(60,y+5)
      menu:getChildAt(i+noptions):setTextColor(0xffffff)
    end

    local m1=menu:getChildAt(1)
    local m2=menu:getChildAt(2)
    local m3=menu:getChildAt(3)
    local m4=menu:getChildAt(4)
    local m5=menu:getChildAt(5)
    local m6=menu:getChildAt(6)
    local m7=menu:getChildAt(7)

--      m1:addEventListener(Event.MOUSE_DOWN,options_controls,m1)

    if string.sub(osname,1,7)=="Windows" or osname=="Win32" then
      m1:addEventListener(Event.MOUSE_DOWN,redefine_keys,m1)
    else
      m1:addEventListener(Event.MOUSE_DOWN,controls_set,m1)
    end

    m2:addEventListener(Event.MOUSE_DOWN,options_landscape,m2)
    m3:addEventListener(Event.MOUSE_DOWN,options_music,m3)
    m4:addEventListener(Event.MOUSE_DOWN,options_fx,m4)
    m5:addEventListener(Event.MOUSE_DOWN,options_manage,m5)
    m6:addEventListener(Event.MOUSE_DOWN,options_graphics,m6)
    m7:addEventListener(Event.MOUSE_DOWN,options_resetgame,m7)

    menu:setAlpha(0)
    GTween.new(menu,time,{alpha=1})

    if landscape and landscape_menu then
      menu:setPosition(95,-65)
      menu:setScale(0.9)
    end

    kill=display.newImage("x.png",30,440)
    if landscape and landscape_menu then
      kill:setPosition(440,290)
    end
    kill:addEventListener(Event.MOUSE_DOWN,main_menu,kill)
  end
end

function redefine_keys(self,event)
  if self:hitTestPoint(event.x,event.y) then
    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end

    menu=Sprite.new()
    menu.name="redefine_keys"
    stage:addChild(menu)

    if landscape then
      menu:setPosition(240,160)
    else
      menu:setPosition(160,240)
    end

    local m1=Sprite.new()
    m1:setPosition(0,-40)
    menu:addChild(m1)
    m1:addEventListener(Event.MOUSE_DOWN,flashKeySet,{m1,1})

    m1:addChild(display.newGradRect(200,30, 255,0,0))
    m1:addChild(TextField.new(myfont,"LEFT="..KeyString[Keys[1]]))
m1:getChildAt(2):setPosition(-80,5)
m1:getChildAt(2):setTextColor(0xFFFFFF)

local m2=Sprite.new()
m2:setPosition(0,0)
menu:addChild(m2)
m2:addEventListener(Event.MOUSE_DOWN,flashKeySet,{m2,2})

m2:addChild(display.newGradRect(200,30, 255,0,255))
m2:addChild(TextField.new(myfont,"RIGHT="..KeyString[Keys[2]]))
m2:getChildAt(2):setPosition(-80,5)
m2:getChildAt(2):setTextColor(0xFFFFFF)

local m3=Sprite.new()
m3:setPosition(0,40)
menu:addChild(m3)
m3:addEventListener(Event.MOUSE_DOWN,flashKeySet,{m3,3})

m3:addChild(display.newGradRect(200,30, 0,0,255))
m3:addChild(TextField.new(myfont,"JUMP="..KeyString[Keys[3]]))
m3:getChildAt(2):setPosition(-80,5)
m3:getChildAt(2):setTextColor(0xFFFFFF)

kill=display.newImage("x.png",30,300)
if not landscape then kill:setY(440) end

kill:addEventListener(Event.MOUSE_DOWN,menu_options,kill)

if landscape and landscape_menu then
  kill:setPosition(440,290)
end

end
end

function flashKeySet(data,event)
  self=data[1]
  if self:hitTestPoint(event.x,event.y) then
    flashKey=data[2]
    menu:getChildAt(1):getChildAt(2):setAlpha(1)
    menu:getChildAt(2):getChildAt(2):setAlpha(1)
    menu:getChildAt(3):getChildAt(2):setAlpha(1)
  end
end

function options_landscape(self,event)

  if self:hitTestPoint(event.x,event.y) then

    if (landscape) then
      application:setOrientation(Application.PORTRAIT)
      if osname=="Windows" or osname=="Win32" then application:setWindowSize(320,480) end
      landscape=false
      scrolling=false
      menu:getChildAt(noptions+2):setText("PORTRAIT")

      controls="left"
      controls_ht="down"

      set_controls()
      set_controls_ht()

    else
      application:setOrientation(Application.LANDSCAPE_LEFT)
      if osname=="Windows" or osname=="Win32" then application:setWindowSize(640,960) end
      landscape=true
      scrolling=true
      menu:getChildAt(noptions+2):setText("LANDSCAPE")

      if threebutton then
        controls="left"
      else
        controls="split"
      end

      controls_ht="down"

      set_controls()
      set_controls_ht()

    end

    fh=io.open("|D|config.txt","w")
    writeconfig(fh)
    fh:close()

    menu_options()
  end
end


function options_graphics(self,event)

  if (not self) or self:hitTestPoint(event.x,event.y) then
    local x,y=ego:getPosition()
    local rot=ego:getRotation()
    ego:removeFromParent()
    ego=nil

    if graphics=="space" then
      graphics="8bit"

      ego=display.newImage("ego8bit.png")
      ego.isEgo=true
      ego:setPosition(x,y)
      ego:setRotation(rot)
      ego:setScale(2,2)

      nebula:removeFromParent()

      nebula=Sprite.new()
      for i=1,50 do
        local star=display.newImage("star.png")
        local x=math.random(-50,screenh+50)
        local y=math.random(-50,screenw+50)
        star:setPosition(x,y)
        nebula:addChild(star)
      end

      stage:addChildAt(nebula,1)

    elseif graphics=="8bit" then
      graphics="xmas"

      ego=display.newImage("ego_xmas.png")
      ego.isEgo=true
      ego:setPosition(x,y)
      ego:setRotation(rot)
      ego:setScale(2,2)

      nebula:removeFromParent()

      nebula=display.newImage("tree.jpg")
      nebula:setPosition(screenh/2,screenw/2)

      stage:addChildAt(nebula,1)

    elseif graphics=="xmas" then
      graphics="space"

      ego=display.newImage("ego.png")
      ego.isEgo=true
      ego:setPosition(x,y)
      ego:setRotation(rot)
--	 ego:setScale(2,2)

      nebula:removeFromParent()

      nebula=display.newImage("hs_2004_10_a_large_web.jpg")
      nebula:setPosition(screenh/2,screenw/2)

      stage:addChildAt(nebula,1)
    end

    menu:getChildAt(noptions+6):setText("GRAPHICS: "..graphics)
  end
end

function options_resetgame(self,event)

  if (not self) or self:hitTestPoint(event.x,event.y) then
    popup({"Really reset?","All progress","will be lost","and user levels","deleted!"},
      {"No way!","Reset"},{nil,resetlevels})
  end
end

function options_controls_ht(self,event)

  if (not self) or self:hitTestPoint(event.x,event.y) then
    if controls_ht=="down" then
      controls_ht="mid"
    elseif controls_ht=="mid" then
      controls_ht="up"
    else
      controls_ht="down"
    end

    set_controls_ht(1)    -- on screen

    self:getChildAt(2):setText(controls_ht)

    fh=io.open("|D|config.txt","w")
    writeconfig(fh)
    fh:close()
  end
end

function set_controls_ht()
  if controls_ht=="mid" then
    if landscape then
      if threebutton then
        lbutton:setY(260)
        rbutton:setY(260)

        ljbutton:setY(260)
        rjbutton:setY(260)
      else
        lbutton:setY(260)
        rbutton:setY(260)

        ljbutton:setY(160)
        rjbutton:setY(160)
      end
    else
      if threebutton then
        lbutton:setY((screenh-80))
        rbutton:setY((screenh-80))
        ljbutton:setY((screenh-80))
        rjbutton:setY((screenh-80))
      else
        lbutton:setY((screenh-80))
        rbutton:setY((screenh-80))
        ljbutton:setY((screenh-180))
        rjbutton:setY((screenh-180))
      end
    end
  elseif controls_ht=="up" then
    if landscape then
      if threebutton then
        lbutton:setY(240)
        rbutton:setY(240)

        ljbutton:setY(240)
        rjbutton:setY(240)
      else
        lbutton:setY(240)
        rbutton:setY(240)

        ljbutton:setY(140)
        rjbutton:setY(140)
      end
    else
      if threebutton then
        lbutton:setY((screenh-120))
        rbutton:setY((screenh-120))
        ljbutton:setY((screenh-120))
        rjbutton:setY((screenh-120))
      else
        lbutton:setY((screenh-120))
        rbutton:setY((screenh-120))
        ljbutton:setY((screenh-220))
        rjbutton:setY((screenh-220))
      end
    end
  else
    if landscape then
      if threebutton then
        lbutton:setY(280)
        rbutton:setY(280)

        ljbutton:setY(280)
        rjbutton:setY(280)
      else
        lbutton:setY(280)
        rbutton:setY(280)

        ljbutton:setY(180)
        rjbutton:setY(180)
      end
    else
      if threebutton then
        lbutton:setY((screenh-40))
        rbutton:setY((screenh-40))
        ljbutton:setY((screenh-40))
        rjbutton:setY((screenh-40))
      else
        lbutton:setY((screenh-40))
        rbutton:setY((screenh-40))
        ljbutton:setY((screenh-140))
        rjbutton:setY((screenh-140))
      end

    end
  end

end

function options_controls(self,event)

  if (not self) or self:hitTestPoint(event.x,event.y) then
    if (controls=="left") then
      controls="right"
    elseif (controls=="right") then
      controls="split"
    else
      controls="left"
    end

    set_controls()

    self:getChildAt(2):setText(controls)

    fh=io.open("|D|config.txt","w")
    writeconfig(fh)
    fh:close()
  end
end

function set_controls()
  if controls=="right" then
    if landscape then
      if threebutton then
        lbutton:setX(340)
        ljbutton:setX(40)
        rbutton:setX(440)
        rjbutton:setX(40)
      else
        lbutton:setX(340)
        ljbutton:setX(340)
        rbutton:setX(440)
        rjbutton:setX(440)
      end
    else
      if threebutton then
        lbutton:setX(180)
        rbutton:setX(280)
        ljbutton:setX(40)
        rjbutton:setX(40)
      else
        lbutton:setX(180)
        rbutton:setX(280)
        ljbutton:setX(180)
        rjbutton:setX(280)
      end
    end
  elseif controls=="split" then
    if landscape then
      if threebutton then
        lbutton:setX(40)
        ljbutton:setX(340)
        rbutton:setX(340)
        rjbutton:setX(440)
      else
        lbutton:setX(40)
        ljbutton:setX(40)
        rbutton:setX(440)
        rjbutton:setX(440)
      end
    else
      if threebutton then
        lbutton:setX(40)
        rbutton:setX(180)
        ljbutton:setX(280)
        rjbutton:setX(280)
      else
        lbutton:setX(40)
        rbutton:setX(280)
        ljbutton:setX(40)
        rjbutton:setX(280)
      end
    end

  else       -- left
    if landscape then
      if threebutton then
        lbutton:setX(40)
        ljbutton:setX(440)
        rbutton:setX(140)
        rjbutton:setX(440)
      else
        lbutton:setX(40)
        ljbutton:setX(40)
        rbutton:setX(140)
        rjbutton:setX(140)
      end
    else
      if threebutton then
        lbutton:setX(40)
        rbutton:setX(140)
        ljbutton:setX(screenw-40)
        rjbutton:setX(screenw-40)
      else
        lbutton:setX(40)
        rbutton:setX(140)
        ljbutton:setX(40)
        rjbutton:setX(140)
      end
    end

  end

  lbutton:setRotation(0)
  rbutton:setRotation(0)
  ljbutton:setRotation(0)

  if threebutton then
    rjbutton:setRotation(-45)
  else
    rjbutton:setRotation(0)
  end

end

function options_music(self,event)

  local fh

  if self:hitTestPoint(event.x,event.y) then
    if (musicstat=="ON") then
      musicstat="OFF"

      music:stop()
      music=nil

    else
      musicstat="ON"

      local sound=Sound.new("Supernatural.mp3")
      music=sound:play(0,myhuge)
      music:setVolume(0.75)
      currmusic="Supernatural.mp3"
    end

    menu:getChildAt(noptions+3):setText("MUSIC: "..musicstat)

    fh=io.open("|D|config.txt","w")
    writeconfig(fh)
    fh:close()

  end
end

function options_fx(self,event)
  if self:hitTestPoint(event.x,event.y) then
    if (fxstat=="ON") then
      fxstat="OFF"
    else
      fxstat="ON"
    end

    menu:getChildAt(noptions+4):setText("SOUND FX: "..fxstat)

    fh=io.open("|D|config.txt","w")
    writeconfig(fh)
    fh:close()
  end
end

function controls_set(self,event)
  if (not self) or self:hitTestPoint(event.x,event.y) then
    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end

    menu=Sprite.new()
    menu.name="controls_set"
    stage:addChild(menu)

    if landscape then
      GTween.new(ego,0.5,{x=440,y=40})
    else
      GTween.new(ego,0.5,{x=290,y=80})
    end

    menu:addChild(TextField.new(myfont,"Drag controls to"))
    menu:addChild(TextField.new(myfont,"required position."))
    menu:addChild(TextField.new(myfont,"Or use default"))
    menu:addChild(TextField.new(myfont,"position buttons."))

    menu:addChild(TextField.new(myfont,"Drag controls to"))
    menu:addChild(TextField.new(myfont,"required position."))
    menu:addChild(TextField.new(myfont,"Or use default"))
    menu:addChild(TextField.new(myfont,"position buttons."))

    if landscape then
      for i=1,4 do
        menu:getChildAt(i):setPosition(10,i*20)
        menu:getChildAt(i):setTextColor(0x000000)
      end

      for i=1,4 do
        menu:getChildAt(i+4):setPosition(12,i*20-2)
        menu:getChildAt(i+4):setTextColor(0xffffff)
      end
    else
      for i=1,4 do
        menu:getChildAt(i):setPosition(10,20+i*20)
        menu:getChildAt(i):setTextColor(0x000000)
      end

      for i=1,4 do
        menu:getChildAt(i+4):setPosition(12,20+i*20-2)
        menu:getChildAt(i+4):setTextColor(0xffffff)
      end
    end

    local button1=Sprite.new()
    local button2=Sprite.new()
    local button3=Sprite.new()

    menu:addChild(button1)
    menu:addChild(button2)
    menu:addChild(button3)

    if landscape then
      button1:setPosition(60,110)
      button2:setPosition(160,110)
      button3:setPosition(260,110)
    else
      button1:setPosition(60,130)
      button2:setPosition(160,130)
      button3:setPosition(260,130)
    end

    button1:addChild(display.newRect(90,30,255,0,0))
    button2:addChild(display.newRect(90,30,255,255,0))
    button3:addChild(display.newRect(90,30,255,0,255))

    local t1=TextField.new(myfont,controls)
    local t2=TextField.new(myfont,controls_ht)

    local t3
    if threebutton then
      t3=TextField.new(myfont," 3x^")
    else
      t3=TextField.new(myfont," 4x^")
    end

    t1:setPosition(-35,5)
    t2:setPosition(-35,5)
    t3:setPosition(-35,5)

    button1:addChild(t1)
    button2:addChild(t2)
    button3:addChild(t3)

    button1:addEventListener(Event.MOUSE_DOWN,options_controls,button1)
    button2:addEventListener(Event.MOUSE_DOWN,options_controls_ht,button2)
    button3:addEventListener(Event.MOUSE_DOWN,options_3button,button3)

    rbutton:setScale(1)
    lbutton:setScale(1)

    rjbutton:setScale(1)
    ljbutton:setScale(1)

    rbutton:addEventListener(Event.MOUSE_DOWN,dragControlDown,rbutton)
    rbutton:addEventListener(Event.MOUSE_MOVE,dragControlMove,rbutton)
    rbutton:addEventListener(Event.MOUSE_UP,dragControlUp,rbutton)

    lbutton:addEventListener(Event.MOUSE_DOWN,dragControlDown,lbutton)
    lbutton:addEventListener(Event.MOUSE_MOVE,dragControlMove,lbutton)
    lbutton:addEventListener(Event.MOUSE_UP,dragControlUp,lbutton)

    rjbutton:addEventListener(Event.MOUSE_DOWN,dragControlDown,rjbutton)
    rjbutton:addEventListener(Event.MOUSE_MOVE,dragControlMove,rjbutton)
    rjbutton:addEventListener(Event.MOUSE_UP,dragControlUp,rjbutton)

    ljbutton:addEventListener(Event.MOUSE_DOWN,dragControlDown,ljbutton)
    ljbutton:addEventListener(Event.MOUSE_MOVE,dragControlMove,ljbutton)
    ljbutton:addEventListener(Event.MOUSE_UP,dragControlUp,ljbutton)

    if (landscape) then
      kill=display.newImage("x.png",440,90)
    else
      kill=display.newImage("x.png",300,40)
    end

    kill:addEventListener(Event.MOUSE_DOWN,controls_set_end,kill)

  end
end

function options_3button(self,event)
  if self:hitTestPoint(event.x,event.y) then
    if threebutton then   -- set 4 button
      self:getChildAt(2):setText(" 4x^")
      threebutton=false
      controls="left"
      controls_ht="down"
      set_controls()
      set_controls_ht()
      ljbutton:setVisible(true)

    else
      self:getChildAt(2):setText(" 3x^")
      threebutton=true
      controls="left"
      controls_ht="down"
      set_controls()
      set_controls_ht()
      ljbutton:setVisible(false)

    end

    local fh=io.open("|D|config.txt","w")
    writeconfig(fh)
    fh:close()
  end

end

function controls_set_end(self,event)
  if (not self) or self:hitTestPoint(event.x,event.y) then

    rbutton:removeEventListener(Event.MOUSE_DOWN,dragControlDown,rbutton)
    rbutton:removeEventListener(Event.MOUSE_MOVE,dragControlMove,rbutton)
    rbutton:removeEventListener(Event.MOUSE_UP,dragControlUp,rbutton)

    lbutton:removeEventListener(Event.MOUSE_DOWN,dragControlDown,lbutton)
    lbutton:removeEventListener(Event.MOUSE_MOVE,dragControlMove,lbutton)
    lbutton:removeEventListener(Event.MOUSE_UP,dragControlUp,lbutton)

    rjbutton:removeEventListener(Event.MOUSE_DOWN,dragControlDown,rjbutton)
    rjbutton:removeEventListener(Event.MOUSE_MOVE,dragControlMove,rjbutton)
    rjbutton:removeEventListener(Event.MOUSE_UP,dragControlUp,rjbutton)

    ljbutton:removeEventListener(Event.MOUSE_DOWN,dragControlDown,ljbutton)
    ljbutton:removeEventListener(Event.MOUSE_MOVE,dragControlMove,ljbutton)
    ljbutton:removeEventListener(Event.MOUSE_UP,dragControlUp,ljbutton)

    rbutton:setScale(0)
    lbutton:setScale(0)

    rjbutton:setScale(0)
    ljbutton:setScale(0)

    fh=io.open("|D|config.txt","w")
    writeconfig(fh)
    fh:close()

    menu_options()
  end
end

function dragControlDown(self,event)

  if self:hitTestPoint(event.x,event.y) then
    self.isFocus=true
    self.x0=event.x
    self.y0=event.y
    event:stopPropagation()
  end
end

function dragControlMove(self,event)
  if self.isFocus then

    local dx = event.x - self.x0
    local dy = event.y - self.y0

    self:setX(self:getX() + dx)
    self:setY(self:getY() + dy)

    self.x0 = event.x
    self.y0 = event.y

    event:stopPropagation()
  end
end

function dragControlUp(self,event)
  if self.isFocus then
    self.isFocus=false

    event:stopPropagation()
  end
end

function options_manage(self,event)
  if (not self) or self:hitTestPoint(event.x,event.y) then
    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end

    GTween.new(ego,time,{x=430,y=180})

    menu=Sprite.new()
    menu.name="options_manage"
    stage:addChild(menu)

    yst=50
    pitch=50

    n=math.min(7,totlevels-ipos+1)

----------------------------------------------------------------------
-- Rectangles
----------------------------------------------------------------------

    for i=1,n do
      ind=ipos+i-1
      menu:addChild(display.newRect(280,40, 1,1,1))
      menu:getChildAt(i):addEventListener(Event.MOUSE_DOWN,gotolevel,menu:getChildAt(i))

      if (ind <= nlevels) then
        if (ind < upto or (upto==nlevels)) then
          menu:getChildAt(i):setColorTransform(0,206,11)  -- green
        elseif (ind == upto) then
          menu:getChildAt(i):setColorTransform(254,112,23)  -- orange
        else
          menu:getChildAt(i):setColorTransform(255,0,0)  -- red
        end
      else
        menu:getChildAt(i):setColorTransform(0,0,255)  -- blue
      end
    end

----------------------------------------------------------------------
-- LEVEL text
----------------------------------------------------------------------

    for i=1,n do
      ind=ipos+i-1
      if (ind>0) then
		local label = vtext(myfont,"LEVEL "..ind)
        menu:addChild(label)
		if ind > nlevels then
			local upload_button = Bitmap.new(upload_tex)
			upload_button.ind = ind
			label:addChild(upload_button)
			upload_button:setScale(40/64)
			upload_button:setPosition(-60, -25)
			upload_button:addEventListener(Event.MOUSE_DOWN, function(e)
				if upload_button:hitTestPoint(e.x, e.y) then
					e:stopPropagation()
					local ind = upload_button.ind
					local levelname = "level"..ind..".txt"
					local coloursname = "colours"..ind..".txt"
					local dialog = TextInputDialog.new("level upload",
						levelname, "author - name", "Cancel", "OK")
					dialog:show()
					dialog:addEventListener(Event.COMPLETE, function(e)
						if e.buttonText == "OK" then
							print(levelname, coloursname)
							local file = io.open("|D|"..levelname)
							local level = file:read"*a"
							local file = io.open("|D|"..coloursname)
							local colours = file:read"*a"
							local data = colours..";"..level
							print(level, colours)
							local ok, err = levman.upload(e.text, data)
							local text = "`"..e.text.."` "
							if err then
								AlertDialog.new("upload error",
								text..err, "OK"):show()
							else
								AlertDialog.new("upload finished", text..
								"was successfully uploaded", "OK"):show()
							end
						end
					end)
				end
			end)
		end
      else
        menu:addChild(vtext(myfont,"TUTORIAL "..(ind+5)))
      end
    end

----------------------------------------------------------------------
-- Delete/reset buttons
----------------------------------------------------------------------

    for i=1,n do
      ind=ipos+i-1
      if (ind<upto or (upto==totlevels)) then
        if (ind<=nlevels) then
          menu:addChild(display.newImage("reset.png",0,0))
        else
          menu:addChild(display.newImage("X-DeleteLevel.png",0,0))
        end

        local num=menu:getNumChildren()

        menu:getChildAt(num):addEventListener(Event.MOUSE_DOWN,rmlevel,menu:getChildAt(num))
        menu:getChildAt(num):setX(280)
        menu:getChildAt(num):setY(yst+(i-1)*pitch)
      end
    end

----------------------------------------------------------------------
-- position everything
----------------------------------------------------------------------

    for i=1,n do
      y=yst+(i-1)*pitch
      menu:getChildAt(i):setPosition(160,y)
      menu:getChildAt(i+n):setPosition(80,y+5)
      menu:getChildAt(i+n):setTextColor(0xffffff)
    end

    menu:addChild(display.newImage("left.png",screenw-60,screenh-30))
    local num=menu:getNumChildren()
    menu:getChildAt(num):setScale(0.5,0.5)
    menu:getChildAt(num):addEventListener(Event.MOUSE_DOWN,manageprev,menu:getChildAt(num))

    menu:addChild(display.newImage("right.png",screenw-20,screenh-30))
    num=menu:getNumChildren()
    menu:getChildAt(num):setScale(0.5,0.5)
    menu:getChildAt(num):addEventListener(Event.MOUSE_DOWN,managenext,menu:getChildAt(num))

    if demo then
      local d=boldtext(myfont,"MORE LEVELS",0x0,0xff0000)
      menu:addChild(d)
      d:setPosition(50,420)

      d=boldtext(myfont,"IN FULL GAME!",0x0,0xff0000)
      menu:addChild(d)
      d:setPosition(50,440)
    end

    kill=display.newImage("x.png",30,440)
    kill:addEventListener(Event.MOUSE_DOWN,menu_options,kill)

    if landscape and landscape_menu then
      kill:setPosition(450,290)
    end

    menu:setAlpha(0)
    GTween.new(menu,time,{alpha=1})

    if landscape then
      menu:setScale(0.9)
      menu:setPosition(80,-20)
      menu:getChildAt(num):setPosition(420,280)
      menu:getChildAt(num-1):setPosition(360,280)
    end

  end
end

function manageprev(self,event)
  if self:hitTestPoint(event.x,event.y) then
    if ipos>-4 then
      menu:removeFromParent(); menu=nil
      kill:removeFromParent(); kill=nil

      ipos=ipos-7
      options_manage()
    end
  end
end

function managenext(self,event)

  if self:hitTestPoint(event.x,event.y) then
    if (ipos<=totlevels-7) then
      menu:removeFromParent(); menu=nil
      kill:removeFromParent(); kill=nil

      ipos=ipos+7
      options_manage()
    end
  end

end


function gotolevel(self,event)

  if self:hitTestPoint(event.x,event.y) then
    for i=1,7 do
      if (menu:getChildAt(i)==self) then
        if (i+ipos-1 > upto) then
          popup({"This level is","locked."},{"OK"},{nil})
          --	    native.showAlert("Error","This level is locked",{"OK"})
        else
          menu:removeFromParent()
          menu=nil

          kill:removeFromParent()
          kill=nil

          menu_first=true
          stage:removeEventListener(Event.ENTER_FRAME,menu_update)
          showbuttons()

          level=i+ipos-1

          ncoll=0
          trans=2
          loadlevel()
        end

        break
      end
    end

  end
end

local rmglobal

function rmlevel(self,event)

  if self:hitTestPoint(event.x,event.y) then

    local n=math.min(7,totlevels-ipos+1)

    for i=1,7 do
      if (menu:getChildAt(2*n+i)==self) then
        print ('delete',i,i+ipos-1)
        rmglobal=i+ipos-1
        if (rmglobal<=nlevels) then
          popup({"Really reset","level?","Are you sure?"},
            {"Reset","No way!"},{rmComplete,nil})
        else
          popup({"Really delete","level?","Are you sure?"},
            {"Delete","No way!"},{rmComplete,nil})
        end
        break
      end
    end

    event:stopPropagation()
  end
end

function rmComplete(event)  -- not a touch listener

  local contents,fh,path

  if (rmglobal<=nlevels) then
    path="level"..rmglobal..".txt"
    fh=io.open(path,"r")
    contents=fh:read("*a")
    fh:close()

    path="|D|level"..rmglobal..".txt"
    fh=io.open(path,"w")
    fh:write(contents)
    fh:close()

    path="colours"..rmglobal..".txt"
    fh=io.open(path,"r")
    contents=fh:read("*a")
    fh:close()

    path="|D|colours"..rmglobal..".txt"
    fh=io.open(path,"w")
    fh:write(contents)
    fh:close()

  else
    print ("Deleting user-level")
    for i=rmglobal,totlevels-1 do
      path="|D|level"..(i+1)..".txt"
      fh=io.open(path,"r")
      contents=fh:read("*a")
      fh:close()

      path="|D|level"..i..".txt"
      fh=io.open(path,"w")
      fh:write(contents)
      fh:close()

      path="|D|colours"..(i+1)..".txt"
      fh=io.open(path,"r")
      contents=fh:read("*a")
      fh:close()

      path="|D|colours"..i..".txt"
      fh=io.open(path,"w")
      fh:write(contents)
      fh:close()

    end  -- for i

    totlevels=totlevels-1
    upto=totlevels

    if level>totlevels then
      level=totlevels
    end

    path="|D|config.txt"
    fh=io.open(path,"w")
    writeconfig(fh)
--      fh:write(totlevels," ",totlevels)
    fh:close()

    menu:removeFromParent(); menu=nil
    kill:removeFromParent(); kill=nil

    ipos=-4
    options_manage()

  end
end

----------------------------------------------------------------------

local cheatcount

function menu_credits(self,event)

  if self:hitTestPoint(event.x,event.y) then

    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end

    menu=Sprite.new()
    menu.name="credits"
    stage:addChild(menu)

    menu:addChild(Bitmap.new(credits_tex))   -- display.newImage("credits.png",0,0,true))

    menu:getChildAt(1):setAnchorPoint(0.5,0.5)

    local rect=display.newRect(40,40, 0,0,0, 0)
    rect:setPosition(270,120)
    rect:addEventListener(Event.MOUSE_DOWN,cheat,rect)
    menu:addChild(rect)
    cheatcount=0

    if landscape and landscape_menu then
      menu.moving=true
      menu:getChildAt(1):setPosition(240,160)
    else
      menu:getChildAt(1):setPosition(160,240)
    end

    menu:setAlpha(0)
    GTween.new(menu,time,{alpha=1})
    GTween.new(ego,time,{x=50,y=50})

    kill=display.newImage("x.png",450,290)
    kill:addEventListener(Event.MOUSE_DOWN,main_menu,kill)

  end
end

local appW = application:getContentWidth()
local appH = application:getContentHeight()

local warning = Layout.new{
	absX = 0, absY = 0, absW = appW, absH = appH,
	bgrC = 0x000000, bgrA = 0.5,
	TextField.new(myfont, "", "-"),
}
warning(1):setTextColor(0xFFFFFF)
warning:addEventListener(Event.MOUSE_DOWN, warning.removeFromParent, warning)
warning:addEventListener(Event.MOUSE_MOVE, warning.removeFromParent, warning)
warning:addEventListener(Event.KEY_DOWN, warning.removeFromParent, warning)

local function showWarning(text)
	if not landscape then warning:update{absW = appH, absH = appW} end
	warning(1):setText(text)
	stage:addChild(warning)
end

local Button = Layout:with{
	text = "BUTTON",
	textColor = 0xFFFFFF,
	bgrC = 0xAA0000, bgrA = 1.0,
	sprM = Layout.FIT_HEIGHT, sprS = 0.10,
	
	init = function(self, p)
		self.textfield = TextField.new(myfont, self.text, "-")
		self.textfield:setTextColor(self.textColor)
		self:addChild(self.textfield)
	end,
	
	upd = function(self, p)
		if p.text then self.textfield:setText(p.text) end
	end,
	
	anPress = Layout.newAnimation(14, 7, 0.02),
	anHover = Layout.newAnimation(14, 7, 0.01),
	
	onPress = function(self)
		local data = levman.download(self.text)
		if data then
			local pos = data:find";"
			if pos then
				local colours = data:sub(1, pos-1)
				local level = data:sub(pos+1, -1)
				totlevels = totlevels + 1
				local path = "|D|level"..totlevels..".txt"
				local file =io.open(path,"w")
				file:write(level)
				file:close()
				local path = "|D|colours"..totlevels..".txt"
				local file =io.open(path,"w")
				file:write(colours)
				file:close()
				local path= "|D|config.txt"
				local file = io.open(path,"w")
				writeconfig(file)
				file:close()
				showWarning("saved as #"..totlevels)
			else
				showWarning(self.text.." is corrupted!")
			end
		else
			showWarning "connection error!"
		end
	end,
	
	anAdd = Layout.newAnimation(40, 0, 0.1)
}

function menu_levels(self,event)
  if self:hitTestPoint(event.x,event.y) then

    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end
	
	local count = levman.count()
	local MAX_NAMES_PER_REQUEST = 100
	local names = count and levman.names(1, count, MAX_NAMES_PER_REQUEST)

	if count and names then
		local database = {}
		for k,v in ipairs(names) do table.insert(database, {text = v}) end
		menu = Layout.new{
			bgrA = 0.0, bgrC = 0xFF00FF,
			absX = 0, absY = 0, absW = appW, absH = appH,
			cellAbsH = 40, cols = 1,
			borderW = 3, borderH = 3,
			template = Button, database = database, scroll = true,
		}
		if not landscape then menu:update{absW = appH, absH = appW} end
		Layout.select(menu)
	else
		showWarning "connection error!"
		menu = warning
	end
	
	stage:addChild(menu)

    menu:setAlpha(0)
    GTween.new(menu,time,{alpha=1})
    GTween.new(ego,time,{x=50,y=50})

    kill=display.newImage("x.png",450,290)
    kill:addEventListener(Event.MOUSE_DOWN,main_menu,kill)
	kill:addEventListener(Event.ENTER_FRAME,function()
		if kill then stage:addChild(kill) end
	end)

  end
end

function cheat(self,event)
  if self:hitTestPoint(event.x,event.y) then
    cheatcount=cheatcount+1

    if cheatcount==10 then
      local fh=io.open("|D|config.txt","r")
      local s=fh:read("*a")
      fh:close()

      s=string.gsub(s,"\n"," # ")

      local textInputDialog = TextInputDialog.new("config.txt", "Preserve # and spc", s, "Cancel", "OK")
      textInputDialog:addEventListener(Event.COMPLETE, cheatComplete)
      textInputDialog:show()
    end

  end
end

function cheatComplete(event)
  print ("buttonText",event.buttonText)
  if event.buttonText=="OK" then
    local s=event.text
    s=string.gsub(s," # ","\n")

    print ("writing config.txt")
    local fh=io.open("|D|config.txt","w")
    fh:write(s)
    fh:close()

    fh=io.open("|D|config.txt","r")
    readconfig(fh)
    fh:close()
  end
end

function main_menu(self,event)

  local yst,pitch,y,x

  if (not self) or self:hitTestPoint(event.x,event.y) then

    if landscape and landscape_menu then
      x=310
      y=30
    else
      x=160
      y=200
    end

    if graphics=="space" then
      GTween.new(ego,time,{x=x,y=y,scaleX=1,scaleY=1})
    else
      GTween.new(ego,time,{x=x,y=y,scaleX=2,scaleY=2})
    end

    if (musicstat=="ON" and currmusic ~= "Supernatural.mp3") then
      if (music) then
        music:stop()
        music=nil
      end

      local sound=Sound.new("Supernatural.mp3")
      music=sound:play(0,myhuge)
      music:setVolume(0.75)
      currmusic="Supernatural.mp3"
    end

    if (menu) then
      menu:removeFromParent()
    end

    if (kill) then
      kill:removeFromParent()
      kill=nil
    end

    if (menu_first) then
      stage:addEventListener(Event.ENTER_FRAME,menu_update)
      menu_first=false
      nscale=0
    end

    menu=Sprite.new()

    if landscape and landscape_menu then
      menu:addChild(display.newImage("retrov.png",0,0))
    else
      menu:addChild(display.newImage("retro.png",0,0))
    end

    if graphics=="space" then
      menu:addChild(display.newImage("baddy.png",0,0))
      menu:addChild(display.newImage("baddy.png",0,0))
    elseif graphics=="xmas" then
      menu:addChild(display.newImage("baddy_xmas.png",0,0))
      menu:addChild(display.newImage("baddy_xmas.png",0,0))
    else
      menu:addChild(display.newImage("baddy8bit.png",0,0))
      menu:addChild(display.newImage("baddy8bit.png",0,0))
    end

    menu:addChild(display.newGradRect(280,35, 255,0,0))
    menu:addChild(display.newGradRect(280,35, 255,0,0))
    menu:addChild(display.newGradRect(280,35, 255,0,0))
    menu:addChild(display.newGradRect(280,35, 255,0,0))
    menu:addChild(display.newGradRect(280,35, 255,0,0))
	menu:addChild(display.newGradRect(280,35, 255,0,0))

    menu:addChild(vtext(myfont,"START!"))
    menu:addChild(vtext(myfont,"HELP!(SPOILERS)"))
    menu:addChild(vtext(myfont,"HOW TO EDIT"))
    menu:addChild(vtext(myfont,"OPTIONS"))
    menu:addChild(vtext(myfont,"CREDITS"))
	menu:addChild(vtext(myfont,"DOWNLOAD LEVELS"))

    if landscape and landscape_menu then
      menu:getChildAt(1):setPosition(90,170)
    else
      menu:getChildAt(1):setPosition(160,100)
    end

    menu:getChildAt(2):setPosition(100,200)
    menu:getChildAt(3):setPosition(220,200)

    if (landscape and landscape_menu) then
      menu:getChildAt(2):setPosition(250,30)
      menu:getChildAt(3):setPosition(370,30)
    end

    if graphics ~= "space" then
      menu:getChildAt(2):setScale(2,2)
      menu:getChildAt(3):setScale(2,2)
    end

    if landscape and landscape_menu then
      x=310
      yst=80
      pitch=40
    else
      x=160
      yst=250
      pitch=40
    end

    for i=1,6 do
      y=yst+(i-1)*pitch
      menu:getChildAt(i+3):setPosition(x,y)
      menu:getChildAt(i+9):setTextColor(0xffffff)
      centreAt(menu:getChildAt(i+9),x,y)  --text
    end

    local m4=menu:getChildAt(4)
    local m5=menu:getChildAt(5)
    local m6=menu:getChildAt(6)
    local m7=menu:getChildAt(7)
    local m8=menu:getChildAt(8)
	local m9=menu:getChildAt(9)

    m4:addEventListener(Event.MOUSE_DOWN,menu_start,m4)
    m5:addEventListener(Event.MOUSE_DOWN,menu_play,m5)
    m6:addEventListener(Event.MOUSE_DOWN,menu_edit,m6)
    m7:addEventListener(Event.MOUSE_DOWN,menu_options,m7)
    m8:addEventListener(Event.MOUSE_DOWN,menu_credits,m8)
	m9:addEventListener(Event.MOUSE_DOWN,menu_levels,m9)

    if demo then
      local m9= boldtext(myfont,"DEMO VERSION",0x0,0xff0000)
      menu:addChild(m9)
      m9:setPosition(60,150)
    end

    stage:addChild(menu)

    menu:setAlpha(0)
    GTween.new(menu,time,{alpha=1})

  end

end

--######################################################################

popup_sprite=nil

function popup_block(event)
  event:stopPropagation()
end

function popup(text,btext,func,extra)

-- popup({"Hello","World"},{"OK","Cancel"},{foo,bar})
-- Hello
-- World
-- [OK]   => foo
--[Cancel]  => bar  (use nil to do nothing)
-- extra: .bitmap, .x, .y

  local panel_width=260
  local bwidth,bheight,pitch,tpitch=150,30,40,30

  if popup_sprite then
    popup_sprite:removeFromParent()
    popup_sprite=nil
  end

  popup_sprite=Sprite.new()

  panel_height=#text*tpitch+#btext*pitch

----------------------------------------------------------------------
-- big rect to screen touches
---------------------------------------------------------------------- 

  local rect=Shape.new()

  rect:setFillStyle(Shape.SOLID,0,0.5)

  rect:beginPath()
  rect:moveTo(-screenh,-screenh)
  rect:lineTo(screenh,-screenh)
  rect:lineTo(screenh,screenh)
  rect:lineTo(-screenh,screenh)
  rect:closePath()
  rect:endPath()

  rect:setPosition(screenw/2,screenh/2)

  rect:addEventListener(Event.MOUSE_DOWN,popup_block)
  rect:addEventListener(Event.MOUSE_MOVE,popup_block)
  rect:addEventListener(Event.MOUSE_UP,popup_block)

  rect:addEventListener(Event.TOUCHES_BEGIN,popup_block)
  rect:addEventListener(Event.TOUCHES_MOVE,popup_block)
  rect:addEventListener(Event.TOUCHES_END,popup_block)

  popup_sprite:addChild(rect)

----------------------------------------------------------------------
-- panel
----------------------------------------------------------------------

  rect=Shape.new()
  rect:setFillStyle(Shape.SOLID,0)
  rect:setLineStyle(5,0xffffff)

  rect:beginPath()
  rect:moveTo(-panel_width/2,-panel_height/2-10)
  rect:lineTo( panel_width/2,-panel_height/2-10)
  rect:lineTo( panel_width/2, panel_height/2+10)
  rect:lineTo(-panel_width/2, panel_height/2+10)
  rect:closePath()
  rect:endPath()

  rect:setPosition(screenw/2,screenh/2)

  popup_sprite:addChild(rect)

----------------------------------------------------------------------
-- Text
----------------------------------------------------------------------

  local y=screenh/2-panel_height/2+15

  for i=1,#text do
    local t=TextField.new(myfont,text[i])

    t:setPosition(screenw/2-panel_width/2+15,y)
    t:setTextColor(0xffffff)

    popup_sprite:addChild(t)

    y=y+tpitch
  end

----------------------------------------------------------------------
-- extra
----------------------------------------------------------------------

  if extra then
    local bm=Bitmap.new(Texture.new(extra.bitmap,true))
    bm:setAnchorPoint(0.5,0.5)
    bm:setPosition(extra.x,extra.y)
    bm:setRotation(extra.rotation)
    popup_sprite:addChild(bm)
  end

----------------------------------------------------------------------
-- Buttons
----------------------------------------------------------------------

  for i=1,#btext do

    rect=Shape.new()

    rect:setFillStyle(Shape.SOLID,0xff0000)
--      rect:setLineStyle(5,0xffffff)

    rect:beginPath()
    rect:moveTo(-bwidth/2,-bheight/2)
    rect:lineTo( bwidth/2,-bheight/2)
    rect:lineTo( bwidth/2, bheight/2)
    rect:lineTo(-bwidth/2, bheight/2)
    rect:closePath()
    rect:endPath()

    rect:setPosition(screenw/2,y)
    rect:addEventListener(Event.MOUSE_DOWN,popup_kill,{rect,func[i]})

    popup_sprite:addChild(rect)

    local t=TextField.new(myfont,btext[i])

    t:setTextColor(0xffffff)
    centreAt(t,screenw/2,y)

    popup_sprite:addChild(t)

    y=y+pitch
  end

  if landscape and (not menu or landscape_menu) then
    popup_sprite:setPosition(screenh/2-screenw/2,screenw/2-screenh/2)
  end

  stage:addChild(popup_sprite)

end

function popup_kill(table,event)
  local self,func=table[1],table[2]

  if self:hitTestPoint(event.x,event.y) then
    event:stopPropagation()
    popup_sprite:removeFromParent()
    popup_sprite=nil

    if func then 
      func()
    end
  end

end

-- normally used for textfields
function centreAt(sprite,x,y)
  local w=sprite:getWidth()
  local h=sprite:getHeight()

  sprite:setPosition(math.floor(x-w/2),math.floor(y+h/2))
end

-- add 5 tutorial levels
-- collect coin -4
-- jump short   -3
-- jump long    -2
-- roll up      -1
-- set controls  0

function resetlevels()

-- overwrite config.txt file set to (nlevels -4)
-- reset total number of levels
-- overwrite all level files from resource

  local path,contents,fh

  readsign=false

  level=-4
  totlevels=nlevels
  upto=-4

  fh=io.open("|D|config.txt","w")
  writeconfig(fh)
  fh:close()

  for i=-4,nlevels do
    path="level"..i..".txt"
    fh=io.open(path,"r")
    contents=fh:read("*a")
    fh:close()

    path="|D|level"..i..".txt"
    fh=io.open(path,"w")
    fh:write(contents)
    fh:close()

    path="colours"..i..".txt"
    fh=io.open(path,"r")
    contents=fh:read("*a")
    fh:close()

    path="|D|colours"..i..".txt"
    fh=io.open(path,"w")
    fh:write(contents)
    fh:close()
  end
end

-- needs to cope if file is old style "1 10"
function readconfig(fh)
  totlevels,upto=fh:read("*number","*number")

  if (not totlevels) then
    totlevels=nlevels
  end

  if (not upto) then
    upto=-4
  end

  fh:read("*line")

  musicstat=fh:read("*line")
  if (musicstat~="ON" and musicstat~="OFF") then
    musicstat="ON"
  end

  fxstat=fh:read("*line")
  if (fxstat~="ON" and fxstat~="OFF") then
    fxstat="ON"
  end

  controls=fh:read("*line")
  if (controls~="left" and controls~="split" and controls~="right") then
    controls="left"
  end

  controls_ht=fh:read("*line")
  if (controls_ht~="down" and controls_ht~="mid" and controls_ht~="up") then
    controls_ht="down"
  end

  -- recently added landscape and manual control position

  landscape=fh:read("*line")=="true"

  if landscape then 
    scrolling=true 
    application:setOrientation(Application.LANDSCAPE_LEFT)
    if osname=="Windows" or osname=="Win32" then application:setWindowSize(640,960) end
  else
    scrolling=false
    application:setOrientation(Application.PORTRAIT)
    if osname=="Windows" or osname=="Win32" then application:setWindowSize(320,480) end
  end

  local x1,y1,x2,y2,x3,y3,x4,y4

  x1,y1=fh:read("*number","*number")
  x2,y2=fh:read("*number","*number")
  x3,y3=fh:read("*number","*number")
  x4,y4=fh:read("*number","*number")

  fh:read("*line")
  zoom_note=fh:read("*line")=="true"

  threebutton=fh:read("*line")=="true"

  readsign=fh:read("*line")=="true"

  Keys[1],Keys[2],Keys[3]=fh:read("*number","*number","*number")

  if (not Keys[1]) then
    Keys[1]=37
    Keys[2]=39
    Keys[3]=17
  end

  set_controls()
  set_controls_ht()

  if x1 and x2 and x3 and x4 and y1 and y2 and y3 and y4 then
    lbutton:setPosition(x1,y1)
    rbutton:setPosition(x2,y2)

    ljbutton:setPosition(x3,y3)
    rjbutton:setPosition(x4,y4)
  end

  print (totlevels,upto)
  print (musicstat)
  print (fxstat)
  print (controls)
  print (controls_ht)
  print (landscape)
  print (x1,y1)
  print (x2,y2)
  print (x3,y3)
  print (x4,y4)
  print (zoom_note)
  print ("threebutton=",threebutton)
  print ("readsign=",readsign)
  print ("Keys=",Keys[1],Keys[2],Keys[3])
end

function writeconfig(fh)
  fh:write(totlevels," ",upto,"\n")
  fh:write(musicstat,"\n")
  fh:write(fxstat,"\n")
  fh:write(controls,"\n")
  fh:write(controls_ht,"\n")

  if landscape then
    fh:write("true\n")
  else
    fh:write("false\n")
  end

  local x,y

  x,y=lbutton:getPosition()
  fh:write(x," ",y,"\n")

  x,y=rbutton:getPosition()
  fh:write(x," ",y,"\n")

  x,y=ljbutton:getPosition()
  fh:write(x," ",y,"\n")

  x,y=rjbutton:getPosition()
  fh:write(x," ",y,"\n")

  if zoom_note then
    fh:write("true\n")
  else
    fh:write("false\n")
  end

  if threebutton then
    fh:write("true\n")
  else
    fh:write("false\n")
  end

  if readsign then
    fh:write("true\n")
  else
    fh:write("false\n")
  end

  fh:write(Keys[1]," ",Keys[2]," ",Keys[3],"\n")

end

function initlevels()

-- if level file does not exist copy it from resources
-- overwrite config file with max(nlevels,totlevels from file)
-- eg 10 std levels and user hass written 4: 14 levels
-- added new level so 11 std but leave at 14 (do not change level 11)
-- eg 10 std levels no user levels: 10 levels
-- added new level so 11 std levels, change totlevels to 11 (copy level 11)

  local path,contents,fh

  fh=io.open("|D|config.txt","r")

  if (fh) then
    readconfig(fh)
    fh:close()

    if nlevels>totlevels then   -- eg I have added levels
      totlevels=nlevels
    end
  else
--      local osname,version,idiom,model=application:getDeviceInfo()
    print(osname,version,idiom,model)

    totlevels=nlevels
    upto=-4

    if (model=="iPad") then
      controls="split"
      landscape=false
      scrolling=false
      threebutton=false
    else
      controls="left"
      landscape=true
      scrolling=true
      threebutton=true
    end

    set_controls()
    set_controls_ht()

  end

  fh=io.open("|D|config.txt","w")
  writeconfig(fh)
  fh:close()

  for i=-4,nlevels do

    fh=io.open("|D|level"..i..".txt")
    if (fh) then
      fh:close()
    end

    if (not fh) then

      path="level"..i..".txt"
      fh=io.open(path,"r")
      contents=fh:read("*a")
      fh:close()

      path="|D|level"..i..".txt"
      fh=io.open(path,"w")
      fh:write(contents)
      fh:close()

      path="colours"..i..".txt"
      fh=io.open(path,"r")
      contents=fh:read("*a")
      fh:close()

      path="|D|colours"..i..".txt"
      fh=io.open(path,"w")
      fh:write(contents)
      fh:close()
    end
  end

end

function vtext(fnt,str)
  return TextField.new(fnt,str)
end

local activeKey

function onKeyDown(event)

  print ("keycode=",event.keyCode,menu)

  if menu and menu.name=="redefine_keys" then
    Keys[flashKey]=event.keyCode
    menu:getChildAt(1):getChildAt(2):setText("LEFT="..KeyString[Keys[1]])
  menu:getChildAt(2):getChildAt(2):setText("RIGHT="..KeyString[Keys[2]])
menu:getChildAt(3):getChildAt(2):setText("JUMP="..KeyString[Keys[3]])

fh=io.open("|D|config.txt","w")
writeconfig(fh)
fh:close()

elseif event.keyCode==KeyCode.BACK then

if popup_sprite then
  popup_sprite:removeFromParent()
  popup_sprite=nil
  return
end

if not menu then
  if playing then
    onpause()
  end
elseif (menu.name=="play" or menu.name=="edit" or menu.name=="credits" or menu.name=="options") then
  main_menu()
elseif (menu.name=="controls_set") then
  controls_set_end()
elseif (menu.name=="options_manage") then
  menu_options()
end
elseif event.keyCode==Keys[1] then
leftpressed=true
rightpressed=false
activeKey=event.keyCode
elseif event.keyCode==Keys[2] then
leftpressed=false
rightpressed=true
activeKey=event.keyCode
elseif playing and event.keyCode==Keys[3] then
if onground or ring then

  local gx,gy=world:getGravity()
  local vx=ego.body:getLinearVelocity()

  if (gy>0) then
    ego.body:setLinearVelocity(vx,-7.0)
  else
    ego.body:setLinearVelocity(vx, 7.0)
  end
end

end

end

function onKeyUp(event)
  if event.keyCode==activeKey then
    leftpressed=false
    rightpressed=false
  end
end

function boldtext(font,text,col1,col2)
  local s=Sprite.new()

  s:addChild(TextField.new(font,text))
  s:addChild(TextField.new(font,text))

  s:getChildAt(1):setPosition(0,0)
  s:getChildAt(1):setTextColor(col1)

  s:getChildAt(2):setPosition(1,1)
  s:getChildAt(2):setTextColor(col2)

  return s
end