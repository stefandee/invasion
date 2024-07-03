unit graphics;
{$G+}
{$R-}

interface

uses Dos,Crt;

Type Vrt     = Array [1..64000] of byte;  { The size of the virtual screen }
     VirtPtr = ^Vrt;
     Tspr    = record
             xl,yl:word;
             pspr:pointer
             end;
     pp      = record
             ofs,seg :word
             end;
     bytes   = array[1..11,1..8] of byte;
     mbytes  = array[1..7,1..7] of byte;


     point   = record
             x,y:integer;
             end;
     triangle= record
             a,b,c : point;
             d     : real;
             col   : byte;
             end;
     paltype = array[0..255,1..3] of byte;
     lineproc = procedure(x1,x2,y:integer;color:byte;where:word);

Const VGA=$A000;
      crtc_addr=$3d4;
      NormalPut =  0  ;      {MOV}
      CopyPut   =  1  ;      {MOV}
      XORPut    =  3  ;      {XOR}
      OrPut     =  2  ;      {OR }
      AndPut    =  1  ;      {AND}
      NotPut    =  4  ;      {NOT}
      GamePut   =  5  ;      {Special put : designed by Karg - ex Phane}
      SpecPut   =  6  ;
      Fond      =  0  ;      {like in cartoons stuff, the put above needs
                              a backgnd color}

      SmallFnt  =  1  ;
      MicroFnt  =  2  ;

      leftclip   : integer = 10;
      rightclip  : integer = 310;
      topclip    : integer = 20;
      botclip    : integer = 180;

      LeftAllign   = 0;
      RightAllign  = 1;
      CenterAllign = 2;

Var workpal,pal  : paltype;
    Virscr       : VirtPtr;                      { Our first Virtual screen }
    Vaddr        : word;                        { The segment of our virtual screen}
    Spr          : array [1..255] of tspr;
    Small        : array[' '..'^'] of bytes;
    Micro        : array[' '..'^'] of mbytes;
    Poly         : array[0..199,1..2] of integer;
    Hlin         : LineProc;
    Step         : byte;
    Allign       : byte;

procedure Vga256;
procedure DoneVga256;
procedure InitVScreen;
procedure DoneVScreen;
procedure InitUnChain;

procedure Putpixel(x,y:word;color:byte;where:word);
function  Getpixel(x,y:word;where:word):byte;
procedure Line(x1,y1,x2,y2:integer;color:byte;where:word);
procedure NHlin(x1,x2,y:integer;color:byte;where:word);
procedure Glare(x1,x2,y:integer;color:byte;where:word);
procedure Rectangle(xi,yi,xf,yf:integer;color:byte;where:word);
procedure Bar(xi,yi,xf,yf:integer;color:byte;where:word);

procedure Setpal;
procedure Loadpal(numef:string);
procedure SetRGB(index,r,g,b:byte);
procedure GetRGB(index : byte;var r,g,b : byte);
procedure FadeIn;
procedure FadeOut(speed:byte);
procedure RotatePal;
procedure WaitRetrace;

procedure Flip;
procedure Cls (Color : Byte; Where:Word);

{sprite procedures...}
procedure Loadspr(nume:string;nr:byte);
procedure Putspr(nr:byte;x1,y1:integer;mode:byte;where:word);
procedure ReplaceSpr(fname:string;nr:byte;readpos : longint);
procedure GetImage(nr:byte;x,y,xll,yll : word;where : word);
procedure DoneSpr(nr:byte);

procedure Outtext(x,y:integer;s:string;fnt:byte;color : byte;where:word);
procedure Outint(x,y:integer;v:longint;fnt:byte;color : byte;where:word);


implementation

procedure Vga256;
begin
asm
   mov ax,$0013
   int $10
end
end;

Procedure DoneVga256;  { This procedure returns you to text mode.  }
begin
  asm
     mov        ax,0003h
     int        10h
  end;
end;

procedure InitVScreen;
begin
Getmem(virscr,64000);
Vaddr := seg (virscr^);
end;

procedure DoneVScreen;
begin
FreeMem(virscr,64000);
end;

