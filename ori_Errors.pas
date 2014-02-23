unit ori_Errors;

// модуль типов и структур
//{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils, ori_StrUtils, ori_Types;

    procedure initErrSystem();
    procedure finalErrSystem();
    
    type
    TError = record
        line: cardinal;
        typ : byte;
        msg : MP_String;
        AFile: MP_String;
    end;
    PError = ^TError;

    TArrayError = array of TError;
    PArrayError = ^TArrayError;
    TErrorHandle = function (typ: Byte; fileName: MP_String; msg: MP_String; line: cardinal): Byte;

  const
    exceptContinue = 1;
    exceptRetry    = 2;
    exceptStop     = 3;

  const
    errNone   = 0;
    errParse  = 9;
    errSyntax = 1;
    errSyntaxWarning = 2;
    errSyntaxHint    = 3;
    errSyntaxNotice  = 4;
    errFatal = 5; // фатальная ошибка при выполнении
    errError = 6;
    errWarning = 7;
    errHint  = 8;
    errNotice = errHint;

    // ?? пока не известно для чего они будут нужны
    errCoreWarning = 9;
    errCoreHint = 10;
    errCoreFatal = 11;
    errCoreError = 11;

    var
      errShowHint: Boolean = false;
      errShowWarning: Boolean = true;
      errShowError: Boolean = true;

      errShowSyntaxHint: Boolean = true;
      errShowSyntaxWarning: Boolean = true;

      funcErrHandle: TErrorHandle;



    type
      TOriErrorPool = class(TObject)

          protected
            fileNames: TArrayWide;
            lines: Array of cardinal;

          public
            isUse: Boolean;
            existsFatalError: Boolean;
            errorTable: PArrayError;
            procedure pushFileName(const fileName: MP_String);
            function getFileName(): MP_String;
            procedure discardFileName();

            procedure pushLine();
            procedure discardLine();
            function getLine(): Cardinal;
            procedure setLine(const line: cardinal);
            
            function getLastError(): TError;
            procedure clearErrors();

            procedure setLineToLastErr(const aline: cardinal);
            function errorExists(const typ: Array of Byte): Boolean;
            function newError(const typ: Byte; const msg: MP_String; line: cardinal = 0): byte; overload;

            constructor Create();
            destructor Destroy(); override;
      end;

      function ErrorTypeToStr(const X: Integer): MP_String;

implementation


function ErrorTypeToStr(const X: Integer): MP_String;
begin
   case X of
      errParse: Result := 'Parse Error';
      errSyntax: Result := 'Syntax Error';
      errFatal: Result := 'Fatal Error';
      errWarning: Result := 'Warning';
      errError: Result := 'Error';
      errHint: Result := 'Notice';
      errCoreFatal: Result := 'Core Error';
   end;
end;

function TOriErrorPool.getLastError(): TError;
begin
    Result := errorTable^[ high(errorTable^) ];
end;

procedure TOriErrorPool.setLineToLastErr(const aline: cardinal);
begin
   with errorTable^[ high(errorTable^) ] do
   begin
     if line = 0 then
        line := aline;
   end;
end;

function TOriErrorPool.errorExists(const typ: Array of Byte): Boolean;
   function inArray(const b: byte; const arr: Array of Byte): Boolean;
     var
     i: integer;
   begin
      Result := true;
      for i := 0 to high(arr) do
      if arr[i] = b then exit;
      Result := false;
   end;
   var
   i: integer;
begin
    Result := false;
    for i := 0 to high(errorTable^) do
      if inArray(errorTable^[ i ].typ, typ) then
      begin
          Result := true;
          exit;
      end;
end;


procedure TOriErrorPool.clearErrors();
begin
   SetLength(errorTable^,0);
   SetLength(fileNames,0);
   SetLength(lines,0);
   existsFatalError := false;
end;

procedure initErrSystem();
begin
    funcErrHandle := nil;
    //clearErrors();
end;

procedure TOriErrorPool.pushFileName(const fileName: MP_String);
begin
   SetLength(fileNames, length(fileNames)+1);
   fileNames[Length(fileNames)-1] := fileName;
end;

constructor TOriErrorPool.Create;
begin
  new( errorTable );
  Self.existsFatalError := false;
end;

destructor TOriErrorPool.Destroy;
begin
  SetLength(errorTable^,0);
  Dispose(errorTable);
  inherited;
end;

procedure TOriErrorPool.discardFileName();
begin
   SetLength(fileNames, length(fileNames)-1);
end;

function TOriErrorPool.getFileName(): MP_String;
begin
  if Length(fileNames) > 0 then
    Result := fileNames[Length(fileNames)-1]
  else
    Result := '';
end;


// добавляем в стек систему номера строк, это необходимо делать,
// т.к. будут вложенные файлы
procedure TOriErrorPool.pushLine();
begin
   SetLength(lines, length(lines)+1);
end;

procedure TOriErrorPool.discardLine();
begin
   SetLength(fileNames, length(fileNames)-1);
end;

function TOriErrorPool.getLine(): Cardinal;
begin
  if Length(lines) > 0 then
    Result := lines[Length(lines)-1]
  else
    Result := 0;
end;

procedure TOriErrorPool.setLine(const line: cardinal);
begin
   if Length(lines) = 0 then
      pushLine;

   lines[high(lines)] := line;
end;

function TOriErrorPool.newError(const typ: Byte; const msg: MP_String; line: cardinal = 0): byte;
  var
  len: integer;
begin
    if line = 0 then
       line := getLine;

    // здесь вызов пользовательской функции обработки ошибок, если пользователь задал такую
    if Assigned(funcErrHandle) then
    begin
      Result := funcErrHandle(typ, getFileName, msg, line);
      if Result = 1 then exit;      
    end;

    if not errShowHint and (typ = errHint) then exit;
    if not errShowWarning and (typ = errWarning) then exit;
    if not errShowError and (typ = errError) then exit;
    if not errShowSyntaxHint and (typ = errSyntaxHint) then exit;
    if not errShowWarning and (typ = errSyntaxWarning) then exit;

   // if typ = errFatal then
      existsFatalError := true;

    len := Length(errorTable^);
    SetLength(errorTable^, len+1);
    
    errorTable^[len].typ := typ;
    errorTable^[len].line := line;
    errorTable^[len].AFile := ( getFileName );
    errorTable^[len].msg := ( msg );

    Result := exceptContinue;
end;

procedure finalErrSystem();
begin
   funcErrHandle := nil;
end;

end.

