program tst_fmplay;

uses FMPlay,crt;

begin
 if InstallDriver<>0 then halt;
 ResetDriver;
 SetStatusByte;
 LoadFm('theme#4',1);
 PlayFm(1);
 repeat
 until readkey=#13;
 StopMusic;
end.