procedure InitUnChain;assembler;
  asm
    mov     ax,0013h
    int     10h                     { Enter mode 13 }
    cli
    mov     dx,3c4h
    mov     ax,604h                 { Enter unchained mode }
    out     dx,ax
    mov     ax,0F02h                { All planes}
    out     dx,ax

    mov     dx,3D4h
    mov     ax,14h                  { Disable dword mode}
    out     dx,ax
    mov     ax,0E317h               { Enable byte mode.}
    out     dx,ax
    mov     al,9
    out     dx,al
    inc     dx
    in      al,dx
    and     al,0E0h                 { Duplicate each scan 8 times.}
    add     al,7
    out     dx,al
    sti
  end;

procedure Putpixel;
begin
Mem [Where:X+Y shl 8 +y shl 6]:=color;
end;

function GetPixel;
begin
GetPixel:=Mem[Where:X+Y*320];
end;

procedure Line;
var i, deltax, deltay, numpixels,
    d, dinc1, dinc2,
    x, xinc1, xinc2,
    y, yinc1, yinc2 : integer;
    screen : word;
    screeninc1, screeninc2 : integer;

begin

  if x1<0 then x1:=0;
  if x2<0 then x2:=0;
  if y1<0 then y1:=0;
  if y2<0 then y2:=0;
  if x1>319 then x1:=319;
  if x2>319 then x2:=319;
  if y1>199 then y1:=199;
  if y2>199 then y2:=199;


  { Calculate deltax and deltay for initialisation }
  deltax := abs(x2 - x1);
  deltay := abs(y2 - y1);

  { Initialize all vars based on which is the independent variable }
  if deltax >= deltay then
    begin

      { x is independent variable }
      numpixels := deltax + 1;
      d := (2 * deltay) - deltax;
      dinc1 := deltay Shl 1;
      dinc2 := (deltay - deltax) shl 1;
      xinc1 := 1;
      xinc2 := 1;
      yinc1 := 0;
      yinc2 := 1;
    end
  else
    begin

      { y is independent variable }
      numpixels := deltay + 1;
      d := (2 * deltax) - deltay;
      dinc1 := deltax Shl 1;
      dinc2 := (deltax - deltay) shl 1;
      xinc1 := 0;
      xinc2 := 1;
      yinc1 := 1;
      yinc2 := 1;
    end;

  { Make sure x and y move in the right directions }
  if x1 > x2 then
    begin
      xinc1 := - xinc1;
      xinc2 := - xinc2;
    end;
  if y1 > y2 then
    begin
      yinc1 := - yinc1;
      yinc2 := - yinc2;
    end;

  { Start drawing at <x1, y1> }
  screen := word(y1) * 320 + x1;
  screeninc1 := yinc1 * 320 + xinc1;
  screeninc2 := yinc2 * 320 + xinc2;

  { Draw the pixels }
  asm

    { Use as many registers as are available }
    push where
    pop es
    mov di, screen
    mov dx, d
    mov al, color
    mov cx, numpixels
    mov bx, dinc1

    @bres1:

    { Draw the current pixel and compare the decision variable to 0 }
    mov es:[di], al
    cmp dx, 0
    jnl @bres2

    { D < 0 }
    add dx, bx { bx = dinc1 }
    add di, screeninc1
    jmp @bres3

    @bres2:

    { D >= 0 }
    add dx, dinc2
    add di, screeninc2

    @bres3:

    loop @bres1
  end;

end;

procedure NHlin;
var adr:word;
    xb,len:word;

begin

if x1=x2 then exit;
if x1<0 then x1:=0;
if x2<0 then x2:=0;
if x2>319 then x2:=319;
if x1>319 then x1:=319;
if y>199 then exit;
if y<0 then exit;

if x1>x2 then begin
             xb:=x2;
             len:=abs(x1-x2);
             end
        else begin
             xb:=x1;
             len:=abs(x2-x1);
             end;
adr:=word(xb+y shl 8 + y shl 6);

asm
mov dx,es
mov ax,where
mov es,ax
mov di,adr
mov cx,len
shr cx,1
mov ah,color
mov al,color
rep stosw
jnc @finish
stosb
@finish:mov es,dx
end;
end;

procedure Glare;
var adr:word;
    xb,len:word;

begin
if x1<0 then x1:=0;
if x2<0 then x2:=0;
if x2>319 then x2:=319;
if x1>319 then x1:=319;
if y>199 then exit;
if y<0 then exit;

