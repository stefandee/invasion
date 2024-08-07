uses graphics,dos,crt;

var i,j : integer;
    x,y : word;
    f   : file;
    xxc,yyc:word;
    xc,yc: word;
    bs:byte;
    b:byte;
    p:char;
    sprfname,pcxfname:string;
    vscr : pointer;
    sv,ov:word;
    regs:registers;
    sc : byte absolute 0:$417;
    manv:string;
    ser : byte;

procedure celload(fname:string);
var f:file;
    b:byte absolute $a000:0;
begin
assign(f,fname);
reset(f,1);
seek(f,32);
blockread(f,workpal,768);
setpal;
blockread(f,b,64000);
close(f);
end;

procedure Pcxread(fname:string);

var pcx : pointer;
    i,j : integer;
    f   : file;
    pcxseg,pcxofs:word;
    len:longint;

begin

assign(f,fname);
reset(f,1);
len:=filesize(f);
seek(f,len-768);
blockread(f,workpal,768);

for i:=0 to 255 do for j:=1 to 3 do workpal[i,j]:=workpal[i,j] shr 2;
waitretrace;
setpal;

seek(f,128);
getmem(pcx,40000);
blockread(f,pcx^,len-128);
close(f);
pcxseg:=seg(pcx^);
pcxofs:=ofs(pcx^);

{begin decoding}
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

mov dx,pcxseg
mov ds,dx
mov si,pcxofs
mov dx,vga
mov es,dx
mov dx,0
mov di,dx
mov bh,$3f
mov ch,0
cld
cli
@decode:
         mov ax,di
{         sub ax,ov}
         cmp ax,63999
         jae @finish

         lodsw;

         mov bl,al
         and bl,$c0
         cmp bl,$c0
         jne @notcode

         and al,$3f
         mov cl,al
         shr cx,1
         mov al,ah
         rep stosw
         jnc @decode
         stosb
         jmp @decode
@notcode:
         stosb
         dec si
         jmp @decode
@finish:
    pop es
   pop ds
   pop bp
   pop di
   pop si
   pop dx
   pop cx
   pop bx
   pop ax
sti
end;
freemem(pcx,40000);
end;

procedure Rectangle(xi,yi,xf,yf:integer;color:byte);
begin
hlin(xi,xf,yi,color,vga);
hlin(xi,xf,yf,color,vga);
line(xi,yi,xi,yf,color,vga);
line(xf,yi,xf,yf,color,vga);
end;

begin

vga256;
Hlin:=Nhlin;
getmem(vscr,64000);
sv:=seg(vscr^);
ov:=ofs(vscr^);
pcxfname:='tiles';
sprfname:='tile';
pcxread(pcxfname+'.pcx');
Move (mem[VGA:0],vscr^,64000);


x:=50;y:=50;xc:=6;yc:=6;
Move (vscr^,mem[VGA:0],64000);
rectangle(x,y,x+xc,yc+y,255);
ser:=1;

repeat
if keypressed then p:=readkey
              else p:=#0;
bs:=sc;
case (bs and 32) of
0:case p of
'q' : begin
     dec(y,1);
     if y<0 then y:=0;
     Move (Vscr^,mem [VGA:0],64000);
     rectangle(x,y,x+xc,yc+y,255);
     end;
'z' : begin
     inc(y,1);
     if y+yc>199 then y:=199-yc;
     Move (Vscr^,mem [VGA:0],64000);
     rectangle(x,y,x+xc,yc+y,255);
     end;
'o' : begin
     dec(x,1);
     if x<0 then x:=0;
     Move (Vscr^,mem [VGA:0],64000);
     rectangle(x,y,x+xc,yc+y,255);
     end;
'p' : begin
     inc(x,1);
     if x+xc>319 then x:=319-xc;
     Move (Vscr^,mem [VGA:0],64000);
     rectangle(x,y,x+xc,yc+y,255);
     end;
' ' : begin
     str(ser,manv);
     assign(f,sprfname+manv+'.spr');
     rewrite(f,1);
     xxc:=xc-1;
     yyc:=yc-1;
     blockwrite(f,xxc,2);
     blockwrite(f,yyc,2);
     for i:=y+1 to y+yc-1 do
         for j:=x+1 to x+xc-1 do
             begin
             b:=getpixel(j,i,vga);
             blockwrite(f,b,1);
             end;
     close(f);
     inc(ser);
     end;
end;
else begin
    case p of
     'q' : dec(yc,1);
     'z' : inc(yc,1);
     'o' : dec(xc,1);
     'p' : inc(xc,1);
     end;
     Move (Vscr^,mem [VGA:0],64000);
     rectangle(x,y,x+xc,yc+y,255);
     end;
end;
until p=#27;
DOnevga256;
freemem(vscr,64000);
end.

