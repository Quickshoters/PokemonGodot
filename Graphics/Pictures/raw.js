function readfile(f){
 var fso=new ActiveXObject("Scripting.FileSystemObject")
 o=fso.GetFile(f)
 if(o){
  var sz=o.Size
  var o=fso.OpenTextFile(f)
  var ret=o.read(sz)
  o.Close()
 }
 return ret
}

eval(readfile("c:\\utility.js"))

function saveppm(image,fn){
 var tf=fso.CreateTextFile(fn,2)
 width=image[0].length
 height=image.length
 tf.write("P6\n"+width+" "+height+"\n255\n")
 for(var y=0;y<height;y++){
 for(var x=0;x<width;x++){
  if(!image[y][x]){
   WScript.Echo([y,x])
  }
  WriteHexBytes(tf,image[y][x])
 } 
 } 
 tf.close()
}
function loadimage(filename){
var img=new BufferedTextFile(filename)
var image=[]
for(var y=0;y<160;y++){
 image[y]=[]
 for(var x=0;x<240;x++){
  image[y][x]=img.readBytes(3)
 }
}
img.close()
return image
}
function newimage(width,height){
 var windowskin=[]
 for(var y=0;y<height;y++){
  windowskin[y]=[]
  for(var x=0;x<width;x++){
   windowskin[y][x]=[248,248,248]
  }
 }
 return windowskin
}

function fillrect(image,dstx,dsty,width,height,color){
 for(var y=0;y<height;y++){
 for(var x=0;x<width;x++){
  image[dsty+y][dstx+x]=color
 } 
 }
}

function stretchrect(dstimage,dstx,dsty,srcimage,srcx,srcy,width,height){
 for(var y=0;y<height;y++){
 for(var x=0;x<width;x++){
  color=srcimage[srcy+y][srcx+x]
  if(color[0]==136&&color[1]==144&&color[2]==248)color=[255,0,255]
  dstimage[dsty+(y*2)][dstx+(x*2)]=color
  dstimage[dsty+(y*2)+1][dstx+(x*2)]=color
  dstimage[dsty+(y*2)][dstx+(x*2)+1]=color
  dstimage[dsty+(y*2)+1][dstx+(x*2)+1]=color
 } 
 }
}

function loadwindowskin(infile,outfile){
image=loadimage(infile)
windowskin=newimage(192,128)
fillrect(windowskin,128,64,32,32,[255,0,255])
fillrect(windowskin,160,64,32,32,[255,0,255])
fillrect(windowskin,144,16,32,32,[255,0,255])
stretchrect(windowskin,128,0,image,8,32,8,8)
stretchrect(windowskin,128,48,image,8,152,8,8)
stretchrect(windowskin,176,0,image,224,32,8,8)
stretchrect(windowskin,176,48,image,224,152,8,8)
stretchrect(windowskin,144,0,image,16,32,16,8)
stretchrect(windowskin,144,48,image,16,152,16,8)
stretchrect(windowskin,128,16,image,8,40,8,16)
stretchrect(windowskin,176,16,image,224,40,8,16)
saveppm(windowskin,outfile)
}
for(var iv=11;iv<=28;iv++){
loadwindowskin("skin"+iv+".raw","skin"+iv+".ppm")
}