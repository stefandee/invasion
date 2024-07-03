program SBFM_test;

{$M 32768,0,30000}

uses Dos,SndDrv,Crt;

type CMFHeader = record
                ID : packed array[1..4] of char;
                VMajor,VMinor : byte;
                InstrOfs : word;
                MusicOfs : word;
                Ctqn : word;
                Cts  : word;
                TitlOfs : word;
                NameOfs : word;
                RemOfs : word;
                Channel : array[1..16] of byte;
                InstrNo : word;
                Tempo : word;
                end;

var Head       : CMFHeader;
    InstrTable : array[1..16,1..16] of byte;
    MusicTable : pointer;
    f          : file;
    StatusByte : byte;
    Segm,Offs  : word;
    Error      : word;
    Aux        : word;
    Key        : byte;
    Play       : boolean;
    TuneLen    : word;

procedure ReadBytes(Offset : word;Ofs0 : string;Ofsn0 : string);
var aux : char;
begin
if Offset=0 then writeln(Ofs0)
             else begin
                  write(Ofsn0);
                  seek(f,Offset);
                  repeat
                    blockread(f,aux,1);
                    write(aux);
                  until (aux=#0) or (filepos(f)=filesize(f));
                  writeln;
                  end;
end;

{$F+}
procedure Except;
begin
writeln('Unknown command.');
end;
{$F-}


begin

clrscr;

assign(f,'song2.cmf');reset(f,1);blockread(f,Head,sizeof(Head));
with Head do
     begin
     writeln('CMF File id : ',id);
     writeln('Version     : ',VMajor,'.0',Vminor);
     writeln('Clock ticks per quarter note : ',ctqn);
     writeln('Clock ticks per second       : ',cts);
     writeln('Instruments : ',InstrNo);

     ReadBytes(TitlOfs,'No title found.','Title is : ');
     ReadBytes(NameOfs,'No name found.','Name is : ');
     ReadBytes(RemOfs,'No remarks found.','Remarks are : ');

     writeln('Reading instrument table...');
     seek(f,InstrOfs);
     Aux:=InstrNo;
     blockread(f,InstrTable,16*InstrNo);
     if MusicOfs=filepos(f) then writeln('Music block continues the instr block.');

     writeln('Reading music table...');
     seek(f,MusicOfs);
     getmem(MusicTable,filesize(f)-MusicOfs);
     blockread(f,MusicTable^,filesize(f)-MusicOfs);
     TuneLen:=filesize(f)-MusicOfs;
     writeln('Tune length : ',TuneLen,' of ',filesize(f));
     end;
close(f);

{Init Blaster}
Output:=Blaster;
Base:=$220;
InternalSet;

swapvectors;
exec('sbfmdrv.com','');
if doserror<>0
   then begin
        writeln('Error loading MIDI driver...Execution halted.');
        writeln('Ending code is : ',doserror);
        halt;
        end;

{Reseting driver...}
asm
   mov bx,8
   int 80h
end;
if error=0 then writeln('Reseting complete.')
           else begin
                writeln('Error reseting driver.');
                end;

{Install exception routine..}
segm:=seg(Except);offs:=ofs(Except);
asm
   mov bx,$B
   mov dx,segm
   mov ax,offs
   int 80h
end;


{Setting the status byte...}
segm:=seg(StatusByte);offs:=ofs(StatusByte);
asm
   mov bx,1;
   mov dx,segm
   mov ax,offs
   int 80h
end;

{Setting instrument table...}
segm:=seg(InstrTable);offs:=ofs(InstrTable);
asm
   mov bx,2
   mov dx,segm
   mov ax,offs
   mov cx,head.instrno
   int 80h
   mov error,ax
end;

if error=0 then writeln('Succesfully installed the instrument table.')
           else begin
                writeln('Error...Halting execution.');
                halt;
                end;

aux:=$1234dd div head.cts;
asm
   mov bx,4
   mov ax,aux
   int 80h
end;

{Roll it...}
segm:=seg(MusicTable^);offs:=ofs(MusicTable^);
asm
   mov bx,6
   mov dx,segm
   mov ax,offs
   mov cx,tunelen
   int 80h
   mov error,ax
end;
if error=0 then writeln('Music is playing.')
           else begin
                writeln('Error...Halting execution.');
                halt;
                end;

play:=true;
clrscr;
repeat
key:=port[$60];
asm
   mov ax,$0c02
   int $21
end;
gotoxy(10,10);writeln(StatusByte);

case key of
 28 : begin
      play:=not play;
      case play of
      true : asm
                mov bx,9
                int 80h
                mov error,ax
             end;
      false: asm
                mov bx,$A
                int 80h
                mov error,ax
             end;
      end;
      if error=0 then writeln('OK')
                 else writeln('Error.');
      end;
end;

until key=1;

{Stop the music...}
asm
   mov bx,7
   int 80h
   mov error,ax
end;


if error=0 then writeln('OK.')
           else writeln('No music is playing.');
swapvectors;

end.


