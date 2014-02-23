unit ori_ManRes;

// модуль для хранения байт-кода функций объявленных пользователем
//{$mode objfpc}
{$H+}
{$ifdef fpc}
        {$mode delphi}
{$endif}

interface

uses
  Classes, SysUtils,
  ori_StrUtils,
  ori_vmTypes,
  ori_OpGen,
  ori_Errors,
  ori_StrConsts,
  ori_Stack,
  ori_vmCrossValues,
  ori_vmTables,
  ori_vmValues,
  ori_Parser,
  ori_vmEval,
  ori_Types,
  ori_vmVariables,
  ori_HashList,
  ori_vmCompiler,
  ori_vmClasses,
  ori_FastArrays,
  ori_vmMemory;


      function mr_getEval: TOriEval;
      function mr_getCompiler: TOriCompiler;
      function mr_getParser: TOriParser;
      function mr_getErrPool: TOriErrorPool;

      procedure mr_freeEval;

     procedure initManMemory();
     procedure finalManMemory();
     
     procedure clearManMemory(); inline;
     procedure addMANTable(table: Pointer); inline;
     procedure addManFunc(func: Pointer); inline;


     type
        TGarbageWatcher = class(TThread)
        private
          FInterval: Integer;
          LastInterval: Integer;
          LastMemoryUse: Integer;
          procedure SetInterval(const Value: Integer);
        protected
            Working: Boolean;
            Busy   : Boolean;
            StartMemory: Integer;

            procedure FixInterval;
            procedure cleanEvals(const MinCount: Integer; const MaxStep: Integer = 100);
            procedure cleanParsers(const MinCount: Integer; const MaxStep: Integer = 100);
            procedure cleanCompilers(const MinCount: Integer; const MaxStep: Integer = 100);
            procedure cleanTables(const MinCount: Integer; const MaxStep: Integer = 100);
        public
            StateAge: Integer; // возраст постоянства памяти
            function GetUseMemory: Integer;
            function GetCPUUsage: Integer;
            function RunEvalCount: Integer;
            procedure Execute; override;
            procedure ToStop;
            procedure ToStart;
            procedure ToSleep(const mlsec: Integer);
            property Interval: Integer read FInterval write SetInterval;

            constructor Create;
     end;

     procedure tryObjectiveFree(val: TOriMemory); inline;

     var
        ORI_GARBAGE: TGarbageWatcher;

implementation

    uses
    ori_vmUserFunc;

    var
      EvalList,CompilerList,ParserList,ErrPoolList: TList;

procedure initManMemory();
begin
    MANHashes := TPtrArray.Create;
    MANFuncs := TPtrArray.Create;

    MANHashes_f := TPtrArray.Create;
    MANFuncs_f  := TPtrArray.Create;
end;

procedure finalManMemory();
  var
  i: integer;
begin
  {for i := MANHashes.Count - 1 downto 0 do
  begin
      TOriTable(MANHashes.Values^[i]).ClearValues;
      TOriTable(MANHashes.Values^[i]).Free;
  end;

  for i := MANHashes_f.Count - 1 downto 0 do
  begin
      TOriTable(MANHashes_f.Values^[i]).ClearValues;
      TOriTable(MANHashes_f.Values^[i]).Free;
  end;

  for i := MANFuncs.Count - 1 downto 0 do
      TUserFunc(MANFuncs.Values^[i]).Destroy;

  for i := MANFuncs_f.Count - 1 downto 0 do
      TUserFunc(MANFuncs_f.Values^[i]).Destroy;

  mr_freeEval;

  FreeAndNil(MANHashes);
  FreeAndNil(MANFuncs); 

  FreeAndNil(MANHashes_f);
  FreeAndNil(MANFuncs_f); }
  
end;

// функция пытается удалить объект через одну итерацию
// если через одну итерацию на объект что-то уже ссылается
// объект не удаляется.
// Эта функция нужна для объектов "в воздухе",
// например объекты переданные через Return означают что используются,
// иначе после вызова функции объект уничтожится если на него ничего не ссылается.
// но функция может быть вызвана без присвоения,
// и тогда объект как бы повиснет в воздухе
procedure tryObjectiveFree(val: TOriMemory);
begin
    case val.typ of
      mvtHash: tryHashTableFree(val.Mem.ptr);
      mvtFunction: tryUserFuncFree(val.Mem.ptr);
      mvtObject: {TODO};
    end;