if x1>x2 then begin
             xb:=x2;
             len:=abs(x1-x2);
             end
        else begin
             xb:=x1;
             len:=abs(x2-x1);
             end;
adr:=word(xb+y shl 8 + y shl 6);

asm
push es
push ds

mov ax,where
mov es,ax
mov di,adr
mov ds,ax
mov si,adr
mov cx,len
inc cx
mov ah,color
mov dh,color
cld
@rep1 :
      lodsb
      cmp al,0
      je @rep2
      shr al,1
      shr ah,1
      add al,ah
      mov ah,dh
      stosb
      loop @rep1
      jmp @finish
@rep2:
      mov al,ah
      stosb
      loop @rep1
@finish :
        pop ds
        pop es
end;
end;

procedure Rectangle;
begin
Hlin(xi,xf,yi,color,where);
Hlin(xi,xf,yf,color,where);
Line(xi,yi,xi,yf,color,where);
Line(xf,yi,xf,yf,color,where);
end;


procedure Bar;
var i:integer;
begin
for i:=yi to yf do hlin(xi,xf,i,color,where);
end;


procedure LoadPal;

var
    result:word;
    fs:file;
begin

   assign(fs,numef);
   reset(fs,1);
   blockread(fs,workpal,768,result);
   close(fs);
   move(workpal,pal,768);
end;

procedure Setpal;assembler;
asm
   
   push ds
   mov ax,seg workpal
   mov ds,ax
   mov si,offset workpal
   call WaitRetrace

   mov dx,3c8h
   mov al,0
   out dx,al
   inc dx
   mov cx,384
   rep outsb
   call WaitRetrace
   mov dx,3c8h
   mov al,128
   out dx,al
   inc dx
   mov cx,384
   rep outsb

   pop ds
end;

procedure SetRGB;
begin

port[$3c8]:=index;
port[$3c9]:=r;
port[$3c9]:=g;
port[$3c9]:=b;

end;

Procedure GetRGB;
Var
   RR,GR,BR : Byte;
Begin
   Asm
      mov   dx, 3c7h
      mov   al, [Index]
      out   dx, al
      inc   dx
      inc   dx
      in    al, dx
      mov   [RR],al
      in    al, dx
      mov   [GR],al
      in    al, dx
      mov   [BR],al
   End;
   R := RR;
   G := GR;
   B := BR;
End;


procedure WaitRetrace;assembler;
label l1,l2;
asm
    mov dx,3DAh
l1:
    in al,dx
    and al,08h
    jnz l1
l2:
    in al,dx
    and al,08h
    jz  l2
end;

Procedure Cls;
BEGIN
  asm
  mov ax,where
  mov es,ax
  mov al,color
  mov ah,al
  mov si,0
  mov di,0
  mov cx,32000
  rep stosw
  end;
{Fillchar (Mem [where:0],64000,color);}
END;

Procedure Flip;
BEGIN
  asm
  push es
  push ds
  mov ax,vaddr
  mov ds,ax
  mov si,0
  mov ax,vga
  mov es,ax
  mov di,0
  mov cx,32000
  cld
  rep movsw
  pop ds
  pop es
  end;
{  Move (Virscr^,mem [VGA:0],64000);}
END;


Procedure Putimage(x,y:integer;xl,yl:word;p:pointer;md:byte;where:word);
var
   s,o,adr,dist : word;
   xli          : word;
begin
s:=seg(p^);
o:=ofs(p^);
if x>319 then exit;
if x+xl<0 then exit;
if x>=0 then begin
            adr:=word(320*y+x);
            dist:=xl;
            end
       else begin
            adr:=word(320*y);
            o:=o+abs(x);
            dist:=xl+x;
            end;

xli:=xl;
if xli=0 then exit;
if yl=0 then exit;
if x+xl>=320 then dist:=word(320-x);
if dist=0 then exit;

case md of
gameput :
   asm
   push ax
   push bx
   push cx
   push dx
   push si
   push di
   push bp
   push ds
   push es
   mov ax,where
   mov es,ax
   mov ax,s
   mov ds,ax
   mov si,o
   mov di,adr
   mov cx,yl
   cld
   @another:
   push di
   push cx
   mov cx,dist
   mov bx,0;
   @again:
   mov al,ds:[si+bx];
   cmp al,fond;
   je @pas;
   mov es:[di+bx],al
   @pas:inc bx
   dec cx
   jnz @again
   pop cx
   pop di
   add di,320
   add si,xli
   dec cx
   jnz @another
   pop es
   pop ds
   pop bp
   pop di
   pop si
   pop dx
   pop cx
   pop bx
   pop ax

   end;

