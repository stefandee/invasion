program get_a_screen;

uses images,graphics;
var     f :file;
        b:byte absolute $a000:0;
        p :pointer;
        xl,yl:word;
        i,j : integer;

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

begin

vga256;
{celload('wos12.cel');}
{corection:=0;}
pcxread('tiles.pcx',0,3412);

assign(f,'inva.pal');
rewrite(f,1);
blockwrite(f,workpal,768);
close(f);

{for i:=0 to 199 do for j:=0 to 319 do
    if getpixel(j,i,vga)>100 then putpixel(j,i,0,vga);}

{assign(f,'planet.spr');
rewrite(f,1);
xl:=320;
yl:=200;
blockwrite(f,xl,2);
blockwrite(f,yl,2);
blockwrite(f,b,64000);
close(f);
readln;
}

donevga256;
end.


