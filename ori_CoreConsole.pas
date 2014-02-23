unit ori_CoreConsole;

{$i './VM/ori_Options.inc'}
{$i './shell_project/Options.inc'}

interface

  uses {$IFDEF UNITTESTS} Classes, {$ENDIF} ori_vmCrossValues,

  {$ifdef ORI_DYNAMIC}
      OriWrap
  {$else}
      ori_vmShortApi, ori_vmValues, ori_vmMemory
  {$endif}
  ;

  function ToDos(St: AnsiString): AnsiString;
  function loadModule(init: boolean): byte;
  
  var
    __FILE__ : MP_String;

implementation

uses            
  SysUtils,
  {$IFDEF MSWINDOWS}
    Windows
  {$ENDIF}
  ;

{$IFDEF MSWINDOWS}
function ToDos(St: AnsiString): AnsiString;
var
   Ch   :    PAnsiChar;
begin
          Ch := PAnsiChar(StrAlloc(Length(St) + 1));
          AnsiToOem(PAnsiChar(St), Ch);
          Result := Ch;
          StrDispose(Ch);
end;
{$ELSE}
function ToDos(St: AnsiString): AnsiString;
begin
 Result := St;
end;
{$ENDIF}

procedure x_print(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  i: integer;
begin
  for i := 0 to cnt - 1 do
    Writeln(ToDos(pr[i].AsString));
end;

{$ifdef UNITTESTS}
procedure x_error_Log(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  l: TStringList;
  fname: AnsiString;
begin
  l := TStringList.Create;
  fname := pr[0].AsString + '.log';

  if FileExists(fname) then
  l.LoadFromFile( fname );

  l.Add('[line ' + pr[2].AsString+'] ' + pr[1].AsString);
  l.SaveToFile( fname );
  l.Free;
end;

procedure x_assert(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  l: TStringList;
  fname: AnsiString;
  line: MP_String;
begin
  if pr[0].AsBoolean then
  begin
    l := TStringList.Create;

    l.LoadFromFile(__FILE__);
    line := l[ pr[1].AsInteger-1 ];
    l.Clear;

    fname := __FILE__+'.log';

    if FileExists(fname) then
       l.LoadFromFile( fname );

    l.Add('[line ' + pr[1].AsString+'] ' + line);
    l.SaveToFile( fname );
    l.Free;
  end;
end;
{$endif}


function loadModule(init: boolean): byte;
begin
    if init then
    begin
          ori_func_add(@x_print,'print',1);
          {$ifdef UNITTESTS}
          ori_func_add(@x_error_Log,'error_log',3);
          ori_func_add(@x_assert,'assert',2);
          {$endif}
          ori_func_add(@x_print,'echo',1);
    end;
end;


end.
