type
         Fame  = record
           name  : string[3];
           score : longint;
           end;


var
     f : file of Fame;
    hall_of_fame : array[1..10] of Fame;
    i : integer;

begin
Hall_of_Fame[1].name:='1st';
Hall_of_Fame[1].score:=15000;
Hall_of_Fame[2].name:='2nd';
Hall_of_Fame[2].score:=14000;
Hall_of_Fame[3].name:='3rd';
Hall_of_Fame[3].score:=13000;
for i:=4 to 10 do
 begin
 Hall_of_Fame[i].name:=char(i+48)+'th';
 Hall_of_Fame[i].score:=15000-i*1000;
 end;
assign(f,'hallfame.dat');rewrite(f);
for i:=1 to 10 do write(f,Hall_of_Fame[i]);
end.
