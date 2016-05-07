-- GIDEROS version
-- edited with emacs
-- Runs on gideros 2016.4

-- Currently when running on Windows (desktop) the game is landscape only
-- (hence no level editting)
-- and landscape/portrait option has been disabled
-- see
--      m2:addEventListener(Event.MOUSE_DOWN,options_landscape,m2) (menu.lua)
-- Also if "Windows" OS then we disable soft controls and there is
-- a Redefine Keys menu instead of Adjust Controls
-- We should check for all desktop types not just Windows
-- by desktop I mean devices with physical keyboards which are landscape only
-- (Windows, Mac, HTML5 - presumably this is "desktop")

-- Later need to fix this so that we can switch between portrait
-- and landscape in Windows by changing the window size/shape
-- currently not supported in Gideros (fix it!)

myfont=Font.new("zxspectr.txt","zxspectr.png",true)
--myfont=TTFont.new("zxspectr.ttf",16,true)

application:setFps(60)

osname,version,idiom,model=application:getDeviceInfo()
print(osname,version,idiom,model) -- eg iOS 6.1.3 iPad iPad
                                  --    Android 2.3.4 nil nil

osname="Android"  -- force this for now (see above)
print("Forced to: ",osname)

function print()
end

local display=require("display")
require("box2d")
require("new")
require("menu")

application:setBackgroundColor(rgb(20,20,20))
world=b2.World.new(0.0,9.8)

myhuge=1000

inclevel,declevel,inctext,dectext=nil,nil,nil,nil
local signtext,hint,sign,shield,hat
ring=nil

local platbuttonv,icebuttonv,movplatbutton,linkbutton
local makebutton,coinbutton,platbutton,vbadbutton,hbadbutton
local Sbadbutton,cratebutton
local Gcratebutton,Bcratebutton,icebutton

lbutton,rbutton,ljbutton,rjbutton=nil,nil,nil,nil

editbutton=nil
editbuttontext="edit"
scene=nil
scrolling=false
sscale=2
egox_global,egoy_global=nil,nil
landscape=true
oldscenex,oldsceney=nil,nil
zoom=nil
zoomedOut=nil
x0,y0=nil,nil
zoom_note=nil

multitouch=true         -- should always be true
threebutton=false
readsign=false
playing=false

onground=nil
local newplanet,ncoll
local sparkle

local radius=10
local baddyrad=10
local coinrad=10
local butrad=50           -- button radius when playing
local ebutrad=30           -- button radius when editing (tighter)

local egobaddy=radius+baddyrad
local egocoin=radius+coinrad

trans=0

level=1
nlevels=26       -- normally 26
totlevels=nil
upto=nil
demo=false

local collected,leveltxt

local edit=false

screenw=320      -- logical dimensions
screenh=480

leftpressed=false
rightpressed=false

music,currmusic=nil,nil
musicstat="ON"
fxstat="ON"
graphics="space"
local mode,pause
modestate="S"

----------------------------------------------------------------------
-- sound assets
----------------------------------------------------------------------

local beepsound=Sound.new("cling_1.wav")  -- previously beep.wav
local beepsound2=Sound.new("cling_2.wav")
local diesound=Sound.new("sound108.wav")
local bdiesound=Sound.new("sound98.wav")
local bumpsound=Sound.new("sound97.wav")
local scream=Sound.new("WilhelmScream.wav")
local victory=Sound.new("sound106.wav")
local rocket=Sound.new("sound10.mp3")
local antigrav=Sound.new("sound5.mp3")
local touchsound=Sound.new("sound118.wav")

----------------------------------------------------------------------
-- Preload graphics textures
----------------------------------------------------------------------

help_tex=Texture.new("help.png",true)
credits_tex=Texture.new("credits.png",true)
howtoedit_tex=Texture.new("howtoedit.png",true)
signunderlay_tex=Texture.new("SIGN-UNDERLAY.png",true)
gotit_tex=Texture.new("Got-it.png",true)
signtext_tex=nil

----------------------------------------------------------------------
-- Create ego, nebula and planet which will persist throughout game
----------------------------------------------------------------------

nebula=display.newImage("hs_2004_10_a_large_web.jpg")

planet=display.newImage("p1.png")
ego=display.newImage("ego.png")

ego.isEgo=true

nebula:setPosition(240,160)
planet:setPosition(240,160)

----------------------------------------------------------------------
-- debug draw if necessary
----------------------------------------------------------------------

--local debugDraw=b2.DebugDraw.new()
--world:setDebugDraw(debugDraw)
--stage:addChild(debugDraw)


--######################################################################

function hsv2rgb(h, s, v)

   -- h=[0,180], s=[0,1], v=[0,100]
   -- r,b,g=[0,255]

   local h60,h60f,hi,f,p,q,t,r,g,b

   h=h*2 -- added JFB
   v=v/100

   h60 = h / 60.0
   h60f = math.floor(h60)
   hi = h60f % 6
   f = h60 - h60f
   p = v * (1 - s)
   q = v * (1 - f * s)
   t = v * (1 - (1 - f) * s)
   r, g, b = 0, 0, 0

   if (hi == 0) then 
      r, g, b = v, t, p
   elseif (hi == 1) then
      r, g, b = q, v, p
   elseif (hi == 2) then
      r, g, b = p, v, t
   elseif (hi == 3) then
      r, g, b = p, q, v
   elseif (hi == 4) then
      r, g, b = t, p, v
   elseif (hi == 5) then
      r, g, b = v, p, q
   end

   r, g, b = math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
   return r, g, b
end
    
function rgb2hsv(r, g, b)

   local mx,mn,df,h,s,v

   r, g, b = r/255.0, g/255.0, b/255.0
   mx = math.max(r, g, b)
   mn = math.min(r, g, b)
   df = mx-mn
   if mx == mn then
      h = 0
   elseif mx == r then
      h = (60 * ((g-b)/df) + 360) % 360
   elseif mx == g then
      h = (60 * ((b-r)/df) + 120) % 360
   elseif mx == b then
      h = (60 * ((r-g)/df) + 240) % 360
   end

   if mx == 0 then
      s = 0
   else
      s = df/mx
   end

   v = mx

   h=h/2  -- added JFB range of hue is [0,180]
   v=v*100 -- range [0,100]

   return h, s, v
end

function onpause(self,event)

   if (not self) or self:hitTestPoint(event.x,event.y) then

      hidebuttons()

      planet:setVisible(false)

      trans=-1
      killlevel()
      main_menu()
   end
end


--######################################################################

function onsave()

----------------------------------------------------------------------
-- Save current level
----------------------------------------------------------------------

  local ntot,path,fh,ch,ind

    path="|D|level"..level..".txt"
    fh=io.open(path,"w")

    path="|D|colours"..level..".txt"
    ch=io.open(path,"w")

    fh:write(planet:getX()," ",planet:getY(),"\n")

    ntot=0
    for i=1,ncoins do
      if (not coin[i].deleted) then
         ntot=ntot+1
      end
    end

    fh:write("ncoins\n",ntot,"\n")

    for i=1,ncoins do 
      if (not coin[i].deleted) then
        fh:write(coin[i]:getX()," ",coin[i]:getY(),"\n")
      end
    end

----------------------------------------------------------------------

    ntot=0
    for i=1,nbaddy do
      if (not baddy[i].deleted) then
         ntot=ntot+1
      end
    end

    fh:write("nbaddy\n",ntot,"\n")

    for i=1,nbaddy do
      if (not baddy[i].deleted) then
        fh:write(baddy[i]:getX()," ",baddy[i]:getY()," ",baddy[i].dir," ",
                 baddy[i].start," ",baddy[i].ends," ",baddy[i].speed,"\n")
      end
    end

----------------------------------------------------------------------
-- go over platforms. If one is linked to a deleted platform, then
-- remove link. In case where platforms have been renumbered
-- due to delete account for this
----------------------------------------------------------------------

    for i=1,nplatform do
       local n = platform[i].link
       if (n <= nplatform) then
	  if (platform[n].deleted) then
	     platform[i].link=255
	  else
	     ind=0
	     for j=1,n do
		if not platform[j].deleted then
		   ind=ind+1
		end
	     end

	     platform[i].link=ind
	  end
       end
    end

----------------------------------------------------------------------
-- if platform is not deleted and also its core is not deleted (moving)
-- then its a real platform
----------------------------------------------------------------------

    ntot=0
    for i=1,nplatform do
       if (not platform[i].deleted) then
	  if (platform[i].ismoving) then
	     if (not platform[i].core.deleted) then
		ntot=ntot+1
	     end
	  else
	     ntot=ntot+1
	  end
       end
    end

    fh:write("nplatform\n",ntot,"\n")
    
    for i=1,nplatform do
      if (not platform[i].deleted) then
	 if (platform[i].ismoving) then
	    if (not platform[i].core.deleted) then
	       fh:write(platform[i]:getX()," ",platform[i]:getY()," ",platform[i].width," ",
			platform[i].height," ",platform[i]:getRotation(),"\n")

	       ch:write(platform[i].red," ",platform[i].green," ",platform[i].blue,
			" ",platform[i].link,"\n")
	    end
	 else
	    fh:write(platform[i]:getX()," ",platform[i]:getY()," ",
		     platform[i].width," ",
		     platform[i].height," ",platform[i]:getRotation(),"\n")

	    ch:write(platform[i].red," ",platform[i].green," ",platform[i].blue,
		     " ",platform[i].link,"\n")
	 end

      end
    end

----------------------------------------------------------------------

    fh:write("ego\n")
    fh:write(ego:getX()," ",ego:getY(),"\n")

----------------------------------------------------------------------

    ntot=0
    for i=1,ncrate do
      if (not crate[i].deleted) then
         ntot=ntot+1
      end
    end

    fh:write("ncrate\n",ntot,"\n")

    for i=1,ncrate do
      if (not crate[i].deleted) then
	 if (crate[i].isblue=="yes" or crate[i].isblue=="inactive") then
	    ind=1
	 elseif (crate[i].isgreen=="yes" or crate[i].isgreen=="inactive") then
	    ind=2
	 else
	    ind=0
	 end

	 fh:write(crate[i]:getX()," ",crate[i]:getY()," ",crate[i].width," ",crate[i].height," ",
		  crate[i]:getRotation()," ",ind,"\n")
      end
    end

    fh:close()
    ch:close()

    print ("saved")
end


--####################################################################

-- coin, crate, platform, spinning baddy, ego shift

function dragDown(self,event)

   -- do not take focus if we are tapping on a move/jump button
   -- (mothballed)
   --if lbutton:hitTestPoint(event.x,event.y) or 
   --   rbutton:hitTestPoint(event.x,event.y) or
   --   ljbutton:hitTestPoint(event.x,event.y) or 
   --   rjbutton:hitTestPoint(event.x,event.y) then
      
   --   return
   --end

   if self:hitTestPoint(event.x, event.y) then

      if (self.isCrate or self.isEgo) then   -- deactivate dynamic bodies during drag
	 self.body:setActive(false)
      end
      
      if (modestate=="S") then
	 self.isFocus = true
	 
	 self.x0 = event.x
	 self.y0 = event.y
	 
	 event:stopPropagation()

      elseif (modestate=="R" and (self.isPlatform or self.isCrate)) then
	 self.isFocus = true
	 
	 self.x0 = event.x
	 self.y0 = event.y
	 
	 event:stopPropagation()

      elseif (modestate=="C" and self.isPlatform and (not self.ismoving) and (not self.isice)) then
	 self.isFocus = true

	 self.x0=event.x
	 self.y0=event.y

	 event:stopPropagation()

      elseif (modestate=="G" and (self.isPlatform or self.isCrate)) then
	 self.isFocus = true
	 
	 self.x0 = event.x
	 self.y0 = event.y
	 
	 self.w0 = self.width
	 self.h0 = self.height
	 
	 event:stopPropagation()
	 
      elseif (modestate=="D") then

	 if (self.isPlanet) then
	    return
	 end

	 if (self.isPlatform and nplatform==1) then
	    popup({"You must have","at least one","platform."},{"OK"},{nil})
	    return
	 end

	 if (self.iscoin and ncoins==1) then
	    popup({"You must have","at least one","coin."},{"OK"},{nil})
	    return
	 end
	 
	 self.deleted=true
	 event:stopPropagation()

	 onsave()
	 trans=0
--	 ncoll=0
	 killlevel()
      elseif (modestate=="x2" and self.isPlatform and (not self.ismoving)) then
	 addplatform(100,100,self:getRotation(),self.width,self.height,
		     self.red,self.green,self.blue)
	 modestate="S"
	 mode:getChildAt(5):setVisible(false)
	 mode:getChildAt(1):setVisible(true)
      end

   end