end;




procedure addMANTable(table: Pointer);
begin
   MANHashes.Add(table);
end;

procedure addManFunc(func: Pointer);
begin
   MANFuncs.Add(func);
   TUserFunc(func).InManager := true;
end;

procedure clearManMemory();
  var
  i,len: integer;
begin
  len := MANHashes.Count;
  if len > 0 then begin
    for i := len - 1 downto 0 do
    begin
      with TOriTable(MANHashes.Values^[i]) do
      if ref_count < 1 then
      begin
            if MANHashes_f.Count < 1000 then
            begin
                UnsetAll;
                Clear;
                inManager := false;
                MANHashes_f.Add(MANHashes.Values^[i]);
            end else
            begin
                Free;
            end;
      end;
    end;
    
    MANHashes.CacheClear;
  end;

  len := MANFuncs.Count;
  if len > 0 then
  begin
    for i := len -1 downto 0 do
    begin
        with TUserFunc(MANFuncs.Values^[i]) do
        if ref_count < 1 then
        begin
          Free;
        end else
          InManager := false;
    end;
    MANFuncs.CacheClear;
  end;
end;


procedure mr_freeEval;
  var
  i: integer;
begin
  for i := EvalList.Count - 1 downto 0 do
  begin
     with TOriEval(EvalList[i]) do
      begin
         if not isUse then
         begin
          EvalList.Delete(i);
          Free;
         end;
      end;
  end;
end;

function mr_getEval: TOriEval;
  var
  i: integer;
begin
  for i := 0 to EvalList.Count - 1 do
  begin
     with TOriEval(EvalList[i]) do
      if not isUse then
      begin
          Result := TOriEval(EvalList[i]);
          Result.ErrPool.clearErrors;
          Result.isUse := true;
          exit;
      end;
  end;
  Result := TOriEval.create();
  Result.isUse := true;

  if EvalList.Count > 7000 then
  begin
      Result.InManager := false;
  end else begin
      Result.InManager := true;
      EvalList.Add(Result);
  end;
  
  if EvalList.Count > 10000 then
  begin
       Result := nil;
  end;
end;

function mr_getCompiler: TOriCompiler;
  var
  i: integer;
begin
  for i := 0 to CompilerList.Count - 1 do
  begin
     with TOriCompiler(CompilerList[i]) do
      if not isUse then
      begin
          Result := TOriCompiler(CompilerList[i]);
          Result.ErrPool.clearErrors;
          Result.isUse := true;
          exit;
      end;
  end;

  Result := TOriCompiler.create();
  Result.isUse := true;
  CompilerList.Add(Result);
end;

function mr_getParser: TOriParser;
  var
  i: integer;
begin
  for i := 0 to ParserList.Count - 1 do
  begin
     with TOriParser(ParserList[i]) do
      if not isUse then
      begin
          Result := TOriParser(ParserList[i]);
          Result.ErrPool.clearErrors;
          Result.isUse := true;
          exit;
      end;
  end;

  Result := TOriParser.create();
  Result.isUse := true;
  ParserList.Add(Result);
end;

function mr_getErrPool: TOriErrorPool;
  var
  i: integer;
begin
  for i := 0 to ErrPoolList.Count - 1 do
  begin
     with TOriParser(ErrPoolList[i]) do
      if not isUse then
      begin
          Result := TOriErrorPool(ErrPoolList[i]);
          Result.isUse := true;
          exit;
      end;
  end;

  Result := TOriErrorPool.create();
  Result.isUse := true;
  ErrPoolList.Add(Result);
end;


{ TGarbageWatcher }

function TGarbageWatcher.RunEvalCount: Integer;
   var
   i: integer;
begin
    Result := 0;
    for i := 0 to EvalList.Count - 1 do
    if TOriEval(EvalList[ i ]).isRun then
        inc(Result);
end;

procedure TGarbageWatcher.cleanCompilers(const MinCount: Integer; const MaxStep: Integer = 100);
  var
  i,c: integer;
begin
  if CompilerList.Count > MinCount then
  begin
      c := 0;
      for i := CompilerList.Count-1 downto MinCount do
      begin
          if c > MaxStep then begin
             ToSleep(200);
             exit;
          end;
          if not Working then exit;

          if not TOriCompiler(CompilerList[i]).isUse then
          begin
                inc(c);
                TOriCompiler( CompilerList[i] ).Free;
                CompilerList.Delete(i);
          end;
      end;
  end;
  if c < MaxStep then
      ToSleep(4000);
