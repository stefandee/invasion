program raw2dat;
{this program only adds}

uses snddrv;

var fs,fd : file;
    h : header;
    p : pointer;

begin
 assign(fs,'explo.raw');reset(fs,1);
 assign(fd,MusicFile);reset(fd,1);
 repeat
  blockread(fd,h,sizeof(h));
  if h.name='unused'
     then begin
           h.len:=filesize(fs);
           h.pos:=filesize(fd);
           h.name:='explode';
           getmem(p,h.len);
           blockread(fs,p^,h.len);
           seek(fd,filepos(fd)-sizeof(h));
           blockwrite(fd,h,sizeof(h));
           seek(fd,filesize(fd));
           blockwrite(fd,p^,h.len);
           break;
          end;
 until h.name='EOH';
 close(fs);
 close(fd);
end.
