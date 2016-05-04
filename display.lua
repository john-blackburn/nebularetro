display={}

-- eg display.newRect(100,20, 255,255,0): solid yellow rectangle
-- eg display.newRect(100,20, 255,255,0, 0.5): yellow rectangle, 50% trans
-- eg display.newRect(100,20, 255,255,0, 1.0, 255,255,255, 10):
-- solid yellow rectangle with white border 10 pixels wide

function rgb(r,g,b)
   return math.floor(r)*65536+math.floor(g)*256+math.floor(b)
end

display.newRoundRect=function(width,height,crad,r,g,b,alpha,rs,gs,bs,swidth)

local block=Shape.new()
local color=rgb(r,g,b)

if (alpha) then
   block:setFillStyle(Shape.SOLID,color,alpha)
else
   block:setFillStyle(Shape.SOLID,color)
end

if (rs) then
   local scolor=rgb(rs,gs,bs)
   block:setLineStyle(swidth, scolor, 1)
end

block:beginPath()
block:moveTo(-width/2+crad,-height/2)
block:lineTo( width/2-crad,-height/2)

block:lineTo( width/2,-height/2+crad)
block:lineTo( width/2, height/2-crad)

block:lineTo( width/2-crad, height/2)
block:lineTo(-width/2+crad, height/2)

block:lineTo(-width/2, height/2-crad)
block:lineTo(-width/2,-height/2+crad)

block:closePath()
block:endPath()

stage:addChild(block)

return block
end

display.newArrow=function(width,height,dir,r,g,b,alpha,rs,gs,bs,swidth)

local block=Shape.new()
local color=rgb(r,g,b)

if (alpha) then
   block:setFillStyle(Shape.SOLID,color,alpha)
else
   block:setFillStyle(Shape.SOLID,color)
--   block:setFillStyle(Shape.TEXTURE,Texture.new("sign1.png"))

end

if (rs) then
   local scolor=rgb(rs,gs,bs)
   block:setLineStyle(swidth, scolor, 1)
end

block:beginPath()

if dir=="left" then
  block:moveTo(-width/2+10,-height/2)
  block:lineTo(width/2,-height/2)
  block:lineTo(width/2,height/2)
  block:lineTo(-width/2+10,height/2)
  block:lineTo(-width/2,0)
else
  block:moveTo(-width/2,-height/2)
  block:lineTo(width/2-10,-height/2)
  block:lineTo(width/2,0)
  block:lineTo(width/2-10,height/2)
  block:lineTo(-width/2,height/2)
end

block:closePath()
block:endPath()

stage:addChild(block)

return block
end

display.newRect=function(width,height,r,g,b,alpha,rs,gs,bs,swidth)

local block=Shape.new()
local color=rgb(r,g,b)

if (alpha) then
   block:setFillStyle(Shape.SOLID,color,alpha)
else
   block:setFillStyle(Shape.SOLID,color)
end

if (rs) then
   local scolor=rgb(rs,gs,bs)
   block:setLineStyle(swidth, scolor, 1)
end

block:beginPath()
block:moveTo(-width/2,-height/2)
block:lineTo(width/2,-height/2)
block:lineTo(width/2,height/2)
block:lineTo(-width/2,height/2)
block:closePath()
block:endPath()

stage:addChild(block)

return block
end

display.newBorderRect=function(width,height,r,g,b,alpha,rs,gs,bs,swidth)

local border_width=2
local block=Shape.new()
local color=rgb(r,g,b)

if (alpha) then
   block:setFillStyle(Shape.SOLID,color,alpha)
else
   block:setFillStyle(Shape.SOLID,color)
end

if (rs) then
   local scolor=rgb(rs,gs,bs)
   block:setLineStyle(swidth, scolor, 1)
end

block:beginPath()
block:moveTo(-width/2+swidth/2,-height/2+swidth/2)
block:lineTo(width/2-swidth/2,-height/2+swidth/2)
block:lineTo(width/2-swidth/2,height/2-swidth/2)
block:lineTo(-width/2+swidth/2,height/2-swidth/2)
block:closePath()
block:endPath()

