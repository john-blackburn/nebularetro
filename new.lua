-- colour change
-- link
-- in edit mode, consider wrap around.

-- moving platforms and baddies both have a "core" which represents range
-- each core has a link to parent
-- platform[i].core.parent=platform[i]
-- cores also have .width and .height

platform,nplatform=nil,nil   -- global
coin,ncoins=nil,nil
crate,ncrate=nil,nil
baddy,nbaddy,baddyRect=nil,nil,nil

local display=require("display")

function addBody(sprite,type,table)

-- Add a rectangular body to existing sprite
-- sprite.width and sprite.height must be set

   local x,y,ang,w,h,body,shape,mytype

   if (type=="static") then
      mytype=b2.STATIC_BODY
   elseif (type=="dynamic") then
      mytype=b2.DYNAMIC_BODY
   elseif (type=="kinematic") then
      mytype=b2.KINEMATIC_BODY
   end

   x,y=sprite:getPosition()
   ang=sprite:getRotation()*math.pi/180

   w,h=sprite.width, sprite.height
   
   body=world:createBody({type=mytype, position={x=x,y=y}, angle=ang})

   shape=b2.PolygonShape.new()
   shape:setAsBox(w/2,h/2)

   body:createFixture({shape=shape, restitution=table.bounce, friction=table.friction})
   
   sprite.body=body
   sprite.body.parent=sprite        -- so we can find sprite from the body during b2 collisions
end

--######################################################################

-- eg call with width, height, colour. requirement for ice
-- function checks to see if is is called with self,event or other
-- if first parameter is table,assumes self, event
-- newicev(arg1,arg2,arg3...)
-- if type(arg1)=="table" then
--    self=arg1
--    event=arg2
-- end
-- if called as listener, then use default positioning and set body
-- if called when setting level, pay attention to positioning, rotation
-- if edit mode, then set listeners for this object

-- addPlatform: set up platform with width, height, position, rotation, and optional core
-- In edit mode, add core and listeners. Do not add body, caller will add this if needed using addBody
-- addplatform(i,w,h,r,g,b) cope with regular platform and ice

-- newicev
-- addPlatform(nplatform, 20,100, 0,0,0)
-- addBody
-- platform[nplatform].isice=true