end;

procedure TGarbageWatcher.cleanEvals(const MinCount: Integer; const MaxStep: Integer = 100);
  var
  i,c: integer;
begin
  if EvalList.Count > MinCount then
  begin
      c := 0;
      for i := EvalList.Count-1 downto MinCount do
      begin
          if c > MaxStep then begin
             ToSleep(200);
             exit;
          end;
          if not Working then exit;

          if not TOriEval(EvalList[i]).isUse then
          begin
                inc(c);
                TOriEval( EvalList[i] ).Free;
                EvalList.Delete(i);
          end;
      end;
  end;
  if c < MaxStep then
      ToSleep(4000);
end;



procedure TGarbageWatcher.cleanParsers(const MinCount: Integer; const MaxStep: Integer = 100);
  var
  i,c: integer;
begin
  if ParserList.Count > MinCount then
  begin
      c := 0;
      for i := ParserList.Count-1 downto MinCount do
      begin
          if c > MaxStep then begin
             ToSleep(200);
             exit;
          end;
          if not Working then exit;

          if not TOriParser(ParserList[i]).isUse then
          begin
                inc(c);
                TOriParser( ParserList[i] ).Free;
                ParserList.Delete(i);
          end;
      end;
  end;
  if c < MaxStep then
      ToSleep(4000);
end;

procedure TGarbageWatcher.cleanTables(const MinCount: Integer; const MaxStep: Integer = 100);
  var
  i,c: integer;
begin
  if MANHashes.Count > MinCount then
  begin
      c := 0;
      for i := MANHashes.Count-1 downto MinCount do
      begin
          if c > MaxStep then begin
             ToSleep(200);
             exit;
          end;
          if not Working then exit;

          {if not TOriTable(MANHashes.Values^[i]).isBusy then
          begin
                inc(c);
                TOriParser( MANHashes.Values^[i] ).Free;
                MANHashes.Delete(i);
          end;}
      end;
  end;
  if c < MaxStep then
      ToSleep(4000);
end;

constructor TGarbageWatcher.Create;
begin
  inherited Create(false);

  LastMemoryUse := 0;
  FInterval := 3500;
  StartMemory := GetHeapStatus.TotalAllocated div 1024;
  LastInterval := -1;
  Working := true;
end;

procedure TGarbageWatcher.Execute;
begin
     while True do
     begin
        Sleep(FInterval);
        FixInterval;

        if LastInterval <> -1 then
        begin
            Interval := LastInterval;
            LastInterval := -1;
        end;

        if RunEvalCount = 0 then
        if GetUseMemory > 10000 then //
        begin
          cleanEvals(1000,50);
          cleanCompilers(100,50);
          cleanParsers(100,50);
          cleanTables(100,10);
        end;
     end;
end;

procedure TGarbageWatcher.FixInterval;
begin
  if StateAge < 10 then
      FInterval := 1500
  else if StateAge > 10 then
      FInterval := 3000
  else if StateAge > 20 then
      FInterval := 3500
  else if StateAge > 30 then
      FInterval := 4000;
end;

function TGarbageWatcher.GetCPUUsage: Integer;
begin
  
end;

function TGarbageWatcher.GetUseMemory: Integer;
begin
   Result := (GetHeapStatus.TotalAllocated div 1024) - StartMemory;
   if (LastInterval > Result - 100) and (LastMemoryUse < Result + 100) then
   begin
       inc(StateAge);
   end else
   begin
       StateAge := 0;
   end;
   LastMemoryUse := Result;
end;

procedure TGarbageWatcher.SetInterval(const Value: Integer);
begin
  FInterval := Value;
end;

procedure TGarbageWatcher.ToSleep(const mlsec: Integer);
begin
  LastInterval := Interval;
  Interval := mlsec;
end;

procedure TGarbageWatcher.ToStart;
begin
   Working := true;
end;

procedure TGarbageWatcher.ToStop;
begin
   Working := false;
end;

initialization
    EvalList := TList.Create;
    CompilerList := TList.Create;
    ParserList := TList.Create;
    ErrPoolList := TList.Create;
    //ORI_GARBAGE := TGarbageWatcher.Create;

finalization
    EvalList.Free;
    CompilerList.Free;
    ParserList.Free;
    ErrPoolList.Free;
    //ORI_GARBAGE.ToStop;


end.
