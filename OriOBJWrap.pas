unit OriOBJWrap;

{$ifdef fpc}
 {$mode delphi}
{$endif}

{$H+}
{$i './VM/cOptions.inc'}

interface

uses
  Classes, SysUtils, OriWrap, vmCrossValues
  ;

  type
    TOrionEngine = class(TObject)
  private
      public
        O: Pointer;
        __FILE__: MP_String;
        ErrPool: Pointer;
        function getVersion(): AnsiString;
        constructor Create(const initEngine: boolean);
        destructor Destroy; override;

        procedure AddModule(func_init: pointer);

        procedure EvalFile(const aFile: AnsiString; const Return: Pointer = nil);
        procedure Eval(const script: MP_String; const Return: Pointer = nil); overload;

        // errors ... //
        function ErrorExists: Boolean;
        function ErrorCount: Integer;
        procedure GetError(const id: Integer; var typ: byte; var line: integer;
                      var Msg,AFile: AnsiString);

    end;

    procedure initOrionEngine();
    procedure finalOrionEngine();
    
implementation

{ TOrionEngine }
procedure initOrionEngine();
begin
   ori_init();
end;

procedure finalOrionEngine();
begin
   ori_final;
end;


constructor TOrionEngine.Create(const initEngine: boolean);
begin
  if initEngine then
      initOrionEngine;

  self.O := ori_create;
end;

destructor TOrionEngine.Destroy;
begin
   ori_destroy(self.O);
   inherited;
end;

function TOrionEngine.ErrorCount: Integer;
begin
  Result := ori_err_count(self.O);
end;

function TOrionEngine.ErrorExists: Boolean;
begin
  Result := ori_err_count(self.O) > 0;
end;

procedure TOrionEngine.EvalFile(const aFile: AnsiString; const Return: Pointer);
begin
  ori_evalfile(self.O, PAnsiChar(aFile));
end;

              
procedure TOrionEngine.GetError(const id: Integer; var typ: byte;
  var line: integer; var Msg, AFile: AnsiString);
  var
  xMsg,xFile: PAnsiChar;
begin
 ori_err_get(self.O, id, line, typ, xMsg, xFile);
 Msg := xMsg;
 AFile := xFile;
 ori_freeStr(xMsg);
 ori_freeStr(xFile);
end;

procedure TOrionEngine.AddModule(func_init: pointer);
begin
  ori_module_add(func_init);
end;

function TOrionEngine.getVersion(): AnsiString;
   var
   v1,v2,x: integer;
begin
  x := ori_version;
  if x < 0 then
  begin
      Result := '0.' + IntToStr(abs(x));
  end else begin
      if x > 99 then
      begin
          v1 := trunc(x/100);
      end else begin
          v1 := trunc(x/10);
      end;
      v2 := x - v1;
      Result := IntToStr(v1)+'.'+IntToStr(v2);
  end;
end;

procedure TOrionEngine.Eval(const script: MP_String; const Return: Pointer);
begin
  ori_evalcode(self.O, PAnsiChar(script), length(script));
end;

end.