end

function dragMove(self, event)
   if self.isFocus then
      local dx = event.x - self.x0
      local dy = event.y - self.y0
      
      if (modestate=="S") then
	 
	 self:setX(self:getX() + dx)
	 self:setY(self:getY() + dy)
	 
	 if self.isPlatform then
	    self.core:setPosition(self:getPosition())
	    if self.link<=nplatform then
	       self.linkline:setAlpha(0)
	    end
	 end
	 
	 if self.body then
	    self.body:setPosition(self:getPosition())
	 end
	 
      elseif (modestate=="R") then        -- only allowed for platforms and crates
	 self:setRotation(self:getRotation()+dy)
	 if (self.isPlatform) then self.core:setRotation(self:getRotation()) end
	 self.body:setAngle(self:getRotation()*math.pi/180)

      elseif (modestate=="C") then        -- only for platforms (not ice or moving)
	 self.hue=self.hue+dy
	 self.hue=self.hue % 180
	 local r,g,b=hsv2rgb(self.hue,self.sat,self.val)
	 self.core:setColorTransform(r,g,b)
	 self:setColorTransform(255-r,255-g,255-b)

	 self.red=r
	 self.green=g
	 self.blue=b
	 
      elseif (modestate=="G") then -- only platforms and crates

	 if (self.width>10 or dx>0) then self.width=self.width+dx end
	 if (self.height>10 or dy>0) then self.height=self.height+dy end
	 
	 if self.isCrate then
	    self:setScale(self.width/self.w0,self.height/self.h0)
	 else
	    self:setScale((self.width+20)/(self.w0+20),(self.height+20)/(self.h0+20))
	 end

	 if (self.isPlatform) then
	    self.core:setScale(self.width/self.w0,self.height/self.h0)
	 end

      end
		
      self.x0 = event.x
      self.y0 = event.y
      
      event:stopPropagation()
   end
end

function dragUp(self, event)
   if self.isFocus then
      self.isFocus = false
      
      if self.body then
	 self.body:setActive(true)
      end

      event:stopPropagation()
      
      onsave()
      trans=0
--      ncoll=0
      killlevel()
   end
end

--######################################################################

function modechange(self,event)

  if self:hitTestPoint(event.x,event.y) then
  
      for i=1,6 do
    	 mode:getChildAt(i):setVisible(false)
      end

      if (modestate=="S") then      -- shift
    	 modestate="R"
	 mode:getChildAt(2):setVisible(true)
      elseif (modestate=="R") then  -- rotate
    	 modestate="G"
	 mode:getChildAt(3):setVisible(true)
      elseif (modestate=="G") then  -- grow
    	 modestate="C"
	 mode:getChildAt(4):setVisible(true)
      elseif (modestate=="C") then  -- colour
    	 modestate="x2"
	 mode:getChildAt(5):setVisible(true)
      elseif (modestate=="x2") then  -- x2
    	 modestate="D"
	 mode:getChildAt(6):setVisible(true)
      elseif (modestate=="D") then  -- delete
    	 modestate="S"
	 mode:getChildAt(1):setVisible(true)
      end

      event:stopPropagation()
   end
end

--########################################################################

----------------------------------------------------------------------
-- prev and next level
----------------------------------------------------------------------

function nextlevel(self,event)

   if (self:hitTestPoint(event.x,event.y)) then
      if (level<upto) then
	 if not edit then showbuttons(true) end
	 level=level+1
	 trans=0; killlevel()
      elseif (level==totlevels) then
	 if demo then
	    popup({"Please buy","the full game","to create","new levels.",
		   "Search:","NEBULA RETRO"},{"OK"},{nil})
	 elseif (landscape) then
	    popup({"You must be","in portrait","mode to edit","or create","levels."},{"OK"},{nil})

	 else
	    popup({"Really create"," new level?"},{"Yes","No"},{newlevel,nil})
	 end
      else
	 popup({"You can't go to","the next level","until you've","completed","this one."},
	       {"OK"},{nil})
      end
   end

end

function prevlevel(self,event)

   if (self:hitTestPoint(event.x,event.y)) then
     if (level>-4) then
	if not edit then showbuttons(true) end
        level=level-1
--        ncoll=0
        trans=0; killlevel()
     end
   end
end

--########################################################################