function newicev(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()

      nplatform=nplatform+1
      platform[nplatform]=display.newRect(40,120, 255,255,255)
      platform[nplatform]:setPosition(100,100)

      platform[nplatform].width=20
      platform[nplatform].height=100

      platform[nplatform].red=-2
      platform[nplatform].green=0
      platform[nplatform].blue=0
      platform[nplatform].link=255

      addBody(platform[nplatform],"static",{friction=0,bounce=0})

      platform[nplatform].isPlatform=true
      platform[nplatform].isice=true

      platform[nplatform]:addEventListener(Event.MOUSE_DOWN,dragDown,platform[nplatform])
      platform[nplatform]:addEventListener(Event.MOUSE_MOVE,dragMove,platform[nplatform])
      platform[nplatform]:addEventListener(Event.MOUSE_UP,dragUp,platform[nplatform])

      platform[nplatform].core=display.newRect(20,100, 0,0,0)
      platform[nplatform].core:setPosition(platform[nplatform]:getPosition())
   end

end

--######################################################################

function newice(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()

      nplatform=nplatform+1
      platform[nplatform]=display.newRect(120,40, 255,255,255)
      platform[nplatform]:setPosition(100,100)

      platform[nplatform].width=100
      platform[nplatform].height=20

      platform[nplatform].red=-2
      platform[nplatform].green=0
      platform[nplatform].blue=0
      platform[nplatform].link=255

      addBody(platform[nplatform],"static",{friction=0,bounce=0})

      platform[nplatform].isPlatform=true
      platform[nplatform].isice=true

      platform[nplatform]:addEventListener(Event.MOUSE_DOWN,dragDown,platform[nplatform])
      platform[nplatform]:addEventListener(Event.MOUSE_MOVE,dragMove,platform[nplatform])
      platform[nplatform]:addEventListener(Event.MOUSE_UP,dragUp,platform[nplatform])

      platform[nplatform].core=display.newRect(100,20, 0,0,0)
      platform[nplatform].core:setPosition(platform[nplatform]:getPosition())
   end

end

--######################################################################

function newmovplat(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()

      nplatform=nplatform+1
      platform[nplatform]=display.newRect(100,10, 0,0,255, 1, 255,255,0, 2)   -- blue with yellow trim
      platform[nplatform]:setPosition(100,100)

      platform[nplatform].width=100
      platform[nplatform].height=10

      platform[nplatform].red=-1          -- indicates moving platform
      platform[nplatform].green=70        -- top of range
      platform[nplatform].blue=170        -- bottom of range
      platform[nplatform].link=255        -- not linked

      platform[nplatform].start=70
      platform[nplatform].ends=170
      platform[nplatform].ismoving=true
      platform[nplatform].speed=1

      addBody(platform[nplatform],"kinematic",{friction=0.6,bounce=0})

      platform[nplatform].core=display.newRect(100,100, 0,255,0, 0.5, 255,255,255, 2) -- green, white trim
      platform[nplatform].core:setPosition(100,120)   -- y=(70+170)/2

      platform[nplatform].core.width=100
      platform[nplatform].core.height=100
      platform[nplatform].core.parent=platform[nplatform]

      platform[nplatform].core:addEventListener(Event.MOUSE_DOWN,movingDOWN,platform[nplatform].core)
      platform[nplatform].core:addEventListener(Event.MOUSE_MOVE,movingMOVE,platform[nplatform].core)
      platform[nplatform].core:addEventListener(Event.MOUSE_UP,  movingUP,  platform[nplatform].core)
   end

end

--######################################################################
-- These functions are for moving platforms and h/v baddies

function movingDOWN(self,event)

   -- do not take focus if we are tapping on a movement button
   if  lbutton:hitTestPoint(event.x,event.y) or 
       rbutton:hitTestPoint(event.x,event.y) or
      ljbutton:hitTestPoint(event.x,event.y) or 
      rjbutton:hitTestPoint(event.x,event.y) then
      
      return
   end

   if (self:hitTestPoint(event.x,event.y)) then

      if (modestate=="S") then
	 self.isFocus = true
	 
	 self.x0 = event.x
	 self.y0 = event.y
	 
	 event:stopPropagation()

      elseif (modestate=="G") then
	 self.isFocus = true
	 
	 self.x0 = event.x
	 self.y0 = event.y
	 
	 self.w0 = self.width
	 self.h0 = self.height
	 
	 event:stopPropagation()
	 
      elseif (modestate=="D") then
	 
	 self.deleted=true
	 self.parent.deleted=true
	 event:stopPropagation()

	 onsave()
	 trans=0
--	 ncoll=0
	 killlevel()

      elseif (modestate=="x2" and self.parent.isbaddy) then
	 local speed=self.parent.speed
	 speed=speed*2

	 if speed>4 then
	    speed=0.5
	 elseif speed<-4 then
	    speed=-0.5
	 end

	 self.parent.speed=speed

	 print ("new speed=",self.parent.speed)

	 onsave()
	 trans=0
	 killlevel()

      end

   end
end

function movingMOVE(self,event)

   if self.isFocus then
      local dx = event.x - self.x0
      local dy = event.y - self.y0
		
      if (modestate=="S") then

	 self:setX(self:getX() + dx)
	 self:setY(self:getY() + dy)
	 
      elseif (modestate=="G") then

	 if ((self.width >10 or dx>0) and self.parent.dir~=2) then self.width=self.width+dx end
	 if ((self.height>10 or dy>0) and self.parent.dir~=1) then self.height=self.height+dy end
	 
--	 print (self.width,self.height)
	 
	 self:setScale((self.width+20)/(self.w0+20),(self.height+20)/(self.h0+20))
	 
      end
		
      self.x0 = event.x
      self.y0 = event.y
      
      event:stopPropagation()
   end
end

function movingUP(self,event)
   if self.isFocus then
      self.isFocus = false

      self.parent:setPosition(self:getPosition())

      if (self.parent.dir==1) then
	 self.parent.start=self:getX()-self.width/2
	 self.parent.ends= self:getX()+self.width/2
      elseif (self.parent.dir==2) then
	 self.parent.start=self:getY()-self.height/2
	 self.parent.ends= self:getY()+self.height/2
      else                                -- moving platform
	 self.parent.width=self.width	    
	 self.parent.body:setPosition(self:getPosition())
	 self.parent.red=-1
	 self.parent.green=self:getY()-self.height/2
	 self.parent.blue= self:getY()+self.height/2
      end

      event:stopPropagation()
      
      onsave()
      trans=0
--      ncoll=0
      killlevel()
   end
end

--######################################################################

function addplatform(x,y,ang,width,height,red,green,blue)

-- add new platform or ice

   nplatform=nplatform+1

   if (red<0) then
      platform[nplatform]=display.newRect(width+20,height+20, 255,255,255)
   else
      platform[nplatform]=display.newRect(width+20,height+20,255-red,255-green,255-blue)
   end

   platform[nplatform]:setPosition(x,y)
   platform[nplatform]:setRotation(ang)

   platform[nplatform].red=red
   platform[nplatform].green=green
   platform[nplatform].blue=blue
   platform[nplatform].link=255

   platform[nplatform].width=width
   platform[nplatform].height=height

   platform[nplatform].hue, platform[nplatform].sat, platform[nplatform].val =
      rgb2hsv(red,green,blue)

   addBody(platform[nplatform],"static",{friction=0.6,bounce=0})
   platform[nplatform].isPlatform=true
   platform[nplatform].ncolp=0

   platform[nplatform]:addEventListener(Event.MOUSE_DOWN,dragDown,platform[nplatform]) 
   platform[nplatform]:addEventListener(Event.MOUSE_MOVE,dragMove,platform[nplatform]) 
   platform[nplatform]:addEventListener(Event.MOUSE_UP,dragUp,platform[nplatform]) 

   if (red<0) then
      platform[nplatform].core=display.newRect(width,height, 0,0,0)
   else
      platform[nplatform].core=display.newRect(width,height, red,green,blue)
   end

   platform[nplatform].core:setPosition(x,y)
   platform[nplatform].core:setRotation(ang)
end

function newplatform(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()
      addplatform(100,100,0, 100,10, 0,0,255)
   end

end

--######################################################################

function newlink(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()

      local x1,y1=50,100
      local x2,y2=100,120

      addplatform(x1,y1,0, 100,10, 255,  0,0)
      addplatform(x2,y2,0, 100,10,   0,255,0)

      platform[nplatform-1].link=nplatform

      platform[nplatform-1].linkline=Shape.new()
      platform[nplatform-1].linkline:setLineStyle(5,0xffffff,1)
      
      local dist=math.sqrt((x1-x2)^2+(y1-y2)^2)
      local ang=math.atan2(y2-y1,x2-x1)*180/math.pi

      platform[nplatform-1].linkline:beginPath()
      platform[nplatform-1].linkline:moveTo(0,0)
      platform[nplatform-1].linkline:lineTo(dist,0)
      platform[nplatform-1].linkline:lineTo(dist-10,-10)
      platform[nplatform-1].linkline:lineTo(dist-10, 10)
      platform[nplatform-1].linkline:lineTo(dist,0)
      platform[nplatform-1].linkline:endPath()

      platform[nplatform-1].linkline:setPosition(x1,y1)
      platform[nplatform-1].linkline:setRotation(ang)
      
      stage:addChild(platform[nplatform-1].linkline)

   end
end

--######################################################################

function newplatformv(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()

      nplatform=nplatform+1
      platform[nplatform]=display.newRect(30,120, 255,255,0)
      platform[nplatform]:setPosition(100,100)

      platform[nplatform].red=0
      platform[nplatform].green=0
      platform[nplatform].blue=255
      platform[nplatform].link=255

      platform[nplatform].width=10
      platform[nplatform].height=100

      platform[nplatform].hue, platform[nplatform].sat, platform[nplatform].val =
	 rgb2hsv(0,0,255)

      addBody(platform[nplatform],"static",{friction=0.6,bounce=0})
      platform[nplatform].isPlatform=true

      platform[nplatform]:addEventListener(Event.MOUSE_DOWN,dragDown,platform[nplatform]) 
      platform[nplatform]:addEventListener(Event.MOUSE_MOVE,dragMove,platform[nplatform]) 
      platform[nplatform]:addEventListener(Event.MOUSE_UP,dragUp,platform[nplatform]) 

      platform[nplatform].core=display.newRect(10,100, 0,0,255)
      platform[nplatform].core:setPosition(platform[nplatform]:getPosition())
   end

end

--######################################################################

function newcoin(self,event)

   if (self:hitTestPoint(event.x,event.y)) then
      
      killmenu()

      ncoins=ncoins+1
      if graphics=="xmas" then
	 coin[ncoins]=display.newImage("bigcoin_xmas.png",50,50)
      else
	 coin[ncoins]=display.newImage("bigcoin.png",50,50)
      end

      coin[ncoins]:addEventListener(Event.MOUSE_DOWN,dragDown,coin[ncoins])
      coin[ncoins]:addEventListener(Event.MOUSE_MOVE,dragMove,coin[ncoins])
      coin[ncoins]:addEventListener(Event.MOUSE_UP  ,dragUp,  coin[ncoins])
   end
   
end

--######################################################################

function newcrate(self,event)

   if (self:hitTestPoint(event.x,event.y)) then
      
      killmenu()

      ncrate=ncrate+1
      crate[ncrate]=display.newBorderRect(30,30, 255,255,0, 1, 120,120,0, 4)

      crate[ncrate]:setPosition(100,100)
      crate[ncrate].width=30
      crate[ncrate].height=30
      crate[ncrate].isCrate=true

      addBody(crate[ncrate],"dynamic",{friction=0.1,bounce=0})

      crate[ncrate]:addEventListener(Event.MOUSE_DOWN,dragDown,crate[ncrate])
      crate[ncrate]:addEventListener(Event.MOUSE_MOVE,dragMove,crate[ncrate])
      crate[ncrate]:addEventListener(Event.MOUSE_UP  ,dragUp,  crate[ncrate])

   end
end

--######################################################################

function newGcrate(self,event)

   if (self:hitTestPoint(event.x,event.y)) then
      
      killmenu()

      ncrate=ncrate+1
      crate[ncrate]=display.newBorderRect(30,30, 2,2,2, 1, 1,1,1, 4)
      crate[ncrate]:setColorTransform(0,120,0)

      crate[ncrate]:setPosition(100,100)
      crate[ncrate].width=30
      crate[ncrate].height=30
      crate[ncrate].isCrate=true

      addBody(crate[ncrate],"dynamic",{friction=0.1,bounce=0})

      crate[ncrate]:addEventListener(Event.MOUSE_DOWN,dragDown,crate[ncrate])
      crate[ncrate]:addEventListener(Event.MOUSE_MOVE,dragMove,crate[ncrate])
      crate[ncrate]:addEventListener(Event.MOUSE_UP  ,dragUp,  crate[ncrate])

      crate[ncrate].isgreen="yes"

   end
end

--######################################################################

function newBcrate(self,event)

   if (self:hitTestPoint(event.x,event.y)) then
      
      killmenu()

      ncrate=ncrate+1
      crate[ncrate]=display.newBorderRect(30,30, 2,2,2, 1, 1,1,1, 4)
      crate[ncrate]:setColorTransform(0,0,120)

      crate[ncrate]:setPosition(100,100)
      crate[ncrate].width=30
      crate[ncrate].height=30
      crate[ncrate].isCrate=true

      addBody(crate[ncrate],"dynamic",{friction=0.1,bounce=0})

      crate[ncrate]:addEventListener(Event.MOUSE_DOWN,dragDown,crate[ncrate])
      crate[ncrate]:addEventListener(Event.MOUSE_MOVE,dragMove,crate[ncrate])
      crate[ncrate]:addEventListener(Event.MOUSE_UP  ,dragUp,  crate[ncrate])

      crate[ncrate].isblue="yes"

   end
end


--######################################################################

function newHbaddy(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()

      nbaddy=nbaddy+1
      if graphics=="space" then
	 baddy[nbaddy]=display.newImage("baddy.png",100,100)
	 baddy[nbaddy]:setScale(0.5)
      elseif graphics=="xmas" then
	 baddy[nbaddy]=display.newImage("baddy_xmas.png",100,100)
      else
	 baddy[nbaddy]=display.newImage("baddy8bit.png",100,100)
      end

      baddy[nbaddy].dir=1
      baddy[nbaddy].start=50
      baddy[nbaddy].ends=150
      baddy[nbaddy].speed=2
      baddy[nbaddy].isbaddy=true
      baddy[nbaddy].falling=false

      baddy[nbaddy].core=display.newRect(100,20, 255,0,0, 0.5, 255,255,255, 2)
      baddy[nbaddy].core:setPosition(100,100)

      baddy[nbaddy].core:addEventListener(Event.MOUSE_DOWN,movingDOWN,baddy[nbaddy].core)
      baddy[nbaddy].core:addEventListener(Event.MOUSE_MOVE,movingMOVE,baddy[nbaddy].core)
      baddy[nbaddy].core:addEventListener(Event.MOUSE_UP  ,movingUP  ,baddy[nbaddy].core)

      baddy[nbaddy].core.parent=baddy[nbaddy]   -- associate core with baddy
      baddy[nbaddy].core.width=100
      baddy[nbaddy].core.height=20
   end
end

--######################################################################

function newVbaddy(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()

      nbaddy=nbaddy+1

      if graphics=="space" then
	 baddy[nbaddy]=display.newImage("baddy2.png",100,100)
	 baddy[nbaddy]:setScale(0.5)
      elseif graphics=="xmas" then
	 baddy[nbaddy]=display.newImage("baddy2_xmas.png",100,100)
      else
	 baddy[nbaddy]=display.newImage("baddy28bit.png",100,100)
      end

      baddy[nbaddy].dir=2
      baddy[nbaddy].start=50
      baddy[nbaddy].ends=150
      baddy[nbaddy].speed=2
      baddy[nbaddy].isbaddy=true
      baddy[nbaddy].falling=false

      baddy[nbaddy].core=display.newRect(20,100, 0,255,0, 0.5, 255,255,255, 2)
      baddy[nbaddy].core:setPosition(100,100)

      baddy[nbaddy].core:addEventListener(Event.MOUSE_DOWN,movingDOWN,baddy[nbaddy].core)
      baddy[nbaddy].core:addEventListener(Event.MOUSE_MOVE,movingMOVE,baddy[nbaddy].core)
      baddy[nbaddy].core:addEventListener(Event.MOUSE_UP  ,movingUP  ,baddy[nbaddy].core)

      baddy[nbaddy].core.parent=baddy[nbaddy]   -- associate with baddy
      baddy[nbaddy].core.width=20
      baddy[nbaddy].core.height=100
   end
end

--######################################################################

function newSbaddy(self,event)

   if (self:hitTestPoint(event.x,event.y)) then

      killmenu()

      nbaddy=nbaddy+1
      if graphics=="space" then
	 baddy[nbaddy]=display.newImage("baddy3.png",150,150)
      elseif graphics=="xmas" then
	 baddy[nbaddy]=display.newImage("baddy3_xmas.png",150,150)
	 baddy[nbaddy]:setScale(2,2)
      else
	 baddy[nbaddy]=display.newImage("baddy38bit.png",150,150)
	 baddy[nbaddy]:setScale(2,2)
      end


      baddy[nbaddy].dir=0
      baddy[nbaddy].start=0
      baddy[nbaddy].ends=0
      baddy[nbaddy].speed=0
      baddy[nbaddy].isbaddy=true
      baddy[nbaddy].falling=false

      baddy[nbaddy]:addEventListener(Event.MOUSE_DOWN,dragDown,baddy[nbaddy])
      baddy[nbaddy]:addEventListener(Event.MOUSE_MOVE,dragMove,baddy[nbaddy])
      baddy[nbaddy]:addEventListener(Event.MOUSE_UP  ,dragUp  ,baddy[nbaddy])

   end
end

--######################################################################

function newlevel()

   local path,fh

   totlevels=totlevels+1
   upto=totlevels
   level=totlevels
   
   path="|D|level"..level..".txt"
   fh=io.open(path,"w")

   fh:write("100 100\n")
   fh:write("ncoins\n",1,"\n")
   fh:write("50 50\n")
   
   fh:write("nbaddy\n",0,"\n")
   fh:write("nplatform\n",1,"\n")
   fh:write("150 250 100 10 0\n")
   fh:write("ego\n")
   fh:write("150 220\n")
   fh:write("ncrate\n0\n")
   
   fh:close()
   
   path="|D|colours"..level..".txt"
   fh=io.open(path,"w")
   fh:write("0 0 255 255\n")
   fh:close()
   
   path="|D|config.txt"
   fh=io.open(path,"w")
   fh:write(totlevels," ",totlevels)
   fh:close()
   
   print ("level created")
   
   trans=0
--   ncoll=0
   killlevel()
end
