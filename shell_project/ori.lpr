program ori;

{$APPTYPE CONSOLE}
{$I './../VM/ori_Options.inc'}
{$i options.inc}

uses
  SysUtils,
  {$ifdef UNITTESTS}
  Classes,
  {$ENDIF}
  {$IFDEF ORI_DYNAMIC}
  OriWrap, OriOBJWrap,
  {$ELSE}
  Orion,
  ori_Errors,
  {$ENDIF}
  ori_CoreConsole, ori_vmCrossValues;

var
    OriEn: TOrionEngine;

    Args: Array of String;
    ProgDir: String;

procedure showErrors();
  var
  i,c: integer;
  {$ifdef UNITTESTS}
  f: TStrings;
  {$endif}
  MSG,AFILE: AnsiString;
  LINE: Integer;
  Typ: Byte;
begin
    {$IFDEF UNITTESTS}
    f := TStringList.Create;
    {$i-} DeleteFile(__FILE__+'.syntax'); {$i+}
    {$ENDIF}
    c := OriEn.ErrorCount;
    if c > 0 then
    for i := 0 to c - 1 do
    begin
        OriEn.GetError(i, typ, line, msg, afile);
        WriteLn( '[line ', line, '] ',
            ToDos(msg) );

        {$IFDEF UNITTESTS}
        f.Add(ExtractFileName(__FILE__) + ' [line ' + IntToStr(line) + '] '+
            msg);
        {$ENDIF}
    end;
    {$IFDEF UNITTESTS}
    f.SaveToFile(__FILE__+'.syntax');
    f.Free;
    {$ENDIF}
end;

procedure loadArgs();
  var i: integer;
begin
  SetLength(Args, 100);
  for i := 0 to ParamCount do
      Args[i] := ParamStr(i);
end;

function inArgs(const key: string): Boolean;
  var i: integer;
begin
  Result := true;
  for i := 1 to ParamCount - 1 do
      if LowerCase(key) = LowerCase(Args[i]) then
        exit;
  Result := false;
end;

  var
  f: TStrings;
  t: integer;
begin
  try
      loadArgs;
      {$IFDEF ORI_DYNAMIC}
      {$ifdef UNITTESTS}
      if not ORION_LOAD('../dynamic/OrionPHP.dll') then
          raise Exception.Create('Error while loading OrionPHP.dll');
      {$else}
      
      if FileExists(ProgDir + '/OrionPHP.dll') or
          not ORION_LOAD(ProgDir + '/OrionPHP.dll') then
          raise Exception.Create('Error while loading OrionPHP.dll');
      {$ENDIF}
      {$endif}

      {
      Writeln('============ ORION ' +OriEn.getVersion+' ============');
      }

      OriEn.AddModule( @ori_CoreConsole.loadModule );
      OriEn := TOrionEngine.Create(true);

      //Args[1] := '-f';
      //Args[2] := '..\test\core_string.php';

      ChDir(ExtractFileDir(ParamStr(0)));
      t := getTime();

      if Args[1] = '-f' then
      begin
          __FILE__ := Args[2];
          OriEn.EvalFile(Args[2]);
      end else if Args[2] = '-r' then
      begin
          OriEn.Eval(Args[2]);
      end else if (ExtractFileExt(args[1]) = '.ori') or (ExtractFileExt(args[1]) = '.php') then
      begin
          __FILE__ := Args[1];
          OriEn.EvalFile(Args[1]);
      end;

      WriteLn('Time: ', getTime() - t, ' mlsec');

      if OriEn.ErrorExists then
          showErrors();


      OriEn.Free;
      finalOrionEngine;
  except
    on E:Exception do begin
      Writeln(E.Classname, ': ', ToDos(E.Message));
      {$IFDEF UNITTESTS}
        f := TStringList.Create;
        f.Text := E.Classname + ': ' + (E.Message);
        f.SaveToFile(__FILE__+'.av');
        f.Free;
      {$ENDIF}
    end;
  end;
  {$ifdef ORI_DYNAMIC}
  ORION_UNLOAD();
  {$endif}
end.
