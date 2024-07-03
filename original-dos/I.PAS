program I_G;
{$R-}
{$M 32768,0,300000}

uses graphics,crt,fmplay,snddrv,dos;

const Rows = 40;
      Cols = 30;
      MaxStars = 35;
      MaxTime  : byte = 11;
      MaxFame = 10;

type TStar = record
           x : integer;
           speed,y : real;
           color : byte;
           end;
     Fame  = record
           name  : string[3];
           score : longint;
           end;

var psg : array[1..Rows,1..Cols] of byte;
    stars : array[1..MaxStars] of TStar;
    x,xa: integer;
    i,j : integer;
    limxl,limxr,limyd,limyu : integer;
    key : integer;
    time : byte;
    ci,cj,c1,c2 : integer;
    points  : longint;
    nextpoints : longint;
    lives   : integer;
    f       : file;
    fscores : file of Fame;
    hall_of_fame : array[1..MaxFame] of Fame;
    pause   : boolean;
    ingame  : boolean;
    tdelta  : integer;
    nexttdelta : integer;
    fadecnt : integer;
    fact : integer;
    scores : boolean;
    scorescnt : integer;
    highcnt : byte;
    highinsert : boolean;
    highpos : integer;
    highwhere : integer;
    shipspr : byte;
    shipdir : shortint;
    DrawAllowed : boolean;

{$L ship1.obj}
procedure ship1;external;
{$L ship2.obj}
procedure ship2;external;
{$L ship3.obj}
procedure ship3;external;
{$L ship4.obj}
procedure ship4;external;
{$L ship5.obj}
procedure ship5;external;
{$L ship6.obj}
procedure ship6;external;
{$L ship7.obj}
procedure ship7;external;
{$L target.obj}
procedure target;external;
{$L title.obj}
procedure title;external;
{$L tile1.obj}
procedure tile1;external;
{$L tile2.obj}
procedure tile2;external;
{$L tile3.obj}
procedure tile3;external;
{$L tile4.obj}
procedure tile4;external;
{$L tile5.obj}
procedure tile5;external;
{$L tile6.obj}
procedure tile6;external;
{$L tile7.obj}
procedure tile7;external;

