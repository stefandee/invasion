unit FMPlay;

interface
 type str8   = string[8];
      Header = record
             name : str8;
             pos  : longint;
             len  : longint;
             end;
      PFMTune = ^FMTune;
      FMTune = record
             InstrTable : array[1..16,1..16] of byte;
             InstrNo    : word;
             Ctqn,Cts   : word;
             TuneLen    : word;
             MusicPtr   : pointer;
             end;
 const
      MusicFile : str8 = 'fm.dat';
 var
    FM : array[1..16] of FMTune;
    StatusByte : byte;
    PlayWhat   : byte;

 procedure LoadFM(name : string;where : byte);
 procedure PlayFM(where : byte);
 procedure SetStatusByte;
 procedure ResetDriver;
 procedure DoneFM(where : byte);
 function  StopMusic : word;
 function  InstallDriver : byte;
 function  UnInstallDriver : byte;

implementation

uses Dos;

var
   segm,offs : word;

procedure LoadFM;
 var f : file;
     h : header;
begin
 assign(f,MusicFile);
 reset(f,1);
 repeat
  blockread(f,h,sizeof(h));
  if h.name=name
     then begin
           seek(f,h.pos);
           blockread(f,FM[where],sizeof(FMTune)-4);
           getmem(FM[where].MusicPtr,h.len);
           blockread(f,FM[where].MusicPtr^,h.len);
           break;
          end;
 until h.name='EOH';
 close(f);
end;

procedure DoneFM;
 begin
  if where<>PlayWhat
     then begin
           freemem(FM[where].Musicptr,FM[where].tunelen);
          end
 end;

function InstallDriver;
 begin
  exec('sbfmdrv.com','');
  if doserror<>0
   then InstallDriver:=doserror
   else InstallDriver:=0;
 end;

procedure SetStatusByte;
begin
 {Setting the status byte...}
 segm:=seg(StatusByte);offs:=ofs(StatusByte);
 asm
   mov bx,1;
   mov dx,segm
   mov ax,offs
   int 80h
 end;
end;

function StopMusic;
begin
 {Stop the music...}
 asm
    mov bx,7
    int 80h
 end;
end;

procedure ResetDriver;
begin
 {Reseting driver...}
 asm
    mov bx,8
    int 80h
 end;
end;

procedure PlayFm;
 var aux : word;
begin
 {Setting instrument table...}
 segm:=seg(FM[where].InstrTable);offs:=ofs(FM[where].InstrTable);
 aux:=FM[where].instrno;
 asm
    mov bx,2
    mov dx,segm
    mov ax,offs
    mov cx,aux
    int 80h
 end;

 aux:=$1234dd div FM[where].cts;
 asm
    mov bx,4
    mov ax,aux
    int 80h
 end;

 {Roll it...}
 segm:=seg(FM[where].MusicPtr^);offs:=ofs(FM[where].MusicPtr^);
 aux:=FM[where].tunelen;
 asm
    mov bx,6
    mov dx,segm
    mov ax,offs
    mov cx,aux
    int 80h
 end;
 PlayWhat:=where;
end;

function UnInstallDriver;
begin
 exec('sbfmdrv.com','/u');
 if doserror<>0 then UnInstallDriver:=doserror
                else UnInstallDriver:=0
end;

BEGIN
END.