function onEdit(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      print ("editbuttontext=",editbuttontext)

      if (editbuttontext=="edit") then
    	 if (upto>level or level==totlevels) then
	    editbuttontext="play"
	    editbutton:getChildAt(1):setVisible(false)
	    editbutton:getChildAt(2):setVisible(false)
	    editbutton:getChildAt(3):setVisible(true)
	    edit=true
	    hidebuttons()
	    trans=0; killlevel()
	 else
	    popup({"You can't edit","this level","until you","complete it."},
		  {"OK"},{nil})
     	 end

      else
    	 editbuttontext="edit"
	 edit=false
	 showbuttons(true)
         editbutton:getChildAt(1):setVisible(false)
         editbutton:getChildAt(2):setVisible(true)
	 editbutton:getChildAt(3):setVisible(false)
	 --	     ncoll=0
	 trans=0; killlevel()
      end
   end
end

--######################################################################

local demohue=0

function update(event)

   if demotext then
      demohue=demohue+0.1
      local r,g,b=hsv2rgb(demohue,1,100)
      demotext:getChildAt(2):setTextColor(rgb(r,g,b))
   end

----------------------------------------------------------------------
-- enterFrame update event
----------------------------------------------------------------------

   local xc,yc,theta,h,w,pos,xbody,ybody,angle
   local egox,egoy,sx,sy,bx,by,cx,cy
   local xmargin,ymargin
   
----------------------------------------------------------------------
-- operate physics. Update ego and crate sprites
----------------------------------------------------------------------

   world:step(1/60,8,3)

   xbody,ybody=ego.body:getPosition()    -- position for box2d
   angle=ego.body:getAngle()*180/math.pi

   if (scrolling) then
      if (landscape) then
	 scene:setPosition(-xbody*sscale+screenh/2,-ybody*sscale+screenw/2)
      else
	 scene:setPosition(-(xbody*sscale-screenw/2),-(ybody*sscale-screenh/2))   -- xscene=screenw/2-sscale*x
      end
   else
      ego:setPosition(xbody,ybody)
   end

   ego:setRotation(angle)

   for i=1,ncrate do
      if (crate[i]) then
	 crate[i]:setPosition(crate[i].body:getPosition())
	 crate[i]:setRotation(crate[i].body:getAngle()*180/math.pi)
      end
   end
   
   egox=ego:getX()   -- actual on screen coords
   egoy=ego:getY()

----------------------------------------------------------------------
-- shield
----------------------------------------------------------------------

   if shield then
      shield:setPosition(egox,egoy)

      local alpha=shield:getAlpha()

      if alpha<0.9 then
	 alpha=alpha-0.01
      else
	 alpha=alpha-0.002
      end

      if alpha<0 then
	 shield:removeFromParent()
	 shield=nil
      else
	 shield:setAlpha(alpha)
      end
   end

----------------------------------------------------------------------
-- hat
----------------------------------------------------------------------

   if hat then
      hat:setPosition(egox+8,egoy-15)
   end

----------------------------------------------------------------------
-- sparkle
----------------------------------------------------------------------

--   if (not edit) then
--      if (sparkle:getWidth()>10) then
--	 sparkle.dir=-1
--      elseif (sparkle.getWidth()<2) then
--	 sparkle.dir=1
--	 local i=math.random(nplatform)
--	 local px,py=platform[i]:getPosition()

--	 sparkle:setX(px+platform[i].width*0.5-10)
--	 sparkle:setY(py-platform[i].height*0.5+10)
--      end
--
--      sparkle: setWidth( sparkle:getWidth()+sparkle.dir*0.5)
 --     sparkle:setHeight(sparkle:getHeight()+sparkle.dir*0.5)
--   end

----------------------------------------------------------------------
-- ice sparkles
----------------------------------------------------------------------

   for i=1,nplatform do
      if (platform[i] and platform[i].sparkle) then
	 
	 xc=platform[i]:getX()
	 yc=platform[i]:getY()
	 theta=-platform[i]:getRotation()*math.pi/180

	 w=platform[i].width
	 h=platform[i].height

	 pos=platform[i].sparkle.pos
	 platform[i].sparkle.pos=pos+0.025

	 if (pos >= 0.975) then
	    platform[i].sparkle.pos=-1
	 end

	 if (w > h) then
	    platform[i].sparkle:setX(xc+pos*w/2*math.cos(theta))
	    platform[i].sparkle:setY(yc-pos*w/2*math.sin(theta))
	 else
	    platform[i].sparkle:setX(xc-pos*h/2*math.sin(theta))
	    platform[i].sparkle:setY(yc-pos*h/2*math.cos(theta))
	 end
      end
   end

   if (ring) then
      ring:setX(ego:getX())
      ring:setY(ego:getY())
      ring:setRotation(ring:getRotation()+5)
   end

----------------------------------------------------------------------
-- Sign: show text
----------------------------------------------------------------------

   if (sign) then

      sx=sign:getX()
      sy=sign:getY()

      if (xbody>sx-radius-10 and xbody<sx+radius+10 and
	  ybody>sy-radius-10 and ybody<sy+radius+10) then
	 if (not signtext) then
	    signtext=Sprite.new()
	    stage:addChild(signtext)

	    signtext:addChild(Bitmap.new(signunderlay_tex))
	    signtext:getChildAt(1):setAnchorPoint(0.5,0.5)

	    signtext:addChild(Bitmap.new(signtext_tex))
	    signtext:getChildAt(2):setAnchorPoint(0.5,0.5)

	    signtext:addChild(Bitmap.new(gotit_tex))
	    signtext:getChildAt(3):setAnchorPoint(0.5,0.5)
	    signtext:getChildAt(3):setY(200)

	    if (landscape) then
	       signtext:setPosition(250,70)
	    else
	       signtext:setPosition(160,100)
	    end

	    signtext:getChildAt(1):setAlpha(0.9)
	    signtext:addEventListener(Event.MOUSE_DOWN,touchsign,signtext)
	 end
      else
	 if (signtext) then
	    signtext:removeFromParent()
	    signtext=nil
	 end
      end
   end

----------------------------------------------------------------------
-- left and right buttons pressed. 1.4*100/40 = 3.5
----------------------------------------------------------------------

   if (leftpressed) then
      local vx,vy=ego.body:getLinearVelocity()
      ego.body:setLinearVelocity(-3.5,vy)
   elseif (rightpressed) then
      local vx,vy=ego.body:getLinearVelocity()
      ego.body:setLinearVelocity(3.5,vy)
   end

----------------------------------------------------------------------
-- Coins
----------------------------------------------------------------------
   
   for i=1,ncoins do
      
      if (coin[i] and (not coin[i].falling) and 
	  xbody>coin[i]:getX()-egocoin and xbody<coin[i]:getX()+egocoin and 
	  ybody>coin[i]:getY()-egocoin and ybody<coin[i]:getY()+egocoin) then

         if (fxstat=="ON" and not edit) then
	    if (math.random()<0.5) then
	       beepsound:play()
	    else
	       beepsound2:play()
	    end
	 end

	 if (collected==ncoins-1 and fxstat=="ON") then
	    victory:play()
         end
	 
	 if (edit) then
--	    coin[i].strokeWidth=4
--	    coin[i]:setStrokeColor(255,0,0)
         else
	    coin[i].falling=true
	    
	    coin[i].vx=2
	    coin[i].vy=-15
	    
	    collected=collected+1
	    if (collected==ncoins) then
	       readsign=false
	       level=level+1
	       if (level>totlevels) then level=1 end

	       if (level>upto) then
		  upto=level

		  local path="|D|config.txt"
		  fh=io.open(path,"w")
		  writeconfig(fh)
		  fh:close()
	       end

	       trans=2; killlevel()
	       return
	    end
	    
         end
      end
      
      if (coin[i] and coin[i].falling) then
	 coin[i].vy=coin[i].vy+2
	 coin[i]:setX(coin[i]:getX()+coin[i].vx)
	 coin[i]:setY(coin[i]:getY()+coin[i].vy)
	 
	 if (coin[i]:getY()>screenh) then
	    coin[i]:removeFromParent()
	    coin[i]=nil
	 end
      end
   end  -- coin loop

----------------------------------------------------------------------
-- baddies
----------------------------------------------------------------------

   for i=1,nbaddy do
      if (baddy[i] and (not baddy[i].falling)) then

	 bx=baddy[i]:getX()
	 by=baddy[i]:getY()

	 if (baddy[i].dir==1) then
	    if (bx>baddy[i].ends or bx<baddy[i].start) then
	       baddy[i].speed=-baddy[i].speed
	    end

	    baddy[i]:setX(bx+baddy[i].speed)

	 elseif (baddy[i].dir==2) then
	    if (by>baddy[i].ends or by<baddy[i].start) then
	       baddy[i].speed=-baddy[i].speed
	    end

	    baddy[i]:setY(by+baddy[i].speed)

	 else
	    baddy[i]:setRotation(baddy[i]:getRotation()+1.7)
	 end

	 if (xbody>bx-egobaddy and xbody<bx+egobaddy and 
	     ybody>by-egobaddy and ybody<by+egobaddy) then

	    if (edit) then
--	       ego.strokeWidth=4
--	       ego:setStrokeColor(255,0,0)
	    else
	       if (not shield) then
		  if (fxstat=="ON") then
		     diesound:play()
		  end
		  --	       ncoll=0
		  trans=1; killlevel()
		  return
	       end
	    end

	 end -- touched baddy
      end   -- baddy exists
   end

----------------------------------------------------------------------
-- kill ego if he falls off screen
-- edit: wrap ego top and bottom
----------------------------------------------------------------------

   if (edit) then
      local x,y=ego:getPosition()
      local shifted=false

      if (x>screenw) then
	 x=x-screenw
	 shifted=true
      elseif (x<0) then
	 x=x+screenw
	 shifted=true
      end

      if (y>screenh) then
	 y=y-screenh
	 shifted=true
      elseif (y<0) then
	 y=y+screenh
	 shifted=true
      end
	 
      if (shifted) then
	 ego:setPosition(x,y)
	 ego.body:setPosition(x,y)
	 ego.body:setLinearVelocity(0,0)
      end
      
   else
      if (ybody > screenh*1.2 or ybody < -screenh*0.2) then

	 if (fxstat=="ON") then
	    scream:play()
	 end

	 --         ncoll=0
         trans=1; killlevel()
	 return
      end
   end

----------------------------------------------------------------------
-- Crates: remove if falls off screen
-- kill baddies
----------------------------------------------------------------------

   for i=1,ncrate do
      if (crate[i]) then

	 cx=crate[i]:getX()
	 cy=crate[i]:getY()

	 if (edit) then
	    local x,y=cx,cy
	    local shifted=false

	    if (x>screenw) then
	       x=x-screenw
	       shifted=true
	    elseif (x<0) then
	       x=x+screenw
	       shifted=true
	    end

	    if (y>screenh) then
	       y=y-screenh
	       shifted=true
	    elseif (y<0) then
	       y=y+screenh
	       shifted=true
	    end
	 
	    if (shifted) then
	       crate[i]:setPosition(x,y)
	       crate[i].body:setPosition(x,y)
--	       crate[i].body:setLinearVelocity(0,0)
	    end
      
	 else
	    if (cy > screenh*1.2 or cy < -screenh*0.2) then

	       world:destroyBody(crate[i].body)                 -- forgot this = memory leak!
	       crate[i]:removeFromParent()
	       crate[i]=nil
	       return
	    end
	 end

--	 xmargin=baddyrad+crate[i].width/2
--	 ymargin=baddyrad+crate[i].height/2

	 local vx,vy=crate[i].body:getLinearVelocity()

	 if (math.abs(vy)>1) then

	    for j=1,nbaddy do
	       if (baddy[j]) then

		  bx,by=baddy[j]:getPosition()
		  bx,by=scene:localToGlobal(bx,by)

		  local baddyhit

		  if (scrolling) then
		     baddyhit=
			crate[i]:hitTestPoint(bx+sscale*baddyrad,by+sscale*baddyrad) or
			crate[i]:hitTestPoint(bx+sscale*baddyrad,by-sscale*baddyrad) or
			crate[i]:hitTestPoint(bx-sscale*baddyrad,by+sscale*baddyrad) or
			crate[i]:hitTestPoint(bx-sscale*baddyrad,by-sscale*baddyrad)
		  else
		     baddyhit=
			crate[i]:hitTestPoint(bx+baddyrad,by+baddyrad) or
			crate[i]:hitTestPoint(bx+baddyrad,by-baddyrad) or
			crate[i]:hitTestPoint(bx-baddyrad,by+baddyrad) or
			crate[i]:hitTestPoint(bx-baddyrad,by-baddyrad)
		  end

		  if (baddyhit) then

		     if (fxstat=="ON" and not baddy[j].falling) then
			bdiesound:play()
		     end

		     if (edit) then
--			baddy[j].strokeWidth=4
		     else
			baddy[j].falling=true
			baddy[j].vx=7
			baddy[j].vy=-10
		     end
		  end

	       end
	    end

	 end  -- crate going down
	 
      end  -- crate exists
   end     -- crate loop

----------------------------------------------------------------------
-- falling baddies
----------------------------------------------------------------------

   for i=1,nbaddy do
      if (baddy[i] and baddy[i].falling) then

	 bx,by=baddy[i]:getPosition()

	 baddy[i].vy=baddy[i].vy+1

	 baddy[i]:setX(bx+baddy[i].vx)
	 baddy[i]:setY(by+baddy[i].vy)

	 local sx,sy=baddy[i]:getScale()
	 baddy[i]:setScale(sx*1.05,sy*1.05)
	 baddy[i]:setAlpha(math.max(baddy[i]:getAlpha()-0.01,0))
	 
	 if (by>screenh) then
	    baddy[i]:removeFromParent()
	    baddy[i]=nil
	 end
      end
   end

----------------------------------------------------------------------
-- Rotate nebula
----------------------------------------------------------------------

   if graphics=="space" or graphics=="xmas" then
      nebula:setRotation(nebula:getRotation()+0.05)
   else
      updateStars()
   end

----------------------------------------------------------------------
-- Moving platforms
----------------------------------------------------------------------

   for i=1,nplatform do
      if (platform[i].ismoving) then
	 
	 px,py=platform[i]:getPosition()

	 if (py>platform[i].ends or py<platform[i].start) then
	    platform[i].speed=-platform[i].speed
	 end

	 py=py+platform[i].speed

	 platform[i]:setY(py)
	 platform[i].body:setPosition(px,py)
      end
   end

----------------------------------------------------------------------
-- touch platform targets
----------------------------------------------------------------------

   for i=1,nplatform do

      if platform[i].waning then
	 local alpha

	 if edit then
	    alpha=platform[i].core:getAlpha()
	 else
	    alpha=platform[i]:getAlpha()
	 end

	 alpha=alpha-0.04

	 if alpha<=0 then
	    touchsound:play()
	    platform[i].fadecnt=platform[i].fadecnt+1

	    if platform[i].fadecnt==3 then
	       alpha=0
	       platform[i].body:setActive(false)
	       platform[i].waxing=false
	       platform[i].waning=false
	    else
	       alpha=1
	    end
	 end

	 if (edit) then
	    platform[i].core:setAlpha(alpha)
	 else
	    platform[i]:setAlpha(alpha)
	 end
      end
   end

   for i=1,nplatform do

      if platform[i].waxing then
	 local alpha

	 if (edit) then
	    alpha=platform[i].core:getAlpha()
	 else
	    alpha=platform[i]:getAlpha()
	 end

	 alpha=alpha+0.02

	 if alpha>=1 then
	    alpha=1
	    platform[i].body:setActive(true)
	    platform[i].waxing=false
	    platform[i].waning=false
	 end

	 if (edit) then
	    platform[i].core:setAlpha(alpha)
	 else
	    platform[i]:setAlpha(alpha)
	 end
      end
   end

end

function touchsign(self,event)
   if self:getChildAt(3):hitTestPoint(event.x,event.y) then
      readsign=true
      signtext:removeEventListener(Event.MOUSE_DOWN,touchsign,signtext)

      local fh=io.open("|D|config.txt","w")
      writeconfig(fh)
      fh:close()

      GTween.new(self,0.2,{alpha=0},{onComplete=killsigntext})
   end
end

function killsigntext()
   if sign then
      sign:removeFromParent()
      sign=nil
   end

   if signtext then
      signtext:removeFromParent()
      signtext=nil
   end
end

--######################################################################

function loadlevel()

----------------------------------------------------------------------
-- Load from data file
-- trans=2: set up outside of screen and transition on
-- trans=1: set up in place but fade in (alpha transition)
-- trans=0: also fade up but zero time
----------------------------------------------------------------------

   zoomedOut=false
   if landscape then sscale=2 end

   if (level==upto and upto<nlevels) then
      print ("HERE",level,upto,nlevels)
      if edit then
	 showbuttons()
	 edit=false
	 editbuttontext="edit"
      end
   end

   scene=Sprite.new()
   stage:addChild(scene)
   
   local x,y,dir,start,ends,speed,width,height,rotation,rect,fadetime
   local imusic,musicname,levelx,ind
   local egoscale,egox,egoy

   if (trans==2) then
      fadetime=3
   elseif (trans==1) then
      fadetime=1
   else
      fadetime=1/30
   end

----------------------------------------------------------------------
-- open files
----------------------------------------------------------------------

   local path="|D|level"..level..".txt"
   local fh=io.open(path,"r")

   local path="|D|colours"..level..".txt"
   local ch=io.open(path,"r")

   x,y=fh:read("*number","*number")
   fh:read("*line")

----------------------------------------------------------------------
-- swap planets
----------------------------------------------------------------------

   if (level==nlevels and (not demo)) then
      levelx="end"
   else
      levelx=(level-1)%12+1
   end

   if (trans==2) then
      GTween.new(planet,fadetime,{x=-2*screenw,y=planet:getY()},
		 {ease=easing.inOutExponential})
      
      if graphics=="space" or levelx=="end" then
	 newplanet=display.newImage("p"..levelx..".png")
      elseif graphics=="xmas" then
	 newplanet=display.newImage("bauble.png")
	 local r,g,b=hsv2rgb(levelx/12*180,1,100)
	 newplanet:setColorTransform(r/255,g/255,b/255)
      else
	 newplanet=display.newImage("p8bit.png")
	 newplanet:setRotation(levelx*40-40)
	 local r,g,b=hsv2rgb(levelx/12*180,1,100)
	 newplanet:setColorTransform(r/255,g/255,b/255)
      end

      newplanet:setX(screenw*2)
      newplanet:setY(y)

      stage:addChildAt(newplanet,2)
      
      GTween.new(newplanet,fadetime,{x=x,y=newplanet:getY()},
		 {ease=easing.inOutExponential,onComplete=swapplanet})

   else

      if (planet) then
	 planet:removeFromParent()
      end

      if graphics=="space" or levelx=="end" then
	 planet=display.newImage("p"..levelx..".png")
      elseif graphics=="xmas" then
	 planet=display.newImage("bauble.png")
	 local r,g,b=hsv2rgb(levelx/12*180,1,100)
	 planet:setColorTransform(r/255,g/255,b/255)
      else
	 planet=display.newImage("p8bit.png")
	 planet:setRotation(levelx*40-40)

	 local r,g,b=hsv2rgb(levelx/12*180,1,100)
	 planet:setColorTransform(r/255,g/255,b/255)
      end

      if (edit) then
	 planet.isPlanet=true

	 planet:addEventListener(Event.MOUSE_DOWN,dragDown,planet)
	 planet:addEventListener(Event.MOUSE_MOVE,dragMove,planet)
	 planet:addEventListener(Event.MOUSE_UP,dragUp,planet)
      end

      planet:setX(x)
      planet:setY(y)

      stage:addChildAt(planet,2)
   end

----------------------------------------------------------------------
-- coins
----------------------------------------------------------------------

   fh:read("*line")
   ncoins=fh:read("*number")
   print ("ncoins=",ncoins)

   coin={}
   for i=1,ncoins do
      x,y=fh:read("*number","*number")

      if (edit) then
	 if graphics=="xmas" then
	    coin[i]=display.newImage("bigcoin_xmas.png")
	 else
	    coin[i]=display.newImage("bigcoin.png")
	 end
	 
	 coin[i]:setX(x)
	 coin[i]:setY(y)
	 coin[i].iscoin=true

      else
	 if graphics=="space" then
	    coin[i]=display.newImage("coin.png")
	    coin[i]:setScale(0.5)
	 elseif graphics=="xmas" then
	    coin[i]=display.newImage("coin_xmas.png")
	 else
	    coin[i]=display.newImage("coin8bit.png")
	 end
	 
	 coin[i]:setX(x)
	 coin[i]:setY(y)
	 coin[i].iscoin=true
      end
	 
      coin[i].vx=0
      coin[i].vy=0
      coin[i].falling=false

      if (edit) then 
	 coin[i]:addEventListener(Event.MOUSE_DOWN,dragDown,coin[i]) 
	 coin[i]:addEventListener(Event.MOUSE_MOVE,dragMove,coin[i]) 
	 coin[i]:addEventListener(Event.MOUSE_UP,dragUp,coin[i]) 
      end

      scene:addChild(coin[i])
      
   end

----------------------------------------------------------------------
-- baddy
----------------------------------------------------------------------

   print(fh:read("*line"))
   print(fh:read("*line"))

   nbaddy=fh:read("*number")
   print ("nbaddy=",nbaddy)

   baddy={}

   for i=1,nbaddy do
      x,y,dir,start,ends,speed=fh:read("*number","*number","*number","*number","*number","*number")
      print (i,x,y,dir,start,ends,speed)

      if (edit and dir==0) then
	 if graphics=="space" then
	    baddy[i]=display.newImage("baddy3.png")
	 elseif graphics=="xmas" then
	    baddy[i]=display.newImage("baddy3_xmas.png")
	    baddy[i]:setScale(2,2)
	 else
	    baddy[i]=display.newImage("baddy38bit.png")
	    baddy[i]:setScale(2,2)
	 end
      else
	 if (dir==0) then
	    if graphics=="space" then
	       baddy[i]=display.newImage("baddy3.png")
	       baddy[i]:setScale(0.5)
	    elseif graphics=="xmas" then
	       baddy[i]=display.newImage("baddy3_xmas.png")
	    else
	       baddy[i]=display.newImage("baddy38bit.png")
	    end
	 elseif (dir==1) then
	    if graphics=="space" then
	       baddy[i]=display.newImage("baddy.png")
	       baddy[i]:setScale(0.5)
	    elseif graphics=="xmas" then
	       baddy[i]=display.newImage("baddy_xmas.png")
	    else
	       baddy[i]=display.newImage("baddy8bit.png")
	    end
	 else
	    if graphics=="space" then
	       baddy[i]=display.newImage("baddy2.png")
	       baddy[i]:setScale(0.5)
	    elseif graphics=="xmas" then
	       baddy[i]=display.newImage("baddy2_xmas.png")
	    else
	       baddy[i]=display.newImage("baddy28bit.png")
	    end
	 end
      end

      baddy[i]:setPosition(x,y)

      baddy[i].dir=dir
      baddy[i].start=start
      baddy[i].ends=ends
      baddy[i].speed=speed
      baddy[i].isbaddy=true
      baddy[i].falling=false

      if (edit) then 
	 if (dir==1) then
	    baddy[i].core=display.newRect(ends-start,20, 255,0,0, 70/255, 255,255,255, 2)
	    baddy[i].core:setX((start+ends)/2)
	    baddy[i].core:setY(y)

	    baddy[i].core.width=ends-start
	    baddy[i].core.height=20

	    baddy[i].core:addEventListener(Event.MOUSE_DOWN,movingDOWN,baddy[i].core)
	    baddy[i].core:addEventListener(Event.MOUSE_MOVE,movingMOVE,baddy[i].core)
	    baddy[i].core:addEventListener(Event.MOUSE_UP,  movingUP  ,baddy[i].core)

	    baddy[i].core.parent=baddy[i]
	    
	 elseif (dir==2) then
	    baddy[i].core=display.newRect(20,ends-start, 0,255,0, 70/255, 255,255,255, 2)
	    baddy[i].core:setX(x)
	    baddy[i].core:setY((start+ends)/2)

	    baddy[i].core.width=20
	    baddy[i].core.height=ends-start

	    baddy[i].core:addEventListener(Event.MOUSE_DOWN,movingDOWN,baddy[i].core)
	    baddy[i].core:addEventListener(Event.MOUSE_MOVE,movingMOVE,baddy[i].core)
	    baddy[i].core:addEventListener(Event.MOUSE_UP,  movingUP  ,baddy[i].core)

	    baddy[i].core.parent=baddy[i]
	 else
	    baddy[i]:addEventListener(Event.MOUSE_DOWN,dragDown,baddy[i])
	    baddy[i]:addEventListener(Event.MOUSE_MOVE,dragMove,baddy[i])
	    baddy[i]:addEventListener(Event.MOUSE_UP  ,dragUp  ,baddy[i])
	 end
      end

      scene:addChild(baddy[i])
   end           -- baddy loop
   
----------------------------------------------------------------------
-- platforms
-- If edit, then platform is bigger and inverse video. Physical size
-- is same. Core is also added which is normal size, actual colour
-- and non-physical. In case of moving, platform is blue and yellow
-- and "core" is actually a large, green rectangle (edit mode).
-- in case of ice, platform is transparent with white outline.
-- In edit mode it is white with black core
-- Introduced width and height fields. These are used by ego lives
-- and also by onsave. (Gideros getWidth does not return actual width
-- if rotated
-- Also sets up hue, sat, val for ordinary platforms. Used by onDrag
-- trans is connected to linked platform.
----------------------------------------------------------------------

   fh:read("*line")
   fh:read("*line")
   nplatform=fh:read("*number")
   print ("nplatform=",nplatform)

   local r,g,b,link -- read from colour.txt
   local rp,gp,bp,alp,rps,gps,bps,pw  -- (r,g,b) platform, tranparency, (r,g,b) stroke, its width
   local wp,hp                        -- display width and height of platform
   local rc,gc,bc,alc,rcs,gcs,bcs,cw  -- (r,g,b) core, tranparency, (r,g,b) stroke, its width
   local wp,hp                        -- display width and height of core

   platform={}
   for i=1,nplatform do
      x,y,width,height,rotation=fh:read("*number","*number","*number","*number","*number")
      r,g,b,link=ch:read("*number","*number","*number","*number")

      print (i,x,y,width,height,rotation,link)

----------------------------------------------------------------------
-- decide on platform sizes, colours, tranparency, stroke width and colour
----------------------------------------------------------------------

      if (edit) then
	 if (r==-1) then
	    rp,  gp,  bp, alp = 0,0,255,1    -- blue platform
	    rps, gps, bps, pw= 255,255,0,2    -- yellow outline, 2 pixels wide
	    wp=width
	    hp=height

	    rc, gc, bc, alc = 0,0,255,0.4              -- blue "core", semi-trans
	    rcs, gcs, bcs, cw=255,255,255,2      -- white stroke, 2 pixels wide
	    wc=width
	    hc=b-g
	 elseif (r==-2) then       -- ice
	    rp,gp,bp,alp = 255,255,255,1          -- white
	    rps,gps,bps,pw=nil,nil,nil,nil
	    wp=width+20                       -- bigger
	    hp=height+20

	    rc,gc,bc,alc= 0,0,0,1                   -- black core
	    rps,gps,bps,pw=nil,nil,nil,nil    
	    wc=width
	    hc=height
	 else
	    rp,gp,bp,alp=255-r,255-g,255-b,1        -- inv. video
	    rps,gps,bps,pw=nil,nil,nil,nil
	    wp=width+20                       -- bigger
	    hp=height+20

	    rc,gc,bc,alc=r,g,b,1
	    rcs,gcs,bcs,cw=nil,nil,nil,nil    
	    wc=width
	    hc=height
	 end
      else
	 if (r==-1) then
	    rp, gp, bp, alp = 0,0,255,1   -- blue platform
	    rps, gps, bps, pw= 255,255,0,2 -- yellow outline, 2 pixels wide
	 elseif (r==-2) then
	    rp,gp,bp,alp=0,0,0,0        -- transparent ice
	    rps, gps, bps, pw= 255,255,255,2 -- white outline, 2 pixels wide
	 else
	    rp,gp,bp,alp=r,g,b,1
	    rps,gps,bps,pw=nil,nil,nil,nil    
	 end

	 wp=width
	 hp=height
      end

----------------------------------------------------------------------
-- Set up platforms and cores
----------------------------------------------------------------------

      if (edit) then
--    	 platform[i]=     display.newRect(wp,hp, rp,gp,bp, alp, rps,gps,bps, pw)
--	 platform[i].core=display.newRect(wc,hc, rc,gc,bc, alc, rcs,gcs,bcs, cw)

    	 platform[i]=     display.newRect(wp,hp, 1,1,1, alp, rps,gps,bps, pw)
	 platform[i].core=display.newRect(wc,hc, 1,1,1, alc, rcs,gcs,bcs, cw)

	 platform[i]     :setColorTransform(rp,gp,bp)
	 platform[i].core:setColorTransform(rc,gc,bc)

         if r==-1 then
	    platform[i].core:addEventListener(Event.MOUSE_DOWN,movingDOWN,platform[i].core)
	    platform[i].core:addEventListener(Event.MOUSE_MOVE,movingMOVE,platform[i].core)
	    platform[i].core:addEventListener(Event.MOUSE_UP,movingUP,platform[i].core)

	    platform[i].core.width=wc         -- set width/height for platform core (ie move range)
	    platform[i].core.height=hc
	    platform[i].core.parent=platform[i]  -- useful for moving platforms
         else
	    platform[i]:addEventListener(Event.MOUSE_DOWN,dragDown,platform[i])
	    platform[i]:addEventListener(Event.MOUSE_MOVE,dragMove,platform[i])
	    platform[i]:addEventListener(Event.MOUSE_UP,dragUp,platform[i])
         end
      else
	 if link<=nplatform then
	    platform[i]=display.newStripeRect(wp,hp,rp,gp,bp,255,255,255)     -- linked
	 elseif (r<0) then
	    platform[i]=display.newRect(wp,hp,rp,gp,bp,alp,rps,gps,bps,pw)    --  ice and moving
	 else
	    if graphics=="space" or graphics=="xmas" then
	       platform[i]=display.newGradRect(wp,hp,rp,gp,bp)                   -- shaded
	    else
	       platform[i]=display.newRect(wp,hp,rp,gp,bp)                   -- shaded
	    end
	 end
      end

----------------------------------------------------------------------
-- set up common properties
----------------------------------------------------------------------

      local h,s,v = rgb2hsv(r,g,b)

      platform[i].hue=h
      platform[i].sat=s
      platform[i].val=v

      platform[i].red=r
      platform[i].green=g
      platform[i].blue=b
      platform[i].link=link

      platform[i].width=width
      platform[i].height=height

      platform[i]:setRotation(rotation)
      platform[i].isPlatform=true
      platform[i].ncolp=0                -- for touch targets

      if (edit) then
	 platform[i].core:setRotation(rotation)
      end

----------------------------------------------------------------------
-- Set up platform position
-- in case of trans=2, set up outside of screen and GTween onto screen
-- Assume trans=0 in edit mode
----------------------------------------------------------------------

      platform[i]:setX(x)
      platform[i]:setY(y)

      if (edit) then
	 if (r==-1) then                        -- moving platform
	    platform[i].core:setX(x)
	    platform[i].core:setY((b+g)/2)
	 else
	    platform[i].core:setX(x)
	    platform[i].core:setY(y)
	 end
      end

----------------------------------------------------------------------
-- This platform is linked to another. Check for collision
----------------------------------------------------------------------

      if (link<=nplatform) then
--	 platform[i]:addEventListener("collision",platcoll)
      end

----------------------------------------------------------------------
-- Set stuff for moving platform. Set its colours
-- For ice, set colours and sparkle
-- others: set colours including core colour
----------------------------------------------------------------------

      if (r==-1) then
	 platform[i].start=g
	 platform[i].ends=b
	 platform[i].ismoving=true
	 platform[i].speed=1
      elseif (r==-2) then
	 platform[i].isice=true
	 
	 if (not edit) then
	    x=platform[i]:getX()
	    y=platform[i]:getY()

	    width=platform[i].width
	    height=platform[i].height

	    if (width>height) then
	       platform[i].sparkle=display.newRect(10,height,255,255,255)
	    else
	       platform[i].sparkle=display.newRect(width,10,255,255,255)
	    end

	    platform[i].sparkle:setX(x)
	    platform[i].sparkle:setY(y)
	    platform[i].sparkle:setRotation(platform[i]:getRotation())
	    platform[i].sparkle.pos=0

	    scene:addChild(platform[i].sparkle)
	 end
      end

      scene:addChild(platform[i])

   end   -- platform loop

----------------------------------------------------------------------
-- In edit mode, draw lines between platforms
-- link>nplatform means no link
----------------------------------------------------------------------

   if (edit) then
      for i=1,nplatform do

	 local n=platform[i].link
	 if (n <= nplatform) then

	    print ("adding link",i,n)

	    x=platform[i]:getX()
	    y=platform[i]:getY()

	    local x2=platform[n]:getX()
	    local y2=platform[n]:getY()

	    platform[i].linkline=Shape.new()
	    platform[i].linkline:setLineStyle(5,0xffffff,1)

	    local dist=math.sqrt((x-x2)^2+(y-y2)^2)
	    local ang=math.atan2(y2-y,x2-x)*180/math.pi

	    platform[i].linkline:beginPath()
	    platform[i].linkline:moveTo(0,0)
	    platform[i].linkline:lineTo(dist,0)
	    platform[i].linkline:lineTo(dist-10,-10)
	    platform[i].linkline:lineTo(dist-10, 10)
	    platform[i].linkline:lineTo(dist,0)
	    platform[i].linkline:endPath()
	    
	    platform[i].linkline:setPosition(x,y)
	    platform[i].linkline:setRotation(ang)

	    stage:addChild(platform[i].linkline)

--	    platform[i].link=display.newLine(x,y,x2,y2)
--	    platform[i].link.width=5

	    print (x,y,x2,y2)
	 end
      end

   end

----------------------------------------------------------------------
-- ensure platforms are behind other objects
----------------------------------------------------------------------

   for i=1,nplatform do
      if (platform[i].core) then
	 scene:addChildAt(platform[i].core,1)
      end
   end

   for i=1,nplatform do
      scene:addChildAt(platform[i],1)
   end

--   stage:addChildAt(editbutton,3)

----------------------------------------------------------------------
-- ego
----------------------------------------------------------------------

   fh:read("*line")
   fh:read("*line")

   egox,egoy=fh:read("*number","*number")

----------------------------------------------------------------------
-- crates
----------------------------------------------------------------------

   fh:read("*line")
   fh:read("*line")
   print ("found crate")

   ncrate=fh:read("*line")
   print ("ncrate=",ncrate)
   
   crate={}
   for i=1,ncrate do
      x,y,width,height,rotation,ind=fh:read("*number","*number","*number","*number","*number","*number")

      if (ind==1) then
     	 crate[i]=display.newBorderRect(width,height, 2,2,2, 1, 1,1,1, 4)
	 crate[i]:setColorTransform(0,0,120)
	 crate[i].isblue="yes"
      elseif (ind==2) then
	 crate[i]=display.newBorderRect(width,height, 2,2,2, 1, 1,1,1, 4)
	 crate[i]:setColorTransform(0,120,0)
	 crate[i].isgreen="yes"
      else
	 crate[i]=display.newBorderRect(width,height, 255,255,0, 1, 120,120,0, 4)
      end

      crate[i].isCrate=true

      crate[i]:setRotation(rotation)
      crate[i].width=width
      crate[i].height=height

      if (edit) then 
	 crate[i]:addEventListener(Event.MOUSE_DOWN,dragDown,crate[i])
	 crate[i]:addEventListener(Event.MOUSE_MOVE,dragMove,crate[i])
	 crate[i]:addEventListener(Event.MOUSE_UP,dragUp,crate[i])
      end

      crate[i]:setX(x)
      crate[i]:setY(y)        -- previously y-10

      scene:addChild(crate[i])
   end

   fh:close()
   ch:close()

----------------------------------------------------------------------
-- In edit mode, we need makebutton and mode
-- In play mode, we need pause button
----------------------------------------------------------------------

   if (edit) then

      makebutton=display.newImage("makebutton.png",screenw-100,20)
      makebutton:addEventListener(Event.MOUSE_DOWN,onmake,makebutton)
      
      mode=Sprite.new()
      mode:addChild(display.newImage("shift.png"))
      mode:addChild(display.newImage("rotate.png"))
      mode:addChild(display.newImage("grow.png"))
      mode:addChild(display.newImage("colour.png"))
      mode:addChild(display.newImage("x2.png"))
      mode:addChild(display.newImage("delete.png"))

      stage:addChild(mode)

      for i=1,6 do
    	 mode:getChildAt(i):setVisible(false)
		 mode:getChildAt(i):setPosition(screenw-60,20)
      end

      if (modestate=="S") then
         mode:getChildAt(1):setVisible(true)	
      elseif (modestate=="R") then
         mode:getChildAt(2):setVisible(true)	
      elseif (modestate=="G") then
         mode:getChildAt(3):setVisible(true)	
      elseif (modestate=="C") then
         mode:getChildAt(4):setVisible(true)	
      elseif (modestate=="x2") then
         mode:getChildAt(5):setVisible(true)	
      elseif (modestate=="D") then
         mode:getChildAt(6):setVisible(true)	
      end

      mode:addEventListener(Event.MOUSE_DOWN,modechange,mode)

      stage:addChildAt(mode,3)
      stage:addChildAt(makebutton,3)

   else
      if (landscape) then
	 pause=display.newImage("x.png",screenh-60,20,true)
      else
	 pause=display.newImage("x.png",screenw-60,20,true)
      end

      stage:addChildAt(pause,3)
   end

----------------------------------------------------------------------
-- Level inc dec and text.
----------------------------------------------------------------------

   if level<1 then
      leveltxt=TextField.new(myfont, "t"..(level+5))
   else
      leveltxt = TextField.new(myfont, level)
   end

   if (landscape) then
      leveltxt:setPosition(screenh-30,25)
   else
      leveltxt:setPosition(screenw-30,25)
   end

   stage:addChild(leveltxt)
   leveltxt:setTextColor(0xffffff)

   inclevel=display.newArrow(40,40,"right",255,255,255,1,100,100,100,2)
   declevel=display.newArrow(40,40,"left", 255,255,255,1,100,100,100,2)

   if (landscape) then
      inclevel:setPosition(100,25)
      declevel:setPosition( 40,25)
   else
      inclevel:setPosition(130,25)
      declevel:setPosition( 80,25)
   end

   local x,y=inclevel:getPosition()

   inctext=TextField.new(myfont,"0")
   dectext=TextField.new(myfont,"0")
   stage:addChild(inctext)   
   stage:addChild(dectext)

   if (landscape) then 
      inctext:setPosition(85,33)
      dectext:setPosition(30,33)
   else
      inctext:setPosition(115,33)
      dectext:setPosition( 70,33)
   end

   stage:addChildAt(inctext,3)
   stage:addChildAt(dectext,3)
   stage:addChildAt(inclevel,3)
   stage:addChildAt(declevel,3)

----------------------------------------------------------------------
-- The edit button
----------------------------------------------------------------------

   if (not landscape) then
      
      editbutton=Sprite.new()
      
      editbutton:addChild(display.newImage("noedit.png"))
      editbutton:addChild(display.newImage("edit.png"))
      editbutton:addChild(display.newImage("play.png"))
      
      editbutton:getChildAt(1):setPosition(30,25)
      editbutton:getChildAt(2):setPosition(30,25)
      editbutton:getChildAt(3):setPosition(30,25)
      
      editbutton:getChildAt(1):setVisible(true)
      editbutton:getChildAt(2):setVisible(false)
      editbutton:getChildAt(3):setVisible(false)

      stage:addChildAt(editbutton,3)

   end

----------------------------------------------------------------------
-- Zoom button in landscape
----------------------------------------------------------------------

   if (landscape) then
      zoom=Bitmap.new(Texture.new("zoom1-blackback.png"))
      zoom:setAnchorPoint(0.5,0.5)
      zoom:setPosition(365,20)

      stage:addChild(zoom)

      local zoom2=Bitmap.new(Texture.new("zoom2-fronticon.png",true))
      zoom2:setAnchorPoint(0.5,0.5)
      zoom2:setPosition(0,0)
      zoom2:setRotation(90)

      zoom:addChild(zoom2)
   end

----------------------------------------------------------------------
-- transition ego
----------------------------------------------------------------------

   if (edit or scrolling) then
      if graphics=="space" then
	 egoscale=1
      else
	 egoscale=2
      end
   else
      if graphics=="space" then
	 egoscale=0.5
      else
	 egoscale=1
      end
   end

   if (trans==0) then
      if (scrolling) then
	 ego:setPosition(screenh/2,screenw/2)   -- NB screenw=320, screenh=480
      else
	 ego:setPosition(egox,egoy-10)
      end

      ego:setScale(egoscale,egoscale)
   else
      if (scrolling) then
	 GTween.new(ego,fadetime,{x=screenh/2,y=screenw/2,scaleX=egoscale,scaleY=egoscale},{ease=easing.inOutExponential})
      else
	 GTween.new(ego,fadetime,{x=egox,y=egoy-10,scaleX=egoscale,scaleY=egoscale},{ease=easing.inOutExponential})
      end
   end

----------------------------------------------------------------------
-- add hat
----------------------------------------------------------------------

   if (graphics=="xmas" and not edit and not landscape) then
      hat=display.newImage("hat.png")
      hat:setPosition(egox+10,-screenh*0.5)
      if trans>0 then
	 GTween.new(hat,fadetime,{x=egox+8,y=egoy-15})
      end
   end

----------------------------------------------------------------------
-- level startup: collected, left/rightpressed, change music
----------------------------------------------------------------------

   collected=0
   leftpressed=false
   rightpressed=false

   ncoll=0
   onground=false

   if level<1 then
      leveltxt:setText("t"..(level+5))
   else
      leveltxt:setText(level)
   end

   imusic=(level-1)%8+1

   if (level==nlevels and (not demo)) then
      musicname="solution.mp3"
   else
      if (imusic==1 or imusic==2) then
	 musicname="spring_winds.mp3"
      elseif (imusic==3 or imusic==4) then
	 musicname="techno_dog.mp3"
      elseif (imusic==5 or imusic==6) then
	 musicname="diving_turtle.mp3"
      else
	 musicname="dance_zone.mp3"
      end
   end

   print ("currmusic, musicname",currmusic,musicname)

   if (musicstat=="ON" and musicname ~= currmusic) then
      if (music) then
	 print ("stopping music")
	 music:stop()
	 music=nil
      end

      local sound=Sound.new(musicname)
      music=sound:play(0,myhuge)
      music:setVolume(0.75)

      currmusic=musicname
   end
   
----------------------------------------------------------------------
-- sign
----------------------------------------------------------------------

   if (level==upto and not readsign) then
      if (level==-4) then
	 sign=display.newImage("sign.png",120,265)
      elseif (level==-3) then
	 sign=display.newImage("sign.png",130,220)
      elseif (level==-2) then
	 sign=display.newImage("sign.png",80,230)
      elseif (level==-1) then
	 sign=display.newImage("sign.png",80,265)
      elseif (level==0) then
	 sign=display.newImage("sign.png",210,270)
      elseif (level==1) then
	 sign=display.newImage("sign.png",190,320)
      elseif (level==2) then
	 sign=display.newImage("sign.png",220,280)
      elseif (level==3) then
	 sign=display.newImage("sign.png",40,210)
      elseif (level==4) then
	 sign=display.newImage("sign.png",210,270)
      elseif (level==5) then
	 sign=display.newImage("sign.png",280,260)
      elseif (level==6) then
	 sign=display.newImage("sign.png",140,80)
      elseif (level==7) then
	 sign=display.newImage("sign.png",260,230)
      elseif (level==8) then
	 sign=display.newImage("sign.png",160,240)
      elseif (level==9) then
	 sign=display.newImage("sign.png",60,150)
      elseif (level==12) then
	 sign=display.newImage("sign.png",260,90)
      elseif (level==14) then
	 sign=display.newImage("sign.png",100,170)
      elseif (level==16) then
	 sign=display.newImage("sign.png",100,410)
      elseif (level==17) then
	 sign=display.newImage("sign.png",230,340)
--      elseif (level==21) then
--	 sign=display.newImage("sign.png",20,85)
      end

      if (sign) then
	 scene:addChildAt(sign,1)
	 sign:setY(sign:getY()-5)
	 sign:setScale(0.5)
      end

      if (trans==2 and sign) then
	 sign:setAlpha(0)
	 GTween.new(sign,1,{alpha=1},{delay=fadetime,transition=easing.inOutExpo})
      end
   end

----------------------------------------------------------------------
-- make buttons
----------------------------------------------------------------------

   if (edit) then
      coinbutton=display.newImage("coinbutton.png",screenw*2,60)      
      coinbutton:addEventListener(Event.MOUSE_DOWN,newcoin,coinbutton)
      
      platbutton=display.newImage("platbutton.png",screenw*2,100)
      platbutton:addEventListener(Event.MOUSE_DOWN,newplatform,platbutton)

      platbuttonv=display.newImage("platbuttonv.png",screenw*2,100)
      platbuttonv:addEventListener(Event.MOUSE_DOWN,newplatformv,platbuttonv)
      
      vbadbutton=display.newImage("vbadbutton.png",screenw*2,140)
      vbadbutton:addEventListener(Event.MOUSE_DOWN,newVbaddy,vbadbutton)
      
      hbadbutton=display.newImage("hbadbutton.png",screenw*2,140)
      hbadbutton:addEventListener(Event.MOUSE_DOWN,newHbaddy,hbadbutton)
      
      Sbadbutton=display.newImage("sbadbutton.png",screenw*2,140)
      Sbadbutton:addEventListener(Event.MOUSE_DOWN,newSbaddy,Sbadbutton)
      
      cratebutton=display.newImage("cratebutton.png",screenw*2,180)
      cratebutton:addEventListener(Event.MOUSE_DOWN,newcrate,cratebutton)
   
      Gcratebutton=display.newImage("Gcratebutton.png",screenw*2,180)
      Gcratebutton:addEventListener(Event.MOUSE_DOWN,newGcrate,Gcratebutton)
      
      Bcratebutton=display.newImage("Bcratebutton.png",screenw*2,180)
      Bcratebutton:addEventListener(Event.MOUSE_DOWN,newBcrate,Bcratebutton)
      
      icebutton=display.newImage("icebutton.png",screenw*2,220)
      icebutton:addEventListener(Event.MOUSE_DOWN,newice,icebutton)

      icebuttonv=display.newImage("icebuttonv.png",screenw*2,220)
      icebuttonv:addEventListener(Event.MOUSE_DOWN,newicev,icebuttonv)

      movplatbutton=display.newImage("movplatbutton.png",screenw*2,260)
      movplatbutton:addEventListener(Event.MOUSE_DOWN,newmovplat,movplatbutton)

      linkbutton=display.newImage("linkbutton.png",screenw*2,300)
      linkbutton:addEventListener(Event.MOUSE_DOWN,newlink,linkbutton)
   end

----------------------------------------------------------------------
-- Set level change buttons
----------------------------------------------------------------------

   if (level==totlevels) then
      inctext:setText("+")
   elseif (level+1<=totlevels) then
      if level+1<1 then
	 inctext:setText("t"..(level+1+5))
      else
	 inctext:setText(level+1)
      end
   else
      inctext:setText("")
   end

--   x,y=inclevel:getPosition()
--   centreAt(inctext,x,y)

   if (level-1>=-4) then
      if level-1<1 then
	 dectext:setText("t"..(level-1+5))
      else
	 dectext:setText(level-1)
      end
   else
      dectext:setText("")
   end

--   x,y=declevel:getPosition()
--   centreAt(dectext,x,y)

   if (level+1<=upto or level==totlevels) then
      inclevel:setColorTransform(0,1,0)   -- green
   else
      inclevel:setColorTransform(1,0,0)   -- red
   end

   if (level-1>=-4) then
      declevel:setColorTransform(0,1,0)
   else
      declevel:setColorTransform(1,0,0)
   end
   
----------------------------------------------------------------------
-- Set correct state for edit button
----------------------------------------------------------------------

   if (not landscape) then
      if (edit) then
	 editbutton:getChildAt(1):setVisible(false)
	 editbutton:getChildAt(2):setVisible(false)
	 editbutton:getChildAt(3):setVisible(true)
      else
	 if (level==upto and upto<nlevels) then
	    editbutton:getChildAt(1):setVisible(true)
	    editbutton:getChildAt(2):setVisible(false)
	    editbutton:getChildAt(3):setVisible(false)
	 else
	    editbutton:getChildAt(1):setVisible(false)
	    editbutton:getChildAt(2):setVisible(true)
	    editbutton:getChildAt(3):setVisible(false)
	 end
      end
   end

----------------------------------------------------------------------
-- Set jump buttons to up and set gravity to down
-- remove ring
----------------------------------------------------------------------

   world:setGravity(0,9.8)
   
   if (ring) then
      ring:removeFromParent()
      ring=nil
   end
   
----------------------------------------------------------------------
-- ensure ego and buttons are at the front
----------------------------------------------------------------------

   local n=stage:getNumChildren()

   stage:addChildAt(ego,n)
   stage:addChildAt(lbutton,n)
   stage:addChildAt(rbutton,n)
   stage:addChildAt(ljbutton,n)
   stage:addChildAt(rjbutton,n)

   if landscape then
      stage:addChildAt(pause,n)
      stage:addChildAt(inclevel,n)
      stage:addChildAt(declevel,n)
      stage:addChildAt(inctext,n)
      stage:addChildAt(dectext,n)
   end

   if (scrolling) then
--      scene:setPosition(-(sscale*egox-screenw/2),-(sscale*egoy-screenh/2))
   else
      scene:setPosition(0,0)
   end

   if (scrolling) then
      scene:setScale(sscale,sscale)
   end

   if landscape and demo then
      demotext=boldtext(myfont,"*DEMO GAME*",0x0,0xff0000)
      demotext:setRotation(90)
      demotext:setPosition(300,140)
      stage:addChild(demotext)
   end

----------------------------------------------------------------------
-- Preload signtext texture if needed
----------------------------------------------------------------------

   if (level==-4) then
      signtext_tex=Texture.new("sign-4.png",true)
   elseif (level==-3) then
      signtext_tex=Texture.new("sign-3.png",true)
   elseif (level==-2) then
      signtext_tex=Texture.new("sign-2.png",true)
   elseif (level==-1) then
      signtext_tex=Texture.new("sign-1.png",true)
   elseif (level==-0) then
      signtext_tex=Texture.new("sign0.png",true)
   elseif (level==1) then
      signtext_tex=Texture.new("sign1.png",true)
   elseif (level==2) then
      signtext_tex=Texture.new("sign2.png",true)
   elseif (level==3) then
      signtext_tex=Texture.new("sign3.png",true)
   elseif (level==4) then
      signtext_tex=Texture.new("sign4.png",true)
   elseif (level==5) then
      signtext_tex=Texture.new("sign5.png",true)
   elseif (level==6) then
      signtext_tex=Texture.new("sign6.png",true)
   elseif (level==7) then
      signtext_tex=Texture.new("sign7.png",true)
   elseif (level==8) then
      signtext_tex=Texture.new("sign8.png",true)
   elseif (level==9) then
      signtext_tex=Texture.new("sign9.png",true)
   elseif (level==12) then
      signtext_tex=Texture.new("sign12.png",true)
   elseif (level==14) then
      signtext_tex=Texture.new("sign14.png",true)
   elseif (level==16) then
      signtext_tex=Texture.new("sign16.png",true)
   elseif (level==17) then
      signtext_tex=Texture.new("sign17.png",true)
-- elseif (level==21) then
--    signtext_tex=Texture.new("sign21.png",true)
   else
      signtext_tex=nil
   end

----------------------------------------------------------------------
-- Prepare transition if required. Call egolives to start level
----------------------------------------------------------------------

   egox_global=egox  -- for egolives
   egoy_global=egoy

   if (trans==2) then
      if (scrolling) then
	 if (landscape) then
	    scene:setPosition(-egox*sscale+screenh/2+2*screenw,-egoy*sscale+screenw/2)
	    GTween.new(scene,fadetime,{x=-egox*sscale+screenh/2,y=-egoy*sscale+screenw/2},
		       {ease=easing.inOutExponential,onComplete=egolives})
	 else
	    scene:setPosition(-(sscale*egox-screenw/2)+screenw,-(sscale*egoy-screenh/2))
	    GTween.new(scene,fadetime,{x=-(sscale*egox-screenw/2)},{ease=easing.inOutExponential,onComplete=egolives})
	 end
      else
	 scene:setX(screenw)
	 GTween.new(scene,fadetime,{x=0},{ease=easing.inOutExponential,onComplete=egolives})
      end
   elseif (trans==1) then

      if (scrolling) then
	 scene:setPosition(oldscenex,oldsceney)
	 GTween.new(scene,fadetime,{x=-egox*sscale+screenh/2,y=-egoy*sscale+screenw/2},
		    {ease=easing.inOutExponential,onComplete=egolives})
      else
	 coin[1]:setAlpha(0)
	 GTween.new(coin[1],fadetime,{alpha=1},{ease=easing.inOutExponential,onComplete=egolives})

	 for i=2,ncoins do
	    coin[i]:setAlpha(0)
	    GTween.new(coin[i],fadetime,{alpha=1},{ease=easing.inOutExponential})
	 end
	 
	 for i=1,ncrate do
	    crate[i]:setAlpha(0)
	    GTween.new(crate[i],fadetime,{alpha=1},{ease=easing.inOutExponential})
	 end
      end
   else
      egolives()
   end

   if (landscape) then
--      scene:setRotation(90)
   end


end           -- function loadlevel

--######################################################################

function onZoom(self,event)

   if self:hitTestPoint(event.x,event.y) then
      if (zoomedOut) then

	 sscale=2

	 local xbody,ybody=ego.body:getPosition()    -- position for box2d
	 GTween.new(scene,0.2,{x=-xbody*sscale+screenh/2,y=-ybody*sscale+screenw/2,scaleX=2,scaleY=2})

	 if shield then GTween.new(shield,0.2,{x=screenh/2,y=screenw/2,scaleX=2,scaleY=2}) end
	 if ring then GTween.new(ring,0.2,{x=screenh/2,y=screenw/2,scaleX=2,scaleY=2}) end

	 GTween.new(zoom:getChildAt(1),0.2,{scaleX=1,scaleY=1})

	 local s
	 if graphics=="space" then
	    s=1
	 else
	    s=2
	 end

	 GTween.new(ego,0.2,{scaleX=s,scaleY=s,x=screenh/2,y=screenw/2},
		    {onComplete=function() stage:addEventListener(Event.ENTER_FRAME,update) end})

	 showbuttons(true)

	 zoomedOut=false
      else                     -- zoom out
--	 scene:setScale(1,1)
	 sscale=1

	 stage:removeEventListener(Event.ENTER_FRAME,update)

	 local xbody,ybody=ego.body:getPosition()    -- position for box2d
	 GTween.new(scene,0.2,{x=-xbody*sscale+screenh/2,y=-ybody*sscale+screenw/2,scaleX=1,scaleY=1})

	 if graphics=="space" then
	    GTween.new(ego,0.2,{scaleX=0.5,scaleY=0.5})
	 else
	    GTween.new(ego,0.2,{scaleX=1,scaleY=1})
	 end

	 if shield then GTween.new(shield,0.2,{scaleX=1,scaleY=1}) end
	 if ring then GTween.new(ring,0.2,{scaleX=1,scaleY=1}) end

	 GTween.new(zoom:getChildAt(1),0.2,{scaleX=0.5,scaleY=0.5})

	 if not zoom_note then
	    popup({"Drag to look","around. Press","\"    \" again","to continue."},
		  {"Got it!"},{nil},{bitmap="zoom2-fronticon.png",x=90,y=230,rotation=0})
	    zoom_note=true

	    fh=io.open("|D|config.txt","w")
	    writeconfig(fh)
	    fh:close()
	 end

	 hidebuttons()

	 zoomedOut=true
      end
   end

end

--######################################################################

function swapplanet()

----------------------------------------------------------------------
-- swap planets over after transitions (called by loadlevel)
----------------------------------------------------------------------

   print ("swapping planet")
   planet:removeFromParent()
   planet=newplanet
   newplanet=nil
end

--######################################################################

function onmake(self,event)
  if self:hitTestPoint(event.x,event.y) then
     if (coinbutton:getX()<screenw) then
	killmenu()
     else
	showmenu()
     end

     event:stopPropagation()
  end
end

function killmenu()
   coinbutton:setX(screenw*2)
   platbutton:setX(screenw*2)
   platbuttonv:setX(screenw*2)
   vbadbutton:setX(screenw*2)
   hbadbutton:setX(screenw*2)
   Sbadbutton:setX(screenw*2)  
   cratebutton:setX(screenw*2)
   Gcratebutton:setX(screenw*2)
   Bcratebutton:setX(screenw*2)
   icebutton:setX(screenw*2)
   icebuttonv:setX(screenw*2)
   movplatbutton:setX(screenw*2)
   linkbutton:setX(screenw*2)
end

function showmenu()
   coinbutton:setX(screenw-100)
   platbutton:setX(screenw-100)
   platbuttonv:setX(screenw-60)
   vbadbutton:setX(screenw-100)
   hbadbutton:setX(screenw-60)
   Sbadbutton:setX(screenw-20)
   cratebutton:setX(screenw-100)
   Gcratebutton:setX(screenw-60)
   Bcratebutton:setX(screenw-20)
   icebutton:setX(screenw-100)
   icebuttonv:setX(screenw-60)
   movplatbutton:setX(screenw-100)
   linkbutton:setX(screenw-100)
end


--######################################################################

function egolives()

   local egox,egoy,egoand,body,shape,x,y,ang,w,h

----------------------------------------------------------------------
-- set up ego as physics body. Store this as ego.body
----------------------------------------------------------------------
   
   if not edit then
      ljbutton:setScale(1,1)
      rjbutton:setScale(1,1)
   end

   if (scrolling) then
      egox,egoy=egox_global,egoy_global
--      egox=(-scene:getX()+screenw/2)/sscale
--      egoy=(-scene:getY()+screenh/2)/sscale
   else
      egox,egoy=ego:getPosition()
   end

   egoang=ego:getRotation()*math.pi/180

   body=world:createBody({type=b2.DYNAMIC_BODY, position={x=egox,y=egoy}, 
				angle=egoang,allowSleep=false})

   shape=b2.PolygonShape.new()
   shape:setAsBox(radius,radius)

   body:createFixture({shape=shape, density=1, restitution=0.0, friction=0.6})

   ego.body=body
   ego.body.parent=ego

----------------------------------------------------------------------
-- set up platforms as STATIC physics bodies
----------------------------------------------------------------------

   for i=1,nplatform do
      x,y=platform[i]:getPosition()
      ang=platform[i]:getRotation()*math.pi/180

      w,h=platform[i].width,platform[i].height

      body=world:createBody({type=b2.STATIC_BODY, position={x=x,y=y},angle=ang})

      shape=b2.PolygonShape.new()
      shape:setAsBox(w/2,h/2)

      if (platform[i].isice) then
	 body:createFixture({shape=shape,restitution=0.0, friction=0.0})
      else
	 body:createFixture({shape=shape,restitution=0.0, friction=0.6})
      end

      platform[i].body=body
      platform[i].body.parent=platform[i]
   end

----------------------------------------------------------------------
-- set up crates as dynamic physics bodies
----------------------------------------------------------------------

   for i=1,ncrate do
      x,y=crate[i]:getPosition()
      ang=crate[i]:getRotation()*math.pi/180

      w,h=crate[i].width,crate[i].height

      body=world:createBody({type=b2.DYNAMIC_BODY, position={x=x,y=y},angle=ang,allowSleep=false})

      shape=b2.PolygonShape.new()
      shape:setAsBox(w/2,h/2)

      body:createFixture({shape=shape, density=1, restitution=0.1, friction=0.1})

      crate[i].body=body
      crate[i].body.parent=crate[i]
   end

----------------------------------------------------------------------
-- Add update as ENTER_FRAME listener
-- Add global touches
----------------------------------------------------------------------

   stage:addEventListener(Event.ENTER_FRAME, update)

   if (not edit) then
      if multitouch then
	 stage:addEventListener(Event.TOUCHES_BEGIN, MtouchDOWN, "DOWN")
	 stage:addEventListener(Event.TOUCHES_MOVE,  MtouchDOWN, "MOVE")
	 stage:addEventListener(Event.TOUCHES_END,   MtouchUP)
      else
	 stage:addEventListener(Event.MOUSE_DOWN, gtouchDOWN, "DOWN")
	 stage:addEventListener(Event.MOUSE_MOVE, gtouchDOWN, "MOVE")
	 stage:addEventListener(Event.MOUSE_UP,   gtouchUP)
      end
   end

   world:addEventListener(Event.BEGIN_CONTACT,collideBEGIN)
   world:addEventListener(Event.END_CONTACT,collideEND)

   inclevel:addEventListener(Event.MOUSE_DOWN,nextlevel,inclevel)
   declevel:addEventListener(Event.MOUSE_DOWN,prevlevel,declevel)

   if pause then
      pause:addEventListener(Event.MOUSE_DOWN,onpause,pause)
   end

   if (not landscape) then
      editbutton:addEventListener(Event.MOUSE_DOWN,onEdit,editbutton)
   end

   if (edit) then 
      ego:addEventListener(Event.MOUSE_DOWN,dragDown,ego) 
      ego:addEventListener(Event.MOUSE_MOVE,dragMove,ego) 
      ego:addEventListener(Event.MOUSE_UP,dragUp,ego) 
   end

----------------------------------------------------------------------
-- Add shield
----------------------------------------------------------------------

   if (not edit) then
      shield=display.newImage("shield.png")
      shield:setPosition(ego:getPosition())

      if (scrolling) then
	 shield:setScale(2,2)
      end

      if graphics=="xmas" then
	 if (scrolling) then
	    shield:setScale(3,3)
	 else
	    shield:setScale(1.5,1.5)
	 end
      end
   end

----------------------------------------------------------------------
-- Activate zoom button
----------------------------------------------------------------------

   if (zoom) then
      zoom:addEventListener(Event.MOUSE_DOWN,onZoom,zoom)
   end

----------------------------------------------------------------------
-- In demo mode pop up nag signs
----------------------------------------------------------------------

   if demo and trans==2 and upto>=nlevels then
      if level==1 then
	 popup({"Congrats! You", "have beaten the","demo version.",
		"Please consider","the full game.","Search for:","'NEBULA RETRO'"},{"OK"},{nil})
      elseif level==2 then
	 popup({"The full game","has more","game mechanics","for complex","puzzles!"},{"OK"},{nil})
      elseif level==3 then
	 popup({"The full game","has","ANTI GRAVITY!","and",
		"ROCKET BOOST!","(Multi jump in","the air)"},{"OK"},{nil})
      elseif level==4 then
	 popup({"The full game","has","TOUCH PLATFORMS","(open doors,",
		"remove floors)",
		"PLEASE BUY","'NEBULA RETRO'!"},{"OK"},{nil})
      elseif level==5 then
	 popup({"To get all","features and","26 levels,","please buy the","full game:",
	       "'NEBULA RETRO',","from your","app store!"},{"OK"},{nil},
	       {bitmap="ego.png",x=230,y=300,rotation=0})
      end
   end

   playing=true
end

function killlevel()

----------------------------------------------------------------------
-- kill level
-- remove enterFrame, collision and button touch events
-- transition objects out and call removelevel to get rid of them
----------------------------------------------------------------------

   playing=false

   local fadetime

   world:removeEventListener(Event.BEGIN_CONTACT,collideBEGIN)
   world:removeEventListener(Event.END_CONTACT,collideEND)
   
   stage:removeEventListener(Event.ENTER_FRAME,update)

   if (multitouch) then
      stage:removeEventListener(Event.TOUCHES_BEGIN,MtouchDOWN, "DOWN")
      stage:removeEventListener(Event.TOUCHES_MOVE, MtouchDOWN, "MOVE")
      stage:removeEventListener(Event.TOUCHES_END,  MtouchUP)
   else
      stage:removeEventListener(Event.MOUSE_DOWN,gtouchDOWN, "DOWN")
      stage:removeEventListener(Event.MOUSE_MOVE,gtouchDOWN, "MOVE")
      stage:removeEventListener(Event.MOUSE_UP,  gtouchUP)
   end

   inclevel:removeEventListener(Event.MOUSE_DOWN,nextlevel,inclevel)
   declevel:removeEventListener(Event.MOUSE_DOWN,prevlevel,declevel)

   if pause then
      pause:removeEventListener(Event.MOUSE_DOWN,onpause,pause)
   end

   if (editbutton) then
      editbutton:removeEventListener(Event.MOUSE_DOWN,onEdit,editbutton)
   end

   if (trans==2) then
      fadetime=2
   elseif (trans==1) then
      fadetime=1
   else
      fadetime=1/30
   end

   if (trans==0) then
      removelevel()
   else

      if hat then GTween.new(hat,fadetime,{y=-screenh}) end

      for i=1,ncoins do
	 if (coin[i]) then 
	    GTween.new(coin[i],fadetime,{alpha=0})
	 end
      end
      
      for i=1,nbaddy do
	 if (baddy[i]) then
	    GTween.new(baddy[i],fadetime,{alpha=0})
	 end
      end
   
      for i=1,ncrate do
	 if (crate[i]) then
	    GTween.new(crate[i],fadetime,{alpha=0})
	 end
      end

      if (sign) then
	 GTween.new(sign,fadetime,{alpha=0})
      end
      
      if (trans==2) then
	 GTween.new(platform[1],fadetime,{alpha=0},{onComplete=removelevel})
      else
	 GTween.new(platform[1],fadetime,{alpha=1},{onComplete=removelevel})
      end
      
      if (trans==2) then
	 for i=2,nplatform do
	    if (platform[i]) then
	       GTween.new(platform[i],fadetime,{alpha=0})
	    end
	 end
      end

   end  -- trans != 0

end

--######################################################################

function removelevel()

----------------------------------------------------------------------
-- Delete all objects of the level
-- then call loadlevel to load the next level
----------------------------------------------------------------------

   if demotext then
      demotext:removeFromParent()
      demotext=nil
   end

   if popup_sprite then
      popup_sprite:removeFromParent()
      popup_sprite=nil
   end

   if (zoom) then
      zoom:removeFromParent()
      zoom=nil
   end

   if (signtext) then
      signtext:removeFromParent()
      signtext=nil
   end

   if (ring) then
      ring:removeFromParent()
      ring=nil
   end

   if (shield) then
      shield:removeFromParent()
      shield=nil
   end

   if (hat) then
      hat:removeFromParent()
      hat=nil
   end

   if (sparkle) then
      sparkle:removeFromParent()
      sparkle=nil
   end

   if (sign) then
      sign:removeFromParent()
      sign=nil
   end

   if (hint) then
      hint:removeFromParent()
      hint=nil
   end
   
   for i=1,ncoins do
      if (coin[i]) then 
	 coin[i]:removeFromParent()
	 coin[i]=nil
      end
   end
   coin=nil
   
   for i=1,nbaddy do
      if (baddy[i]) then
	 if (baddy[i].core) then
	    baddy[i].core:removeFromParent()
	    baddy[i].core=nil
	 end

	 baddy[i]:removeFromParent()
	 baddy[i]=nil
      end
   end
   baddy=nil
   
   for i=1,nplatform do
      if (platform[i]) then
	 if (platform[i].core) then
	    platform[i].core:removeFromParent()
	    platform[i].core=nil
	 end
	 
	 world:destroyBody(platform[i].body)

	 if (platform[i].sparkle) then
	    platform[i].sparkle:removeFromParent()
	    platform[i].sparkle=nil
	 end

	 if (platform[i].linkline) then
	    platform[i].linkline:removeFromParent()
	    platform[i].linkline=nil
	 end

	 platform[i]:removeFromParent()
	 platform[i]=nil
      end
   end
   platform=nil
   
   for i=1,ncrate do
      if (crate[i]) then
	 world:destroyBody(crate[i].body)
	 crate[i]:removeFromParent()
	 crate[i]=nil
      end
   end
   crate=nil

   oldscenex,oldsceney=scene:getPosition()
   scene:removeFromParent()
   scene=nil

   if (makebutton) then
      ego:removeEventListener(Event.MOUSE_DOWN,dragDown,ego)
      ego:removeEventListener(Event.MOUSE_MOVE,dragMove,ego)
      ego:removeEventListener(Event.MOUSE_UP,dragUp,ego)

      makebutton:removeFromParent(); makebutton=nil
      mode:removeFromParent(); mode=nil

      coinbutton:removeFromParent(); coinbutton=nil
      platbutton:removeFromParent(); platbutton=nil
      platbuttonv:removeFromParent(); platbuttonv=nil
      vbadbutton:removeFromParent(); vbadbutton=nil
      hbadbutton:removeFromParent(); hbadbutton=nil
      Sbadbutton:removeFromParent(); Sbadbutton=nil
      cratebutton:removeFromParent(); cratebutton=nil
      Bcratebutton:removeFromParent(); Bcratebutton=nil
      Gcratebutton:removeFromParent(); Gcratebutton=nil
      icebutton:removeFromParent(); icebutton=nil
      icebuttonv:removeFromParent(); icebuttonv=nil
      movplatbutton:removeFromParent(); movplatbutton=nil
      linkbutton:removeFromParent(); linkbutton=nil
   end

   if (pause) then
      pause:removeFromParent(); pause=nil
   end

   if (leveltxt) then
      leveltxt:removeFromParent()
      leveltxt=nil
   end

   if (inclevel) then
      inclevel:removeFromParent()
      inclevel=nil

      declevel:removeFromParent()
      declevel=nil

      inctext:removeFromParent()
      inctext=nil

      dectext:removeFromParent()
      dectext=nil
   end

   if (editbutton) then
      editbutton:removeFromParent()
      editbutton=nil
   end

   world:destroyBody(ego.body)         -- destroy ego's body

   if (trans > -1) then
      loadlevel()
   end
end

--######################################################################

-- local myplat,fadetween

function collideBEGIN(event)

----------------------------------------------------------------------
-- ego collide event
----------------------------------------------------------------------

--   local typeA=event.fixtureA:getBody().type
--   local typeB=event.fixtureB:getBody().type

   local objectA=event.fixtureA:getBody().parent
   local objectB=event.fixtureB:getBody().parent

   if ((objectA==ego and not objectB.isice) or (objectB==ego and not objectA.isice)) then
     ncoll=ncoll+1
     onground=true
   end
   
----------------------------------------------------------------------
-- collision of green crates
----------------------------------------------------------------------

   local i,dy,dx
   local gx,gy=world:getGravity()

   if (objectA.isgreen=="yes" and objectB.isgreen=="yes") then

      local sx,sy
      if threebutton then
	 sx=-1
	 sy=-1
      else
	 sx=1
	 sy=-1
      end
	 
      if (landscape) then
	 dx=planet:getX()-screenw/2

	 GTween.new(planet,1,{x=screenw/2-dx},{ease=easing.inOutExponential})

	 if (gy>0) then
	    world:setGravity(0,-9.8)
	    if not edit then
	       ljbutton:setScale(sx,sy)
	       rjbutton:setScale(sx,sy)
	    end
	 else
	    world:setGravity(0,9.8)
	    if not edit then
	       ljbutton:setScale(1,1)
	       rjbutton:setScale(1,1)
	    end
	 end

      else

	 dy=math.abs(planet:getY()-screenh/2)

	 if (gy>0) then
	    GTween.new(planet,1,{y=screenh/2-dy},{ease=easing.inOutExponential})
	    world:setGravity(0,-9.8)
	    if not edit then
	       ljbutton:setScale(sx,sy)
	       rjbutton:setScale(sx,sy)
	    end
	 else
	    GTween.new(planet,1,{y=screenh/2+dy},{ease=easing.inOutExponential})
	    world:setGravity(0,9.8)
	    if not edit then
	       ljbutton:setScale(1,1)
	       rjbutton:setScale(1,1)
	    end
	 end
      end

      if (edit) then
	 objectA:setColorTransform(0,60,0)
	 objectB:setColorTransform(0,60,0)
	 objectA.isgreen="inactive"
	 objectB.isgreen="inactive"
      else
	 objectA:setColorTransform(120,120,0)
	 objectB:setColorTransform(120,120,0)
	 objectA.isgreen="no"
	 objectB.isgreen="no"

	 if (fxstat=="ON") then
	    antigrav:play()
	 end
      end

   end

----------------------------------------------------------------------
-- collision of blue crates
----------------------------------------------------------------------

   if (objectA.isblue=="yes" and objectB.isblue=="yes") then
      
      if (edit) then
	 objectA:setColorTransform(0,120,120)
	 objectB:setColorTransform(0,120,120)
	 objectA.isblue="inactive"
	 objectB.isblue="inactive"
      else
	 objectA:setColorTransform(120,120,0)
	 objectB:setColorTransform(120,120,0)
	 objectA.isblue="no"
	 objectB.isblue="no"

	 if (fxstat=="ON") then
	    rocket:play()
	 end

	 ring=display.newImage("ring.png",0,0)
	 ring:setPosition(ego:getPosition())
	 if landscape then
	    ring:setScale(2,2)
	 end
      end

   end

----------------------------------------------------------------------
-- Touch sensitive platform pause
----------------------------------------------------------------------

   local t=nil

   if objectA.isPlatform then
      t=objectA
   elseif objectB.isPlatform then
      t=objectB
   end

   if t and not t.ismoving and not t.isice then
      if t.link<=nplatform then

	 local ncolp=platform[t.link].ncolp
	 ncolp=ncolp+1
	 platform[t.link].ncolp=ncolp

	 if ncolp==1 then
	    platform[t.link].waning=true
	    platform[t.link].waxing=false
	    platform[t.link].fadecnt=0

	    if (fxstat=="ON") then
--	       bumpsound:play()
	    end

	 end

      end
   end

end

function collideEND(event)
--   local typeA=event.fixtureA:getBody().type
--   local typeB=event.fixtureB:getBody().type

--   if ((typeA=="ego" and typeB~="ice") or (typeB=="ego" and typeA~="ice")) then

   local objectA=event.fixtureA:getBody().parent
   local objectB=event.fixtureB:getBody().parent

   if ((objectA==ego and not objectB.isice) or (objectB==ego and not objectA.isice)) then

      ncoll=ncoll-1   

      if (ncoll==0) then
         onground=false
      end
   end

----------------------------------------------------------------------
-- Touch sensitive platform resume
----------------------------------------------------------------------

   local t=nil

   if objectA.isPlatform then
      t=objectA
   elseif objectB.isPlatform then
      t=objectB
   end

   if t and not t.ismoving and not t.isice then
      if t.link <= nplatform then

	 local ncolp=platform[t.link].ncolp
	 ncolp=ncolp-1
	 platform[t.link].ncolp=ncolp

	 if ncolp==0 then
	    platform[t.link].waxing=true
	    platform[t.link].waning=false
	    platform[t.link].fadecnt=0
	 end

--	 if (edit) then
--	    fadetween=GTween.new(platform[myplat].core,1,{alpha=1},{onComplete=resumeplat})
--	 else
--	    fadetween=GTween.new(platform[myplat],1,{alpha=1},{onComplete=resumeplat})
--	 end

      end
   end

end

--######################################################################

activeID=nil

function gtouchUP(event)
   leftpressed=false
   rightpressed=false
end

function MtouchUP(event)
   if event.touch.id==activeID then
      leftpressed=false
      rightpressed=false
   end
end

--######################################################################

function gtouchDOWN(type,event)

   local x=event.x
   local y=event.y

   if zoomedOut then
      if type=="DOWN" then
	 x0=event.x
	 y0=event.y
      else
	 local dx = event.x - x0
	 local dy = event.y - y0
      
	 scene:setX(scene:getX() + dx)
	 scene:setY(scene:getY() + dy)

	 ego:setX(ego:getX() + dx)
	 ego:setY(ego:getY() + dy)

	 if shield then
	    shield:setX(shield:getX() + dx)
	    shield:setY(shield:getY() + dy)
	 end

	 if ring then
	    ring:setX(ring:getX() + dx)
	    ring:setY(ring:getY() + dy)
	 end

	 if hat then
	    hat:setX(hat:getX() + dx)
	    hat:setY(hat:getY() + dy)
	 end

	 x0 = event.x
	 y0 = event.y
      end
      return
   end

   print ("os name=",osname)
   if string.sub(osname,1,7)=="Windows" then   -- windows, so no touch controls
      print ("early return")
      return
   end

   if (x>lbutton:getX()-butrad and x<lbutton:getX()+butrad and
       y>lbutton:getY()-butrad and y<lbutton:getY()+butrad) then
      leftpressed=true
      rightpressed=false
   end

   if (x>rbutton:getX()-butrad and x<rbutton:getX()+butrad and
       y>rbutton:getY()-butrad and y<rbutton:getY()+butrad) then
      leftpressed=false
      rightpressed=true
   end

   if (type=="DOWN") then

      local gx,gy=world:getGravity()
      
      if ((onground or ring) and 
	  x>ljbutton:getX()-butrad and x<ljbutton:getX()+butrad and
	  y>ljbutton:getY()-butrad and y<ljbutton:getY()+butrad) then
	 
	 if (gy>0) then
	    ego.body:setLinearVelocity(-1.4,-7.0)
	 else
	    ego.body:setLinearVelocity(-1.4, 7.0)
	 end
      end
   
      if ((onground or ring) and
	  x>rjbutton:getX()-butrad and x<rjbutton:getX()+butrad and
	  y>rjbutton:getY()-butrad and y<rjbutton:getY()+butrad) then
	 
	 if (gy>0) then
	    ego.body:setLinearVelocity( 1.4,-7.0)
	 else
	    ego.body:setLinearVelocity( 1.4, 7.0)
	 end
      end
   
   end    -- type is "DOWN"
end

--######################################################################

function MtouchDOWN(type,event)

   local x=event.touch.x
   local y=event.touch.y

   if signtext then
      if signtext:getChildAt(3):hitTestPoint(x,y) then
	 return
      end
   end

   if zoomedOut then

      if event.touch.id ~= 1 then   -- simulate single touch
	 return
      end

      if type=="DOWN" then
	 x0=x
	 y0=y
      else
	 local dx = x - x0
	 local dy = y - y0
      
	 scene:setX(scene:getX() + dx)
	 scene:setY(scene:getY() + dy)

	 ego:setX(ego:getX() + dx)
	 ego:setY(ego:getY() + dy)

	 if shield then
	    shield:setX(shield:getX() + dx)
	    shield:setY(shield:getY() + dy)
	 end

	 if ring then
	    ring:setX(ring:getX() + dx)
	    ring:setY(ring:getY() + dy)
	 end

	 x0 = x
	 y0 = y
      end
      return
   end

   if string.sub(osname,1,7)=="Windows" then   -- windows, so no touch controls
      return
   end

   if (x>lbutton:getX()-butrad and x<lbutton:getX()+butrad and
       y>lbutton:getY()-butrad and y<lbutton:getY()+butrad) then
      leftpressed=true
      rightpressed=false
      activeID=event.touch.id
   end

   if (x>rbutton:getX()-butrad and x<rbutton:getX()+butrad and
       y>rbutton:getY()-butrad and y<rbutton:getY()+butrad) then
      leftpressed=false
      rightpressed=true
      activeID=event.touch.id
   end

   if (type=="DOWN") then
      
      if (not threebutton and (onground or ring) and 
	  x>ljbutton:getX()-butrad and x<ljbutton:getX()+butrad and
	  y>ljbutton:getY()-butrad and y<ljbutton:getY()+butrad) then

	 local gx,gy=world:getGravity()
	 local vx

	 if threebutton then
	    vx=ego.body:getLinearVelocity()
	 else
	    vx=-1.4
	 end
	 
	 if (gy>0) then
	    ego.body:setLinearVelocity(vx,-7.0)
	 else
	    ego.body:setLinearVelocity(vx, 7.0)
	 end
      end

      if ((onground or ring) and
	  x>rjbutton:getX()-butrad and x<rjbutton:getX()+butrad and
	  y>rjbutton:getY()-butrad and y<rjbutton:getY()+butrad) then

	 local gx,gy=world:getGravity()
	 local vx

	 if threebutton then
	    vx=ego.body:getLinearVelocity()
	 else
	    vx=1.4
	 end
	 
	 if (gy>0) then
	    ego.body:setLinearVelocity(vx,-7.0)
	 else
	    ego.body:setLinearVelocity(vx, 7.0)
	 end
      end
   
   end    -- type is "DOWN"
end

----------------------------------------------------------------------
-- Main program
----------------------------------------------------------------------

function main()

   onground=false
   ncoll=0
   
   ego:setX(160)
   ego:setY(200)

----------------------------------------------------------------------
-- Set left/right/jump buttons
-- set inc/dec level
----------------------------------------------------------------------

   lbutton=display.newImage("left.png")
   rbutton=display.newImage("right.png")
   
   ljbutton=display.newImage("upleft.png")
   rjbutton=display.newImage("upright.png")

   if osname=="Windows" then
     lbutton:setAlpha(0)
     rbutton:setAlpha(0)
     ljbutton:setAlpha(0)
     rjbutton:setAlpha(0)
   else
     lbutton:setAlpha(0.7)
     rbutton:setAlpha(0.7)
     ljbutton:setAlpha(0.7)
     rjbutton:setAlpha(0.7)
   end

   initlevels()  -- sets totlevels and upto. set controls, controls_ht
   level=upto
   		     
   hidebuttons()        -- invisible

   if threebutton then
      ljbutton:setVisible(false)
   end

   stage:addEventListener(Event.APPLICATION_RESUME,onResume)
   stage:addEventListener(Event.KEY_DOWN,onKeyDown)
   stage:addEventListener(Event.KEY_UP,onKeyUp)

   trans=1
   main_menu()

end

function onResume()

   if music then
      print("resuming")
      music:stop()
      music=nil

      local sound=Sound.new(currmusic)
      music=sound:play(0,myhuge)
      music:setVolume(0.75)
   end
end

main()
