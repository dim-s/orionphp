program StaticShort;

{$APPTYPE CONSOLE}

uses
  SysUtils, vmShortApi, vmCoreConsole;

  var
    OriEn: Pointer;
    OpCodeLen: Integer;
    OpCode: PAnsiChar;

    ErrCount: Integer;
    ErrMsg: PAnsiChar;
    ErrFile: PAnsiChar;
    ErrLine, I: Longint;
    ErrType: Byte; 

begin
  try
    ori_module_add( @vmCoreConsole.loadModule );
    ori_init;

    // create orion item engine
    OriEn := ori_create();

    // compile to byte-code and eval byte-code
    OpCode := ori_compilefile(OriEn, 'code.ori', OpCodeLen);
    if ori_err_count(OriEn) = 0 then
        ori_evalcompiled(OpCode, OpCodeLen);

    ErrCount := ori_err_count( OriEn );
    if ErrCount > 0 then begin
    for i := 0 to ErrCount - 1 do
    begin
         ori_err_get( OriEn, i, ErrLine, ErrType, ErrMsg, ErrFile );
         WriteLn('[Line ', ErrLine, ']: ', ToDos(ErrMsg));

        ori_freeStr( ErrMsg );
        ori_freeStr( ErrFile );
    end;
     Sleep(3000);
    end;



    // final
    ori_destroy( OriEn );
    ori_final();

    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
