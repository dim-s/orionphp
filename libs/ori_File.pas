unit ori_File;


//{$mode objfpc}
{$H+}

interface

uses
  SysUtils,
  ori_Types,
  ori_StrUtils,
  ori_StrConsts;

  function realpath(const s: MP_String): MP_String;


implementation

function CheckPath(Path: MP_String): MP_String;
  var
   i: Integer;
begin
 if Path <> '' then
  begin
   i := pos('//', Path);
   while (i <> 0) do
    begin
     Delete(Path, i, 1);
     i := pos('//', Path);
    end;

   i := pos('/./', Path);
   while (i <> 0) do
    begin
     Delete(Path, i, 2);
     i := pos('/./', Path);
    end;
  end;
 Result := Path;
end;


function realpath(const s: MP_String): MP_String;
begin
    Result := ExpandFileName(CheckPath(s));
end;


end.