normalput:
asm
   push ax
   push bx
   push cx
   push dx
   push si
   push di
   push bp
   push ds
   push es

   mov ax,where
   mov es,ax
   mov ax,s
   mov ds,ax
   mov si,o
   mov di,adr
   mov cx,yl
   cld

@5:
   push di
   push cx
   mov cx,dist
   shr cx,1
   rep movsw
   jnc @done
   movsb
@done:pop cx
   pop di
   add di,320
   loop @5

   pop es
   pop ds
   pop bp
   pop di
   pop si
   pop dx
   pop cx
   pop bx
   pop ax
end;
copyput:
asm
   push ax
   push bx
   push cx
   push dx
   push si
   push di
   push bp
   push ds
   push es
   mov ax,where
   mov es,ax
   mov ax,s
   mov ds,ax
   mov si,o
   mov di,adr
   mov cx,yl
   cld
@7:
   push di
   push cx
   mov cx,xl
@6:
   lodsb
   cmp al,0
   je @8
   mov es:[di],al
@8:
   inc di
   loop @6
   pop cx
   pop di

   add di,320
   loop @7
   pop es
   pop ds
   pop bp
   pop di
   pop si
   pop dx
   pop cx
   pop bx
   pop ax


end;
specput :
   asm
   push ax
   push bx
   push cx
   push dx
   push si
   push di
   push bp
   push ds
   push es
   mov ax,where
   mov es,ax
   mov ax,s
   mov ds,ax
   mov si,o
   mov di,adr
   mov cx,yl
   cld
   @another:
   push di
   push cx
   mov cx,dist
   mov bx,0;
   @again:
   mov al,ds:[si+bx];
   cmp al,0
   je @pas;
   add al,step;
   mov es:[di+bx],al
   @pas:inc bx
   dec cx
   jnz @again
   pop cx
   pop di
   add di,320
   add si,xli
   dec cx
   jnz @another
   pop es
   pop ds
   pop bp
   pop di
   pop si
   pop dx
   pop cx
   pop bx
   pop ax

   end;


end;{case}
end;{proc}

procedure GetImage(nr:byte;x,y,xll,yll:word;where : word);
label l1;
var
   s,o:word;
   adr:word;

begin
with spr[nr] do
     begin
     xl:=xll;
     yl:=yll;
     getmem(pspr,xl*yl);
     s:=seg(pspr^);
     o:=ofs(pspr^);
     end;

adr:=x+y shl 8 +y shl 6;

asm

   push ds
   push es
   mov ax,s
   mov es,ax
   mov ax,where
   mov ds,ax
   mov si,adr
   mov di,o
   mov cx,yll
l1:
   push si
   push cx
   mov cx,xll
   rep movsb
   pop cx
   pop si

   add si,320
   loop l1
   pop es
   pop ds
end;

end;{proc}



Procedure Loadspr(nume:string;nr:byte);
var
    xxl,yyl    : word;
    fs         : file;

begin
assign(fs,nume);
reset(fs,1);
with spr[nr] do
     begin
         blockread(fs,xxl,2);
         blockread(fs,yyl,2);
         getmem(pspr,xxl*yyl);
         blockread(fs,pspr^,xxl*yyl);
         xl:=xxl;
         yl:=yyl;
     end;
close(fs);
end;

procedure ReplaceSpr;
var
    xxl,yyl    : word;
    fs         : file;

begin
assign(fs,fname);
reset(fs,1);
seek(fs,readpos);
with spr[nr] do
     begin
         blockread(fs,xxl,2);
         blockread(fs,yyl,2);
         blockread(fs,pspr^,xxl*yyl);
         xl:=xxl;
         yl:=yyl;
     end;
close(fs);
end;{usually for full screen sprites}


Procedure Putspr(nr:byte;x1,y1:integer;mode:byte;where:word);
begin
with spr[nr] do
putimage(x1,y1,xl,yl,pspr,mode,where);
end;