var
  Int1CSave : Pointer;
{$F+,S-,W-}
procedure TimerHandler; interrupt;
begin
 { Timer ISR }
 {*** Refer to DDK and DPMI Specs for creating ISR's ***}
 DrawAllowed := true;
end;
{$F-,S+}

procedure GenStar(index : integer);
 var aux : integer;
begin
 with stars[index] do
      begin
       aux:=random(10);
       speed:=2*(aux/10+1);
       x:=random(limxr-limxl)+limxl;
       y:=limyd;
       color:=200+round(speed*10);
      end;
end;

procedure RunStars;
 var i : integer;
begin
 for i:=1 to MaxStars do
     with Stars[i] do
          begin
           y:=y+speed;
           if y>=limyu then GenStar(i);
           putpixel(round(x),round(y),color,vaddr);
          end;
end;

procedure InsertTiles;
 var i,j   : integer;
     xb,yb : integer;
begin
 fact:=(15-maxtime) div 2;
 xb:=random(cols-fact)+fact+1;
 yb:=1+random(6);
 for i:=xb-fact to xb+fact do
     for j:=yb to yb+4 do
         if random(2)=1 then if (i<=cols) and (i>=1) then psg[j,i]:=1;
end;

procedure MovePsg;
 var i,j : integer;
begin
 for i:=Rows downto 2 do
     for j:=1 to Cols do
         begin
          psg[i,j]:=psg[i-1,j];
          psg[i-1,j]:=0;
          if (i=Rows) and (psg[i,j]=1) and (ingame)
             then begin
                   x:=160;xa:=(x-limxl) div 6+1;
                   dec(lives);time:=0;
                   for i:=1 to MaxStars do GenStar(i);
                   for i:=1 to Rows do for j:=1 to Cols do psg[i,j]:=0;
                   InsertTiles;
                  end;
         end;
end;

procedure ShowPsg;
 var i,j   : integer;
     stack : array[1..20,1..2] of integer;
     found : boolean;
     min,max   : integer;

 label done;
begin
 for i:=Rows downto 2 do
     for j:=1 to Cols do
          if i>10
             then begin
                   if (i>=Rows-3) and (psg[i,j]=1)
                      then begin
                            if (j>1) and (j<Cols) then if (psg[i,j-1]=0) and (psg[i,j+1]=0) then psg[i,j]:=2;
                            if (j=1) and (psg[i,j+1]=0) then psg[i,j]:=2;
                            if (j=Cols) and (psg[i,j-1]=0) then psg[i,j]:=2;
                           end;
                   if (psg[i,j]=1) and (i+4<=Rows)
                      then begin
                            if j+4<=cols then max:=4
                                         else max:=cols-j+1;
                            for c1:=4 downto 1 do
                                begin
                                min:=2;
                                if c1=2 then min:=1;
                                for c2:=max downto min do
                                    begin
                                     found:=true;
                                     for ci:=i downto i-c1 do
                                         for cj:=j to j+c2 do
                                             if psg[ci,cj]<>1 then found:=false;
                                     if found=true
                                        then begin
                                              for ci:=i downto i-c1 do
                                                  for cj:=j to j+c2 do
                                                      psg[ci,cj]:=2;
                                              points:=points+(c1*c2)*310;
                                              if output=Blaster then PlaySound(2);
                                              if points>nextpoints
                                                 then begin
                                                       nextpoints:=nextpoints+20000;
                                                       if nexttdelta>100 then nexttdelta:=nexttdelta-20;
                                                       if maxtime>2
                                                          then begin
                                                                dec(maxtime);
                                                                if output=Blaster
                                                                   then begin
                                                                         DoneFm(2);
                                                                         StopMusic;
                                                                         case maxtime of
                                                                          10 : LoadFm('theme#2',2);
                                                                          9 : LoadFm('theme#3',2);
                                                                          8 : LoadFm('theme#4',2);
                                                                          7 : LoadFm('theme#5',2);
                                                                          6 : LoadFm('theme#6',2);
                                                                          5,4,3,2,1 : LoadFm('theme#7',2);
                                                                         end;
                                                                        end;
                                                               end;
                                                      end;
                                              goto done;
                                             end;
                                    end;
                               end;
                           end;

             done  :
                   case psg[i,j] of
                   1 : putspr(3,limxl+(j-1)*6,(i-10)*6,normalput,vaddr);
                   2,3,4,5,6 : begin
                                putspr(psg[i,j]+2,limxl+(j-1)*6,(i-10)*6,normalput,vaddr);
                                inc(psg[i,j]);
                               end;
                   7 : begin
                        putspr(psg[i,j]+2,limxl+(j-1)*6,(i-10)*6,normalput,vaddr);
                        psg[i,j]:=0;
                       end;
                   end;
                  end;

end;

procedure PutTarget;
 var i : integer;
begin
 for i:=Rows downto 11 do
     if (psg[i,xa]=1) and (i<Rows-2)
        then begin
              putspr(2,limxl+(xa-1)*6,(i-10+1)*6,gameput,vaddr);
              break;
             end;
end;

procedure Fired;
 var i : integer;
begin
 for i:=Rows downto 11 do
     if psg[i,xa]=1
        then begin
              if (i+1<=rows) then psg[i+1,xa]:=1;
              break;
             end;
end;

procedure DoDrawings;
 var i : integer;
begin
 Cls(0,vaddr);
 RunStars;
 ShowPsg;
 inc(tdelta);
 if tdelta>=nexttdelta
    then begin
          case maxtime of
          10,11 : for i:=1 to 2 do InsertTiles;
          else InsertTiles;
          end;
          tdelta:=0;
         end;
 inc(time);
 if time>=MaxTime
    then begin
          MovePsg;
          time:=0;
         end;
 PutTarget;
 putspr(shipspr,x-spr[14].xl div 2,limyu+6,gameput,vaddr);
 xa:=(x-limxl) div 6+1;
 outtext(0,0,'SCORE : ',1,0,vaddr);
 outint(64,0,points,1,110,vaddr);
 outtext(238,0,'LIVES : ',1,0,vaddr);
 outint(302,0,lives,1,110,vaddr);
end;

procedure Initialize;
begin
 limxl:=160-(cols*6) div 2-6;limxr:=160+(cols*6) div 2+6;
 limyd:=100-((rows-10)*6) div 2;limyu:=100+((rows-10)*6) div 2-12;
 x:=160;xa:=(x-limxl) div 6+1;time:=0;points:=0;lives:=3;
 for i:=1 to MaxStars do GenStar(i);
 for i:=1 to Rows do for j:=1 to Cols do psg[i,j]:=0;
 tdelta:=0;nextpoints:=20000;nexttdelta:=290;shipspr:=14;
 scores:=false;
 InsertTiles;
end;

procedure NewWOSIntro;
begin
 LoadPal('Wos.pal');
 if output=Blaster then LoadSound('wosintro',1);
 for i:=0 to 255 do
     begin
      pal[i,1]:=workpal[i,1];pal[i,2]:=workpal[i,2];pal[i,3]:=workpal[i,3];
      workpal[i,1]:=0;workpal[i,2]:=0;workpal[i,3]:=0;
     end;
 SetPal;

 LoadSpr('wos.spr',1);
 PutSpr(1,0,0,normalput,vaddr);
 Flip;
 fadecnt:=0;
 repeat
  if fadecnt<63
     then begin
           inc(fadecnt);
           Fadein;
          end;
  if fadecnt=40 then if output=Blaster then PlaySound(1);
  key:=port[$60];
  asm
   mov ax,$0c02
   int $21
  end;
 until (key=1) or (key=28) or (key=57);
 Fadeout(3);
 DoneSpr(1);
 FreeSound(1);
end;

procedure Detect;
 var aux : string;
     b   : byte;
begin
 aux:=getenv('BLASTER');
 if aux<>''
    then begin
          base:=(byte(aux[3])-48)*16+512;
          output:=BLASTER;
          InternalSet;
          writeln('Blaster environment found = ',aux);
          b:=InstallDriver;
          writeln('Installing SBFMDRV,from my original SB package...',b);
          if b<>0 then halt;
          ResetDriver;
          SetStatusByte;
	  LoadSound('laser',3);LoadSound('explode',2);
          LoadFM('mainsng',1);
         end
    else begin
	  writeln('No SB environment string found.No sound allowed.');
	  output:=None;
         end;
end;

function CheckHighs : boolean;
 var i,j : integer;
begin
 CheckHighs:=false;
 for i:=1 to 10 do
      if Hall_of_Fame[i].score<=points
         then begin
               for j:=10 downto i do Hall_of_Fame[j]:=Hall_of_Fame[j-1];
               Hall_of_Fame[i].score:=points;
               Hall_of_Fame[i].name:='???';
               highpos:=1;
               highcnt:=byte('?');
               CheckHighs:=true;
               highwhere:=i;
               break;
              end;
end;


BEGIN

 Detect;
 Vga256;
 InitVScreen;Cls(0,vaddr);

 NewWOSIntro;

 LoadPal('invasion.pal');
 for i:=0 to 255 do
     begin
      pal[i,1]:=workpal[i,1];pal[i,2]:=workpal[i,2];pal[i,3]:=workpal[i,3];
      workpal[i,1]:=0;workpal[i,2]:=0;workpal[i,3]:=0;
     end;
 Setpal;

 Assign(f,'invasion.fnt');reset(f,1);blockread(f,small,filesize(f));close(f);
 Assign(fscores,'hallfame.dat');reset(fscores);for i:=1 to 10 do read(fscores,Hall_of_fame[i]);close(fscores);

 with spr[11] do
      begin
       xl:=memw[seg(ship1):ofs(ship1)];
       yl:=memw[seg(ship1):ofs(ship1)+2];
       pspr:=ptr(seg(ship1),ofs(ship1)+4);
      end;
 with spr[12] do
      begin
       xl:=memw[seg(ship2):ofs(ship2)];
       yl:=memw[seg(ship2):ofs(ship2)+2];
       pspr:=ptr(seg(ship2),ofs(ship2)+4);
      end;
 with spr[13] do
      begin
       xl:=memw[seg(ship3):ofs(ship3)];
       yl:=memw[seg(ship3):ofs(ship3)+2];
       pspr:=ptr(seg(ship3),ofs(ship3)+4);
      end;
 with spr[14] do
      begin
       xl:=memw[seg(ship4):ofs(ship4)];
       yl:=memw[seg(ship4):ofs(ship4)+2];
       pspr:=ptr(seg(ship4),ofs(ship4)+4);
      end;
 with spr[15] do
      begin
       xl:=memw[seg(ship5):ofs(ship5)];
       yl:=memw[seg(ship5):ofs(ship5)+2];
       pspr:=ptr(seg(ship5),ofs(ship5)+4);
      end;
 with spr[16] do
      begin
       xl:=memw[seg(ship6):ofs(ship6)];
       yl:=memw[seg(ship6):ofs(ship6)+2];
       pspr:=ptr(seg(ship6),ofs(ship6)+4);
      end;
 with spr[17] do
      begin
       xl:=memw[seg(ship7):ofs(ship7)];
       yl:=memw[seg(ship7):ofs(ship7)+2];
       pspr:=ptr(seg(ship7),ofs(ship7)+4);
      end;

 with spr[2] do
      begin
       xl:=memw[seg(target):ofs(target)];
       yl:=memw[seg(target):ofs(target)+2];
       pspr:=ptr(seg(target),ofs(target)+4);
      end;
 with spr[3] do
      begin
       xl:=memw[seg(tile1):ofs(tile1)];
       yl:=memw[seg(tile1):ofs(tile1)+2];
       pspr:=ptr(seg(tile1),ofs(tile1)+4);
      end;
 with spr[4] do
      begin
       xl:=memw[seg(tile2):ofs(tile2)];
       yl:=memw[seg(tile2):ofs(tile2)+2];
       pspr:=ptr(seg(tile2),ofs(tile2)+4);
      end;
 with spr[5] do
      begin
       xl:=memw[seg(tile3):ofs(tile3)];
       yl:=memw[seg(tile3):ofs(tile3)+2];
       pspr:=ptr(seg(tile3),ofs(tile3)+4);
      end;
 with spr[6] do
      begin
       xl:=memw[seg(tile4):ofs(tile4)];
       yl:=memw[seg(tile4):ofs(tile4)+2];
       pspr:=ptr(seg(tile4),ofs(tile4)+4);
      end;
 with spr[7] do
      begin
       xl:=memw[seg(tile5):ofs(tile5)];
       yl:=memw[seg(tile5):ofs(tile5)+2];
       pspr:=ptr(seg(tile5),ofs(tile5)+4);
      end;
 with spr[8] do
      begin
       xl:=memw[seg(tile6):ofs(tile6)];
       yl:=memw[seg(tile6):ofs(tile6)+2];
       pspr:=ptr(seg(tile6),ofs(tile6)+4);
      end;
 with spr[9] do
      begin
       xl:=memw[seg(tile7):ofs(tile7)];
       yl:=memw[seg(tile7):ofs(tile7)+2];
       pspr:=ptr(seg(tile7),ofs(tile7)+4);
      end;
 with spr[10] do
      begin
       xl:=memw[seg(title):ofs(title)];
       yl:=memw[seg(title):ofs(title)+2];
       pspr:=ptr(seg(title),ofs(title)+4);
      end;

 Randomize;
 Initialize;ingame:=false;fadecnt:=0;
 if output=Blaster then PlayFm(1);
 DrawAllowed := false;
 GetIntVec($1C,Int1CSave);
 SetIntVec($1C,Addr(TimerHandler));

 repeat
  if not ingame
     then begin

           repeat
           until DrawAllowed;
           DoDrawings;
           DrawAllowed := false;

           if fadecnt<63
              then begin
                    inc(fadecnt);
                    FadeIn;
                   end;
           {outint(0,50,scorescnt,1,0,vaddr);}
           if not scores
              then putspr(10,0,85,gameput,vaddr)
              else begin
                    Allign:=CenterAllign;
                    outtext(160,30,'HALL OF FAME',1,100,vaddr);
                    for i:=1 to MaxFame do
                        begin
                         Allign:=LeftAllign;
                         outtext(116,(i-1)*11+50,Hall_of_Fame[i].name,1,0,vaddr);
                         Allign:=RightAllign;
                         outint(212,(i-1)*11+50,Hall_of_Fame[i].score,1,0,vaddr);
                        end;
                   Allign:=LeftAllign;
                   end;
           inc(scorescnt);
           if scorescnt>500
              then begin
                    scorescnt:=0;
                    scores:=not scores;
                   end;
           if not highinsert then begin
                                   Allign:=CenterAllign;
                                   outtext(160,169,'PRESS SPC OR ENTER TO START',1,0,vaddr);
                                   Allign:=LeftAllign;
                                  end
                             else begin
                                   Allign:=CenterAllign;
                                   outtext(160,169,'ENTER YOUR NAME',1,0,vaddr);
                                   Allign:=LeftAllign;;
                                   scorescnt:=0;
                                  end;
           key:=port[$60];
           asm
            mov ax,$0c02
            int $21
           end;
           if not highinsert
              then
                   case key of
                   28,57 : begin
                            Initialize;
                            ingame:=true;
                            if output=Blaster
                               then begin
                                     StopMusic;
                                     LoadFm('theme#1',2);
                                     PlayFm(2);
                                    end;
                           end;
                  end
              else
                  case key of
                  72 : begin
                        inc(highcnt);
                        if highcnt>byte('^') then highcnt:=32;
                        Hall_of_Fame[highwhere].name[highpos]:=char(highcnt);
                       end;
                  80 : begin
                        dec(highcnt);
                        if highcnt<32 then highcnt:=byte('^');
                        Hall_of_Fame[highwhere].name[highpos]:=char(highcnt);
                       end;
                  77,28,57 : if highpos<3 then begin
                                                inc(highpos);
                                                delay(15);
                                               end
                                         else begin
                                               highinsert:=false;
                                               Assign(fscores,'hallfame.dat');
                                               reset(fscores);
                                               for i:=1 to 10 do write(fscores,Hall_of_fame[i]);
                                               close(fscores);
                                               delay(15);
                                              end;
                  end;
           if output=Blaster then if StatusByte<>255 then PlayFm(1);
          end
     else
      if not pause
         then begin

               repeat
               until DrawAllowed;
               DoDrawings;
               DrawAllowed := false;

               if output=Blaster then if StatusByte<>255 then PlayFm(2);
               key:=port[$60];
               asm
                mov ax,$0c02
                int $21
               end;
               case key of
                24,75 : begin
                         if x>limxl then dec(x,6);
                         if shipspr>11 then dec(shipspr);
                         shipdir:=1;
                        end;
                25,77 : begin
                         if x+18<limxr then inc(x,6);
                         if shipspr<17 then inc(shipspr);
                         shipdir:=-1;
                        end;
                50,57,28 : begin
			    Fired;
			    if output=BLASTER then PlaYSound(3);
			   end;
                35 : begin
                      pause:=true;
                      outtext(116,95,'GAME PAUSED',1,0,vaddr);
                     end;
                1  : begin
                      if output=Blaster
                         then begin
                               StopMusic;
                               PlayFM(1);
                              end;
                      ingame:=false;key:=0;delay(300);
                     end;
                else if shipspr<>14 then shipspr:=shipspr+shipdir;
               end;
               {outint(0,100,maxtime,3,110,vaddr);
               outint(0,120,fact,3,110,vaddr);}
               if (lives<=0)
                  then begin
                        if output=Blaster
                           then begin
                                 StopMusic;
                                 PlayFM(1);
                                end;
                        ingame:=false;key:=0;delay(300);
                        if CheckHighs then begin
                                            highinsert:=true;
                                            scores:=true;
                                           end;
                       end;
              end
         else begin
               repeat
                key:=port[$60];
                asm
                 mov ax,$0c02
                 int $21
                end;
               until (key=35) or (key=1);
               key:=0;
               pause:=false;
              end;
  flip;
 until (key=1) and (not ingame);

 FadeOut(3);
 SetIntVec($1C,Int1CSave);
 DoneVscreen;
 DoneVga256;
 if output=Blaster
    then begin
          StopMusic;
          UnInstallDriver;
         end;
 writeln('Thank you for playing Karg''s Invasion,(c)1996 WOS');
 writeln('Programming & Design : Karg');
 writeln('Graphics             : Steli');
 writeln('E-mail us at pp709@cs.utt.ro.');
END.