block:setFillStyle(Shape.NONE)
block:setLineStyle(border_width,0)

block:beginPath()
block:moveTo(-width/2,-height/2)
block:lineTo( width/2,-height/2)
block:lineTo( width/2, height/2)
block:lineTo(-width/2, height/2)
block:closePath()
block:endPath()

stage:addChild(block)

return block
end


display.newStripeRect=function(width,height,r,g,b,r2,g2,b2)

   local border_width=2
   local block=Shape.new()
   local color=rgb(r,g,b)
   local color2=rgb(r2,g2,b2)


   local l=10
   local n=math.floor(width/l)
   local col=color

   local delta=width-n*l

   for i=1,n do

      block:beginPath()
      block:setFillStyle(Shape.SOLID,col)
      block:moveTo(-width/2+(i-1)*l,-height/2)
      block:lineTo(-width/2+i*l,    -height/2)
      block:lineTo(-width/2+i*l,     height/2)
      block:lineTo(-width/2+(i-1)*l, height/2)
      block:closePath()
      block:endPath()

      if col==color then
	 col=color2
      else
	 col=color
      end
   end

   if delta>0 then
      block:beginPath()
      block:setFillStyle(Shape.SOLID,col)
      block:moveTo(-width/2+n*l,-height/2)
      block:lineTo( width/2,    -height/2)
      block:lineTo( width/2,     height/2)
      block:lineTo(-width/2+n*l, height/2)
      block:closePath()
      block:endPath()
   end

   block:beginPath()
   block:setLineStyle(border_width,0)
   block:setFillStyle(Shape.NONE)

   block:moveTo(-width/2,-height/2)
   block:lineTo( width/2,-height/2)
   block:lineTo( width/2, height/2)
   block:lineTo(-width/2, height/2)

   block:closePath()
   block:endPath()

   stage:addChild(block)
   return block
end

display.newGradRect=function(width,height,r,g,b)

   local block=Shape.new()

   local h,s,v=rgb2hsv(r,g,b)
   local l=10
   local border_width=2
   local n=math.floor(width/l)

   local delta=width-n*l

   for i=1,n do

      v=i/n*70+30
--      s=i/n

      local r2,g2,b2=hsv2rgb(h,s,v)
      local color=rgb(r2,g2,b2)

      block:beginPath()
      block:setFillStyle(Shape.SOLID,color)
      block:moveTo(-width/2+(i-1)*l,-height/2)
      block:lineTo(-width/2+i*l,    -height/2)
      block:lineTo(-width/2+i*l,     height/2)
      block:lineTo(-width/2+(i-1)*l, height/2)
      block:closePath()
      block:endPath()
   end

   if delta>0 then

      local r2,g2,b2=hsv2rgb(h,s,100)
--      local r2,g2,b2=hsv2rgb(h,1,v)

      local color=rgb(r2,g2,b2)

      block:beginPath()
      block:setFillStyle(Shape.SOLID,color)
      block:moveTo(-width/2+n*l,-height/2)
      block:lineTo( width/2,    -height/2)
      block:lineTo( width/2,     height/2)
      block:lineTo(-width/2+n*l, height/2)
      block:closePath()
      block:endPath()
   end

   block:beginPath()
   block:setLineStyle(border_width,0)
   block:setFillStyle(Shape.NONE)

   block:moveTo(-width/2,-height/2)
   block:lineTo( width/2,-height/2)
   block:lineTo( width/2, height/2)
   block:lineTo(-width/2, height/2)

   block:closePath()
   block:endPath()

   stage:addChild(block)
   return block
end

display.newImage=function(name,x,y,filtering)
--   local image=Bitmap.new(Texture.new(name,filtering))
   local image=Bitmap.new(Texture.new(name,true))

   if x then
     image:setPosition(x,y)
   end
   
   stage:addChild(image)
   image:setAnchorPoint(0.5,0.5)
   
   return image
end

return display