procedure DoneSpr(nr:byte);
begin
with spr[nr] do
freemem(pspr,xl*yl);
end;

procedure PutRomFont( x,y : integer;whatfont : byte;
                      whatchar : byte;charheight : byte;color : byte;
                      where : word);
var s,o       : word;
    r         : registers;
    adr       : word;
begin
asm
   push ax
   push bx
   push cx
   push dx
   push si
   push di
   push bp
   push ds
   push es
end;
r.al:=$30;
r.bh:=whatfont;
r.ah:=$11;
intr($10,r);
s:=r.es;o:=r.bp;
o:=o+charheight*whatchar;{A}
adr:=y shl 8+y shl 6+x;
asm
mov ax,s
mov es,ax
mov di,o
mov cx,word(charheight)
mov ax,where
mov ds,ax
mov bl,color
mov si,adr
@1 :
   push cx
   mov cx,8
   mov al,es:[di]
   inc di
@3 :
   xor ah,ah
   shl ax,1
   and ah,1
   jz @2
   mov ds:[si],bl
@2 :
   inc si
   loop @3
   sub si,8
   add si,320
   pop cx
   loop @1

   pop es
   pop ds
   pop bp
   pop di
   pop si
   pop dx
   pop cx
   pop bx
   pop ax

end;

end;

procedure Outtext;
var i,xp:integer;
    p:pointer;

begin
case fnt of
1 : begin
    case Allign of
     LeftAllign  :  xp:=x-8;
     RightAllign :  xp:=x-(8*length(s));
     CenterAllign : xp:=x-(8*length(s)) div 2;
    end;
    for i:=1 to length(s) do
    begin
    p:=ptr(seg(small),ofs(small[upcase(s[i])]));
    putimage(xp+8*i,y,8,11,p,gameput,where);
    end;
    end;
2 : begin
    case Allign of
     LeftAllign  :  xp:=x-7;
     RightAllign :  xp:=x-(7*length(s));
     CenterAllign : xp:=x-(7*length(s)) div 2;
    end;
    for i:=1 to length(s) do
    begin
    p:=ptr(seg(micro),ofs(micro[upcase(s[i])]));
    putimage(xp+i*5,y,7,7,p,gameput,where);
    end;
    end;
3 : for i:=1 to length(s) do PutRomFont(x+(i-1)*8,y,1,byte(s[i]),8,color,where);
4 : for i:=1 to length(s) do PutRomFont(x+(i-1)*8,y,2,byte(s[i]),14,color,where);
5 : for i:=1 to length(s) do PutRomFont(x+(i-1)*8,y,3,byte(s[i]),8,color,where);

end;
end;

procedure Outint;
var s:string;
begin
str(v,s);
outtext(x,y,s,fnt,color,where);
end;

procedure FadeIn;{by one}
 var i : integer;
begin
 for i:=0 to 255 do
     begin
      if workpal[i,1]<pal[i,1] then inc(workpal[i,1]);
      if workpal[i,2]<pal[i,2] then inc(workpal[i,2]);
      if workpal[i,3]<pal[i,3] then inc(workpal[i,3]);
     end;
 setpal;
end;

procedure FadeOut(speed:byte);
var i,j:integer;
begin
for i:=1 to 64 div speed do
    begin
    for j:=0 to 255 do
        begin
        if workpal[j,1]>=speed then dec(workpal[j,1],speed);
        if workpal[j,2]>=speed then dec(workpal[j,2],speed);
        if workpal[j,3]>=speed then dec(workpal[j,3],speed);
        end;
    Setpal;
    delay(15);
    end;
end;

procedure RotatePal;

var r,g,b : byte;
    spal,opal,swpal,owpal : word;

begin
r:=workpal[1,1];g:=workpal[1,2];b:=workpal[1,3];
asm
   push es
   push ds
   mov ax,seg pal
   mov es,ax
   mov di,offset pal
   add di,3
   mov ax,seg workpal
   mov ds,ax
   mov si,offset workpal
   add si,6
   mov cx,762
   cld
   rep movsb
   pop ds
   pop es
end;
pal[255,1]:=r;pal[255,2]:=g;pal[255,3]:=b;
workpal:=pal;
setpal;
end;


begin
end.