program NewRawDat;

uses snddrv;

var f : file;
    aux : header;
    i : integer;

begin
 assign(f,musicfile);rewrite(f,1);
 for i:=1 to 15 do
     with aux do
          begin
           name:='unused';
           pos:=0;len:=0;
           blockwrite(f,aux,sizeof(aux));
          end;
     with aux do
          begin
           name:='EOH';
           pos:=0;len:=0;
           blockwrite(f,aux,sizeof(aux));
          end;

end.


