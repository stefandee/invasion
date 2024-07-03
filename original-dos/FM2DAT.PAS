program SBFM_test;

{$M 32768,0,30000}

uses Dos,Crt,FMPlay;

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
    fs,fd    : file;
    StatusByte : byte;
    Segm,Offs  : word;
    Error      : word;
    Aux        : word;
    Key        : byte;
    Play       : boolean;
    TuneLen    : word;
    h          : header;
    f          : fmtune;
    i,j        : integer;

procedure ReadBytes(Offset : word;Ofs0 : string;Ofsn0 : string);
var aux : char;
begin
if Offset=0 then writeln(Ofs0)
             else begin
                  write(Ofsn0);
                  seek(fs,Offset);
                  repeat
                    blockread(fs,aux,1);
                    write(aux);
                  until (aux=#0) or (filepos(fs)=filesize(fs));
                  writeln;
                  end;
end;

begin

clrscr;

assign(fs,'song_3.cmf');reset(fs,1);blockread(fs,Head,sizeof(Head));
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
     seek(fs,InstrOfs);
     Aux:=InstrNo;
     blockread(fs,InstrTable,16*InstrNo);
     if MusicOfs=filepos(fs) then writeln('Music block continues the instr block.');

     writeln('Reading music table...');
     seek(fs,MusicOfs);
     getmem(MusicTable,filesize(fs)-MusicOfs);
     blockread(fs,MusicTable^,filesize(fs)-MusicOfs);
     TuneLen:=filesize(fs)-MusicOfs;
     writeln('Tune length : ',TuneLen,' of ',filesize(fs));
     end;
close(fs);

assign(fs,MusicFile);reset(fs,1);
repeat
 blockread(fs,h,sizeof(h));
 if h.name='unused'
    then begin
          {write the new header}
          h.name:='theme#8';
          h.pos:=filesize(fs);
          h.len:=tunelen;
          seek(fs,filepos(fs)-sizeof(h));
          blockwrite(fs,h,sizeof(h));
          {write the song info}
          seek(fs,filesize(fs));
          for i:=1 to 16 do
              for j:=1 to 16 do
                  f.instrtable[i,j]:=instrtable[i,j];
          f.instrno:=head.instrno;
          f.ctqn:=head.ctqn;
          f.cts:=head.cts;
          f.tunelen:=tunelen;
          blockwrite(fs,f,sizeof(f)-4);
          blockwrite(fs,MusicTable^,tunelen);
          break;
         end;

until h.name='EOH';
close(fs);

end.


