unit ori_vmCompiler;

{$H+}
{$ifdef fpc} {$mode delphi} {$endif}

interface

uses
  Classes, SysUtils,
  ori_StrUtils,
  ori_OpGen,
  ori_Errors,
  ori_StrConsts,
  ori_Types,
  ori_vmUserFunc,
  ori_vmNativeFunc,
  ori_vmTypes,
  ori_Parser,
  ori_Stack,
  ori_Math,
  ori_FastArrays,
  ori_vmMemory;



  type
   TOriCompiler = class(TObject)
   
            FTokens: TArrayToken;
            FTokens2: TArrayToken;
            AddCloneHash: Boolean;
        protected
            FBreakes: TArrayCardinal;
            isToStack: Boolean;
            curLine: Cardinal;
            lastLine: Cardinal;
            cI: Integer;

            prev   : PCodeBlock;
            current: PCodeBlock;
            next   : PCodeBlock;

            /// дл€ компил€ции выражений
            tk,prevTk,nextTk: PToken;
            progressI: Integer;
            opLine: POpcodeLine;
            data: TOpcodeArray;

            moduleName: MP_String;
            moduleType: Byte;

            inClass: Boolean;

            // хеш запрос на операцию клонировани€
            // хранить последний оператор GET_HASH
            lastGetHash: POpcodeLine;
            stackGetHash: TPtrArray;
            stackGetHashP: Array[0..127] of Word;
            lastStackHash: Integer;

            stackLen: Integer; // длина стека выражени€...

            function addOpcodeExpr(typ: byte; const create_oper1: boolean): POpcodeLine;
            function checkConsts(): boolean;
            function checkOperators(): boolean;
            function checkLogics(): boolean;
            function checkAssign(): boolean;
            function checkCall(): boolean;
            function checkFunc(): Boolean;
            function checkLexWord(): Boolean;

            procedure indexTokens(ncode: TOpcodeArray);
            procedure compileTokens(tokens: TArrayToken; ncode: TOpcodeArray);
            function checkSyntaxExpr(ncode: TOpcodeArray): Boolean;

            // компил€ци€ выражени€ в 3х адресный оп-код
            procedure compile3xExpr(opcode: TOpcodeArray);
            function addByteCode(var tokens: TArrayToken): Integer;
            procedure addCompileToken(const typ: byte);
            procedure addCompileIf(); inline;
            procedure addCompileElseif();
            procedure addCompileElse(); inline;
            procedure addCompileWhile();
            procedure addCompileDo(); inline;
            procedure addCompileFor();
            procedure addCompileForeach();
            procedure addCompileFunction();
            procedure addCompileModule(); inline;
            procedure addCompileUse();
            procedure addCompileReturn();
            procedure addCompileBreak(); inline;
            procedure addCompileContinue(); inline;

            procedure addCompileClass();
            procedure addCompileProperty();

            procedure addIfElse();
            procedure addLexBlock(); // добавить обработку

            procedure pushBreak(const X: Cardinal);
            function popBreak(): Integer;

        public
            isUse: Boolean;
            __FILE__: MP_String;
            //opcode: PArrayOpcode; // оп-код
            Opcode: TOpcodeArray;
            ErrPool: TOriErrorPool;
            constructor create(const initOpcode: boolean = true);
            destructor destroy(); override;
            procedure clearSource();
            function addCompileExpr(const s: MP_String): POpcodeLine;

            function addOpcode(typ: byte; const create_oper1: boolean = false): POpcodeLine;
            procedure compile(source: TPtrArray); overload;  // исходники
            procedure compile(source: TPtrArray; dest: TOpcodeArray); overload;
            procedure optimizeShort(); // оптимизаци€ оп кодов, сокращаем 2 оп кода в 1
            procedure optimizeJump(); // оптимизаци€ прыжков
            procedure optimizeClear(); // очищение от лишних оп кодов...
            procedure fixJumpInFunc(); //
   end;


  procedure discardOpcode(op: POpcodeLine);
  procedure discardOpcodeS(code: TOpcodeArray);

implementation

  uses ori_ManRes;

procedure discardOpcode(op: POpcodeLine);
begin
  if op^.oper1 <> nil then
  begin
    op^.oper1.Destroy;
    op^.oper1 := nil;
  end;

  if op^.oper2 <> nil then
  begin
    op^.oper2.Destroy;
    op^.oper2 := nil;
  end;
  Dispose(op);
end;

procedure discardOpcodeS(code: TOpcodeArray);
  var
  i: integer;
begin
  for i := 0 to code.Count - 1 do
  begin
    discardOpcode(POpcodeLine(code.Values^[i]));
  end;
  code.Clear;
end;

function TOriCompiler.addOpcodeExpr(typ: byte; const create_oper1: Boolean): POpcodeLine;
begin
     New(Result);
     Result^.typ := typ;

     Result^.toStack := isToStack;
     Result^.checkMemory := false;

     if create_oper1 then
     begin
        Result^.oper1 := TOriMemory.Create;
        Result^.oper1.id  := -1;
     end else
        Result^.oper1 := nil;
        Result^.oper2 := nil;

     Result^.line := tk^.line;

     data.Add(result);
     Result^.cnt := -1;
     Result^.id  := -1;
     Result^.ptr := nil;
     opLine := Result;
end;


function TOriCompiler.checkConsts(): boolean;
begin
  Result := true;
       case tk^.typ of
          opTrue: addOpcodeExpr(OP_PUSH_B, true)^.oper1.Val(true);
          opFalse: addOpcodeExpr(OP_PUSH_B, true)^.oper1.Val(false);
          opInteger: addOpcodeExpr(OP_PUSH_L, true)^.oper1.ValL(StrToInt(tk^.val));
          opDouble:  addOpcodeExpr(OP_PUSH_D, true)^.oper1.ValF(StrToFloat(tk^.val));
          opString: begin
                if tk^.val = defSelf then
                  addOpcodeExpr(OP_PUSH_N, true)^.oper1.id := 0
                else if tk^.val = defParent then
                  addOpcodeExpr(OP_PUSH_N, true)^.oper1.id := 1
                else
                  addOpcodeExpr(OP_PUSH_S, true)^.oper1.Val(tk^.val);
                end;
          opBoolean: addOpcodeExpr(OP_PUSH_B, true)^.oper1.Val(StrToBool(tk^.val));
          opMagicString: addOpcodeExpr(OP_PUSH_MS, true)^.oper1.Val(tk^.val);
          opNull : addOpcodeExpr(OP_PUSH_N, true)^.oper1.ValType(mvtNull);
          opHexNumber: begin
                        tk^.val := base_convert( Cut(tk^.val,1,2),16,10 );
                        if tk^.val = '' then
                        begin
                            ErrPool.newError(errSyntax, MSG_ERR_HEXNUM, tk^.line);
                            exit;
                        end;

                        addOpcodeExpr(OP_PUSH_L, true)^.oper1.ValL( StrToInt(tk^.val) );
                 end;
          opClassVar: begin
                 with addOpcodeExpr(OP_PUSH, true)^.oper1 do
                 begin
                       id := -2; // Static Var modifer = -2
                       Val(tk^.val);
                 end;
          end;
          opVar: with addOpcodeExpr(OP_PUSH_V, true)^.oper1 do
                 begin
                     id := -1;
                     Typ := mvtVariable;
                     Mem.Str := LowerCase(tk^.val);
                     Delete(Mem.Str,1,1);
                     if Mem.Str = 'globals' then
                     begin
                         typ := mvtGlobalVar;
                         opLine^.typ := OP_PUSH_GV;
                     end;
                 end;
          opGlobalVar:  with addOpcodeExpr(OP_PUSH_GV, true)^.oper1 do
                 begin
                     id := -1;
                     Typ := mvtGlobalVar;
                     Mem.str := LowerCase(tk^.val);
                     Delete(Mem.str,1,1);
                 end;
          opWord: begin
              if UpperCase(tk^.val) = defPreLINE then
              begin
                  addOpcodeExpr(OP_PUSH_L, true)^.oper1.ValL(curLine)
              end else if UpperCase(tk^.val) = defPreFILE then
              begin
                  addOpcodeExpr(OP_PUSH_S, true)^.oper1.Val(__FILE__);
              end else
                  with addOpcodeExpr(OP_PUSH, true)^.oper1 do begin
                    Mem.str  := tk^.val;
                    Typ := mvtWord;
                  end;
          end;
          else
              Result := false;
       end;
end;

function TOriCompiler.checkOperators(): boolean;
begin
  Result := true;
      case tk^.typ of
          opPlus     : addOpcodeExpr(OP_PLUS,false);
          opMinus    : addOpcodeExpr(OP_MINUS,false);
          opMul      : addOpcodeExpr(OP_MUL,false);
          opDiv      : addOpcodeExpr(OP_DIV,false);
          opXor      : addOpcodeExpr(OP_XOR,false);
          opMod      : addOpcodeExpr(OP_MOD,false);
          opConcat   : addOpcodeExpr(OP_CONCAT,false);
          opUnarMinus: addOpcodeExpr(OP_UNARMINUS,false);
          opPlusPlus : addOpcodeExpr(OP_INC,false);
          opMinusMinus: addOpcodeExpr(OP_DEC,false);
          opHashValue: addOpcodeExpr(OP_HASH_VALUE,false);
          opLink     : addOpcodeExpr(OP_LINK,false);
          opBitNot   : addOpcodeExpr(OP_BIT_NOT,false);
          opShl      : addOpcodeExpr(OP_SHL,false);
          opShr      : addOpcodeExpr(OP_SHR,false);
          opBitAnd   : addOpcodeExpr(OP_BIT_AND,false);
          opBitOr    : addOpcodeExpr(OP_BIT_OR,false);

          opTypInteger : addOpcodeExpr(OP_TYPED_INT,false);
          opTypDouble  : addOpcodeExpr(OP_TYPED_DOUBLE,false);
          opTypBoolean : addOpcodeExpr(OP_TYPED_BOOL,false);
          opTypString  : addOpcodeExpr(OP_TYPED_STR,false);
          opTypArray   : addOpcodeExpr(OP_TYPED_ARRAY,false);
          opTypObject  : addOpcodeExpr(OP_TYPED_OBJ,false);

          opBreak    :
          begin
             addOpcodeExpr(OP_BREAK,false);
          end;
          else
            Result := false;
      end;
end;


function TOriCompiler.checkLogics(): boolean;
begin
  Result := true;
      case tk^.typ of
          opEq       : addOpcodeExpr(OP_EQUAL,false);
          opEqTyp    : addOpcodeExpr(OP_EQUAL_T,false);
          opNotEq    : addOpcodeExpr(OP_NOEQUAL,false);
          opNoteqTyp : addOpcodeExpr(OP_NOEQUAL_T,false);
          opNot      : addOpcodeExpr(OP_NOT,false);
          opMin      : addOpcodeExpr(OP_ISMIN,false);
          opMinEq    : addOpcodeExpr(OP_ISMIN_EQ,false);
          opMax      : addOpcodeExpr(OP_ISMAX,false);
          opMaxEq    : addOpcodeExpr(OP_ISMAX_EQ,false);
          opAnd      : addOpcodeExpr(OP_AND,false);
          opOr       : addOpcodeExpr(OP_OR,false);
          opLogicXor : addOpcodeExpr(OP_LOGIC_XOR,false);
          opIn       : addOpcodeExpr(OP_IN,false);
          else
            Result := false;
      end;
end;

function TOriCompiler.checkAssign(): boolean;
begin
  Result := true;
      case tk^.typ of
          opAssign      : addOpcodeExpr(OP_ASSIGN,false);
          opPlusAssign  : addOpcodeExpr(OP_PLUS_ASSIGN,false);
          opMinusAssign : addOpcodeExpr(OP_MINUS_ASSIGN,false);
          opMulAssign   : addOpcodeExpr(OP_MUL_ASSIGN,false);
          opDivAssign   : addOpcodeExpr(OP_DIV_ASSIGN,false);
          opModAssign   : addOpcodeExpr(OP_MOD_ASSIGN,false);
          opXorAssign   : addOpcodeExpr(OP_XOR_ASSIGN,false);
          opConcatAssign: addOpcodeExpr(OP_CONCAT_ASSIGN,false);
          else
            Result := false;
      end;
end;


function TOriCompiler.checkCall(): boolean;
begin

  if tk^.typ = opCallHash then
  begin
       with addOpcodeExpr(OP_GET_HASH,false)^ do
       begin
          cnt    := tk^.cnt+1;
          Result := True;
          if AddCloneHash then
            Typ := OP_GET_CLONE_HASH;

          if lastGetHash <> nil then
          begin
              
          end;

          exit;
       end;
  end else
  if tk^.typ = opCallStatic then
  begin
       with addOpcodeExpr(OP_CALL_STATIC,false)^ do
       begin
          Result := True;
          exit;
       end;
  end else
  if tk^.typ = opCallFunc then
  begin
      if tk^.val = defArray then
      begin
          addOpcodeExpr(OP_NEW_ARRAY,false);
      end else if tk^.val = defGlobal then
      begin
          addOpcodeExpr(OP_GLOBAL,false);
      end else if tk^.val = defUnset then
          addOpcodeExpr(OP_UNSET,false)
      else
      if tk^.val = '' then
        addOpcodeExpr(OP_CALL,false)
      else begin
        addOpcodeExpr(OP_CALL, true)^.oper1.ValWord( LowerCase( tk^.val ) );
      end;
      
      opLine^.cnt := tk^.cnt;

      Result := true;
  end else
      Result := false;
end;

function TOriCompiler.checkFunc(): Boolean;
begin
  {if tk^.typ = opFunc then
  begin
           ErrPool.newError(errSyntax, MSG_ERR_FUNCNAME, tk^.line);
           Result := false;
           exit;
      Result := true;
  end else
      Result := false; }
end;

function TOriCompiler.checkLexWord(): Boolean;
begin
  if tk^.typ in [opDefine{,opIf,opElse,opElseif,opWhile}] then
  begin
      case tk^.typ of
          // define
          opDefine: begin
                    addOpcodeExpr(OP_DEFINE,false)^.cnt := tk^.cnt;
                    Result := true;
                    exit;
                    end;
      end;
  end;
  Result := false;
end;


procedure TOriCompiler.indexTokens(ncode: TOpcodeArray);
   var
   stackIndex: array of cardinal;
   stackOpcode: array of POpcodeLine;
   ln: POpcodeLine;
begin
   tk := nil;
   progressI := -1;

   while True do
    begin

        inc(progressI);
        if progressI >= ncode.Count then break;

        ln := POpcodeLine(ncode[progressI]);

        if ln^.typ = OP_SKO then
        begin

            SetLength(stackOpcode,Length(stackOpcode)+1);
            stackOpcode[high(stackOpcode)] := ln;

            // просто метка теперь
            //ln^.typ := OP_NOP;

            SetLength(stackIndex,Length(stackIndex)+1);
            stackIndex[high(stackIndex)] := progressI;
        end else if ln^.typ = OP_SKC then
        begin
            if length(stackOpcode) = 0 then
            begin
                 ErrPool.newError(errSyntax, MSG_ERR_NOCORRECTSKOBE, ln^.line);
                 clearSource;
                 Exit;
            end;
            // обмениваемс€ индексацией
            stackOpcode[high(stackOpcode)]^.cnt := progressI;
            ln^.cnt := stackIndex[high(stackIndex)];

            // означает что это метка
            //ln^.typ := OP_NOP;

            SetLength(stackOpcode,Length(stackOpcode)-1);
            SetLength(stackIndex, Length(stackIndex)-1);
        end;

    end;

    if length(stackIndex) > 0 then
    begin
          ErrPool.newError(errSyntax, MSG_ERR_NOCORRECTSKOBE, stackOpcode[high(stackOpcode)]^.line);
          clearSource;
    end;
end;




// главна€ функци€ дл€ компил€ции токенов в байт код
procedure TOriCompiler.compileTokens(tokens: TArrayToken; ncode: TOpcodeArray);
   var
   len: cardinal;
   i: integer;
   stackGetHashP: integer;
begin
    progressI := -1;
    stackGetHashP := -1;
    len := tokens.Count;
    tk := nil;
    data := ncode;
    stackLen := 0;
    lastStackHash := 255;
    stackGetHash.CacheClear;
    
    if len > 0 then begin
    while True do
    begin
        if ErrPool.errorExists([errSyntax,errParse]) then exit;

        inc(progressI);
        if progressI >= len then break;

        tk := tokens.Values^[progressI];

        if progressI <> 0 then prevTk := tokens.Values^[progressI-1]
        else           prevTk := nil;

        if progressI <> len-1 then nextTk := tokens.Values^[progressI+1]
        else           nextTk := nil;

        if nextTk = nil then
            isToStack := true
        else begin
            isToStack := not(nextTk^.typ in [opBreak]);
            if not isToStack then
              stackLen := 0;
        end;

        if not checkOperators then
        if not checkLogics then
        if not checkConsts then
        if not checkAssign then
        if not checkCall then
        //if not checkFunc then
        if tk^.typ = opBSKo then
            addOpcodeExpr(OP_SKO,false)
        else if tk^.typ = opBSKc then
        begin
            addOpcodeExpr(OP_SKC,false);
        end else
            continue;

        if opLine^.typ in sOP_PUSH then inc(stackLen);
        if opLine^.typ in sOP_CALL_EX then
        begin
            dec(stackLen,opLine^.cnt-1);
            if (opLine^.oper2 <> nil) and (opLine^.oper1.typ <> mvtWord) then
              dec(stackLen);
            if (opLine^.oper1 = nil) and not (opLine^.typ in [OP_GET_HASH,OP_NEW_ARRAY]) then
              dec(stackLen);
        end else
        if opLine^.typ in sOP_BIN_OPER then
        begin
          if isToStack then
              dec(stackLen)
          else
              dec(stackLen,2);
        end;
        
        // TODO: !!!!!!!!!!!1
        // »справить, убрать стековую систему, это видно по коду
        // что список stackGetHash не нужен, его можно заменить одной ссылкой
        // тоже самое с stackGetHashP, это можно заменить на одну переменную
        if stackGetHash.Count > 0 then
        if stackLen < stackGetHashP then
        begin
           stackGetHash.Clear;
           stackGetHashP := -1;
        end;
        
        if (opLine^.typ in sOP_ASSIGN) then
        begin
           if (stackGetHash.Count > 0) and (stackGetHashP = stackLen) then
            begin
            for i := 0 to stackGetHash.Count - 1 do
              POpcodeLine(stackGetHash.Values^[i])^.typ := OP_GET_CLONE_HASH;

            stackGetHash.Clear;
            stackGetHashP := -1;
            continue;
            end;
        end;

        if opLine^.typ = OP_GET_HASH then
        begin
            {if (stackGetHash.Count = 0) or (stackGetHashP[ stackGetHash.Count - 1 ] = stackLen) then
            begin}
                stackGetHash.Add(opLine);
                if stackGetHashP = -1 then
                stackGetHashP := stackLen;
            //end;
        end;

    end;

    end;
end;


{ TOriCompiler }

procedure TOriCompiler.compile3xExpr(opcode: TOpcodeArray);
   Var
   i,c: integer;
   stack: array of Integer; // —“≈ ...
   ln1,ln2: POpcodeLine;
begin
// задача, мы должны заранее пройтись по стеку и просчитать оп-код
SetLength(stack,0);

     for i := 0 to opcode.Count-1 do
     begin
          if opcode[i]^.typ in sOP_PUSH then
          begin
              SetLength(stack, length(stack)+1);
              stack[high(stack)] := i;
          end else if opcode[i]^.typ in sOP_UN_OPER then
          begin
              c := high(stack);

              if stack[c] = -1 then
              begin
                  opcode[i]^.oper1 := nil;
              end else begin
                  opcode[i]^.oper1 := opcode[ stack[c] ]^.oper1;
                  Dispose(opcode[stack[c]]);
                  opcode[stack[c]]   := nil;
              end;

              SetLength(stack, length(stack)-1);
              if opcode[i]^.toStack then
              begin
                SetLength(stack, length(stack)+1);
                stack[high(stack)] := -1;
              end;

          end else if opcode[i]^.typ in sOP_BIN_OPER then
          begin
              c := high(stack);
              if {(not toUse) and }(c > 0) then
              begin

                  if stack[c-1] = -1 then
                  begin
                      ln1 := nil;
                      opcode[i]^.oper1 := nil;
                  end else
                  begin
                      ln1 := opcode[stack[c-1]];
                      opcode[i]^.oper1 := ln1^.oper1;
                      opcode[stack[c-1]] := nil;
                  end;

                  if stack[c] = -1 then
                     opcode[i]^.oper2 := nil
                  else
                  begin
                      ln2 := opcode[stack[c  ]];
                      opcode[i]^.oper2 := ln2^.oper1;
                      opcode[stack[c]]   := nil;
                      Dispose(ln2);
                  end;

                  SetLength(stack,length(stack)-2);
              end else
              begin

                  if c = -1 then
                  begin
                     ln1 := nil;
                     opcode[i]^.oper1 := nil;
                  end else begin

                     if stack[c] = -1 then
                     begin
                        ln1 := nil;
                        opcode[i]^.oper2 := nil;
                        opcode[i]^.oper1 := nil;
                     end
                     else
                     begin
                        ln1 := opcode[stack[c]];
                        opcode[i]^.oper1 := ln1^.oper1;
                        opcode[stack[c]]   := nil;
                     end;

                     SetLength(stack, length(stack)-1);
                  end;
              end;

              if opcode[i]^.toStack then
              begin
                SetLength(stack, length(stack)+1);
                stack[high(stack)] := -1;
              end;

              if ln1 <> nil then
              Dispose(ln1);
          end else if opcode[i]^.typ in sOP_CALL then
          begin
              if opcode[i]^.cnt > 0 then
              begin
                if opcode[i]^.cnt > 1 then
                SetLength(stack, length(stack)-(opcode[i]^.cnt-1));

                  c := high(stack);
                  if c = -1 then
                  begin
                    opcode[i]^.oper2 := nil;
                  end else begin
                    if stack[c] = -1 then
                    begin
                      //ln1 := nil;
                      opcode[i]^.oper2 := nil;
                    end else begin
                      ln1 := opcode[stack[c]];
                      opcode[i]^.oper2 := ln1^.oper1;
                      opcode[stack[c]]   := nil;
                      Dispose(ln1);
                    end;

                    SetLength(stack, length(stack)-1);
                  end;
              end;
          end;

          // !!!!!!!!!!!!!!!!!!!!!
          if opcode[i]^.toStack and (opcode[i]^.typ in [OP_GET_HASH, OP_GET_CLONE_HASH,
                                      OP_CALL,OP_CALL_NATIVE,OP_NEW_ARRAY]) then begin
               SetLength(stack, length(stack)+1);
               stack[high(stack)] := -1;
          end;

     end;

     for i := opcode.Count-1 downto 0 do
        if opcode[i] = nil then
           opcode.Delete(i);
end;

function TOriCompiler.addByteCode(var tokens: TArrayToken): Integer;
   var
   ncode: TOpcodeArray;
   i,len: cardinal;
begin
    Result := 0;
    stackLen := 0;
    
    ncode := TOpcodeArray.Create;
    compileTokens(tokens, ncode);

    if not ((stackLen < 2) and (stackLen >= 0)) then
    begin
        Result := 0;
    end else begin

      compile3xExpr(ncode);
      Result := ncode.Count + Opcode.Count;
    end;

    if Result > 0 then
    begin
      for i := 0 to ncode.Count - 1 do
      begin
        Opcode.Add(ncode[i]);
        ncode[i]^.line := curLine;
      end;
      opcode[opcode.Count-1]^.checkMemory := true;
    end;

    ncode.Free;
end;

// добавл€ет в байт код выражение
function TOriCompiler.addCompileExpr(const s: MP_String): POpcodeLine;
begin
   FTokens.Clear;
   ori_OpGen.safeString(s, FTokens);

   if ori_OpGen.polkaTokens(FTokens, FTokens2, ErrPool) > 0 then
   begin
      ErrPool.setLineToLastErr(curLine);
      clearSource;
      exit;
   end;

   if FTokens2.Count = 0 then
   begin
      Result := nil;
   end
   else begin
      if addByteCode(FTokens2) = 0 then
      begin
           ErrPool.newError(errSyntax, MSG_ERR_EXPR, curLine);
      end else
          Result := opcode[opcode.Count-1];
   end;

   clearTokens(FTokens);
end;


procedure TOriCompiler.addCompileFor;
  var
  b: PCodeFor;
  i,j: integer;
  tmp: POpcodeLine;
begin
  b := PCodeFor(current^.block);
  // for ($i=0;$i<10000;$i++)
  for I := 0 to high(b^.param) do // $i=0;
  begin
      addCompileExpr(b^.param[i]);
      addOpcode(OP_BREAK);
  end;

  addCompileExpr(b^.cond);
  //addOpcode(OP_IF_N);
  tmp := addOpcode(OP_JMPZ_N);
  addOpcode(OP_NOP); // на конец...

  j := Opcode.Count-1;

  for i := 0 to high(b^.iter) do begin // $i=0;
      addCompileExpr(b^.iter[i]);
      addOpcode(OP_BREAK);
  end;

  addCompileExpr(b^.cond); // $i<10000
  addOpcode(OP_IF)^.cnt := j+1;
  j := Opcode.Count-1;

  addOpcode(OP_NOP);

  addOpcode(OP_FOR)^.cnt := j;
  tmp^.cnt := Opcode.Count+1;
end;

procedure TOriCompiler.addCompileForeach;
  var
  f: PCodeForeach;
begin
    f := PCodeForeach(Self.current^.block);
    addCompileExpr(f^.param);
    opcode[opcode.Count-1]^.checkMemory := false;

    with addOpcode(OP_FOREACH_INIT)^ do
         if f^.value_link then cnt := 1;

    with addOpcode(OP_FOREACH,true)^ do begin
    begin
      oper1.Typ  := mvtVariable;
      oper1.Mem.Str := f^.value;
    end;

      if f^.key <> '' then
      begin
          oper2 := TOriMemory.Create;
          oper2.Typ := mvtVariable;
          oper2.Mem.Str := f^.key;
      end;
    end;
end;

{

  init $arr --> stack
  foreach  $key, $value <-- stack

}

procedure TOriCompiler.addCompileFunction;
  var
  f: PCodeFunction;
begin
  new(f);
  f^ := PCodeFunction(Self.current^.block)^;
  if f^.assign <> '' then begin
      AddCloneHash := true;
      addCompileExpr(f^.assign)^.checkMemory := false;
      AddCloneHash := false;
  end;

  addOpcode(OP_NOP); // дл€ ключевого слова USE резирвируем...
  with addOpcode(OP_DEFINE_FUNC, true)^ do
  begin
       oper1.Typ := mvtFunction;
       oper1.Mem.ptr := f;
       toStack := true;
  end;
end;

procedure TOriCompiler.addCompileIf;
begin
   addCompileExpr(current^.val);
   addOpcode(OP_IF);
end;


procedure TOriCompiler.addCompileModule;
begin
  addOpcode(OP_MODULE,true)^.oper1.Val(current^.val);
end;

procedure TOriCompiler.addCompileReturn;
  var
  r: POpcodeLine;
begin
  r := addCompileExpr(current^.val);
  if r = nil then
  begin
     r := addCompileExpr(defNull);
  end;

  r^.checkMemory := false;
  r^.toStack := true;

  addOpcode(OP_RET)^.checkMemory := true;
end;

procedure TOriCompiler.addCompileElse;
begin
  addOpcode(OP_ELSE);
end;

procedure TOriCompiler.addCompileElseif;
  var
  i: integer;
begin
  //addOpcode(OP_WHILE);
  i := Opcode.Count-1;
  if i = -1 then i := 0;
   addCompileExpr(current^.val);
   addOpcode(OP_ELSEIF)^.cnt := i;
end;

procedure TOriCompiler.addCompileToken(const typ: byte);
begin
   case typ of
      opBSKo : addOpcode(OP_SKO);
      opBSKc : addOpcode(OP_SKC);
      opBreak: begin
          addOpcode(OP_BREAK);
          end;
   end;
end;


procedure TOriCompiler.addCompileUse;
begin
  with addOpcode(OP_USE_AS,true)^ do
  begin
      oper1.ValWord( current^.val );

      oper2 := TOriMemory.Create;
      oper2.ValWord(current^.param);
  end;
end;

procedure TOriCompiler.addCompileBreak;
begin
  addOpcode(OP_CYCLE_BREAK);
end;

procedure TOriCompiler.addCompileClass;
begin
  with addOpcode(OP_DEF_CLASS, true)^ do
  begin
      oper1.ValWord(PCodeClass(current^.block)^.name);
      if PCodeClass(current^.block)^.parent_class <> '' then
      begin
          oper2 := TOriMemory.Create;
          oper2.Mem.str := PCodeClass(current^.block)^.parent_class;
      end;
  end;
end;

procedure TOriCompiler.addCompileProperty;
  var
  prop: PCodeProperty;
begin
  prop := current^.block;
  if prop^.isConst then
  begin
    if (prop^.expr) <> '' then
        addCompileExpr(prop^.expr)^.toStack := true
    else
      begin
        ErrPool.newError(errSyntax, Format(MSG_ERR_CONST_NOVAL,[prop^.name]), current^.line);
        exit;
      end;

    with addOpcode(OP_CLASS_CONST, true)^ do
    begin
        oper1.Mem.ptr := prop; //<-----------------
    end;
  end else begin
    if (prop^.expr) <> '' then begin
        addCompileExpr(prop^.expr)^.toStack := true;
        prop^.expr := '1';
    end;

    with addOpcode(OP_CLASS_PROPERTY, true)^ do
    begin
        oper1.Mem.ptr := prop; //<-----------------
    end;
  end;
end;

procedure TOriCompiler.addCompileContinue;
begin
  addOpcode(OP_CYCLE_CONTINUE);
end;

procedure TOriCompiler.addCompileDo;
begin
   addOpcode(OP_DO);
end;


procedure TOriCompiler.addCompileWhile;
  var
  i: integer;
  c: POpcodeLine;
begin
  addOpcode(OP_WHILE);
  i := Opcode.Count - 1;
  if i = -1 then i := 0;

  c := addOpcode(OP_NOP);
  addCompileExpr(current^.val);
  addOpcode(OP_IF)^.cnt := i;
  if (Self.next = nil) or ((Self.next <> nil) and (Self.next^.token_typ <> opBSKo)) then
  addOpcode(OP_NOP); // резервирование дл€ do-while цикла под OP_JMP

  i := Opcode.Count - 1;
  if i = -1 then i := 0;
  c^.cnt := i;
end;

procedure TOriCompiler.addLexBlock;
  var
  {len,} cnt, x: integer;
  ln: POpcodeLine;
  anext, aprev, acurrent: POpcodeLine;
begin
  //len := Length(opcode);
  cI := 0;
  x := -1;
  self.inClass := false;
  while (cI < opcode.Count) do
  begin
        acurrent := opcode[cI];
        if cI < opcode.Count - 1 then anext := opcode[cI+1] else anext := nil;
        if cI <> 0 then aprev := opcode[cI-1] else aprev := nil;

        x := High(FBreakes);
        if x > -1 then
        begin
            if cI > opcode[FBreakes[x]]^.cnt then
            begin
                popBreak;
                x := -1;
            end;
        end;

        if acurrent^.typ = OP_SKC then
        begin
              cnt := acurrent^.cnt;
              ln := opcode[cnt];
              if cnt <> 0 then
              begin
                  with opcode[cnt-1]^ do
                  begin
                      if (typ = OP_IF) and (cnt <> -1) then begin // встретили цикл while
                          inc(ln^.cnt,1);
                          if cnt = 0 then
                             acurrent^.cnt := 0
                          else
                             acurrent^.cnt := cnt+2;


                          acurrent^.typ := OP_JMP;
                          ln^.typ := OP_JMP;
                      end;
                  end;
              end;
        end else if acurrent^.typ = OP_WHILE then
        begin
             pushBreak(opcode[cI+1]^.cnt+1);
        end else if acurrent^.typ = OP_DO then
        begin
            if opcode[anext^.cnt+2]^.cnt = -1 then
            begin
                ErrPool.newError(errSyntax,MSG_ERR_DO,acurrent^.line);
                clearSource;
                exit;
            end;

            opcode[opcode[anext^.cnt+2]^.cnt]^.typ := OP_NOP;
            ln      := opcode[opcode[anext^.cnt+2]^.cnt-1];
            ln^.typ := OP_JMPZ_N;
            ln^.cnt := cI;
        end else if acurrent^.typ = OP_FOREACH then
        begin

            acurrent^.cnt := anext^.cnt;
            anext^.typ := OP_NOP;
            opcode[anext^.cnt]^.typ := OP_JMP;
            dec(opcode[anext^.cnt]^.cnt);


        end else if acurrent^.typ = OP_FOR then
        begin
            ln := opcode[anext^.cnt]; // конец цикла } должны заменить на jmp
            ln^.typ := OP_JMP;

            pushBreak(cI+1);

            with opcode[acurrent^.cnt+1]^ do
            begin
                typ := OP_JMP;
                cnt := anext^.cnt+1;
            end;

            ln^.cnt := opcode[acurrent^.cnt]^.cnt;
            with opcode[opcode[acurrent^.cnt]^.cnt-1]^ do
            begin
                typ := OP_JMP;
                cnt := anext^.cnt+1;
            end;
        end else if acurrent^.typ = OP_DEFINE_FUNC then
        begin
            if anext = nil then
               // new error
            else
                begin
                      anext^.typ := OP_NOP;
                      acurrent^.cnt := anext^.cnt;
                      if anext^.cnt = -1 then
                      begin
                        ErrPool.newError(errSyntax, MSG_ERR_INCOR_FUNC, acurrent^.line);
                        clearSource;
                        exit;
                      end;
                      
                      opcode[anext^.cnt]^.typ := OP_UNDEFINE_FUNC;
                      
                      if (moduleName <> '') and (not inClass) then
                      begin
                          with PCodeFunction(acurrent^.oper1.Mem.ptr)^ do
                          begin
                              if name <> '' then
                                  name   := moduleName +defNamespace+ name;
                          end;
                      end;

                      if inClass then
                      if PCodeFunction(acurrent^.oper1.Mem.ptr)^.name <> '' then
                      begin
                        acurrent^.typ := OP_DEF_METHOD;
                        //dec(acurrent^.cnt,3);
                      end;

                      opcode[anext^.cnt]^.toStack := PCodeFunction(acurrent^.oper1.Mem.ptr)^.assign <> '';
                end;
        end else if acurrent^.typ = OP_DEF_CLASS then
        begin
            if anext = nil then
                // new error
            else
              begin
                   inClass := true;
                   anext^.typ := OP_NOP;
                   acurrent^.cnt := anext^.cnt;
                   opcode[anext^.cnt]^.typ := OP_UNDEF_CLASS;
                   if moduleName <> '' then
                   begin
                       with acurrent^.oper1 do
                        Mem.str := moduleName +defNamespace+ Mem.str;
                   end;
              end;
        end else if acurrent^.typ = OP_UNDEF_CLASS then begin

                   inClass := false;

        end else if acurrent^.typ = OP_MODULE then
        begin
                   moduleName := acurrent^.oper1.Mem.str;
                   if anext <> nil then
                   if anext^.typ = OP_SKO then
                   begin
                      opcode[anext^.cnt]^.typ := OP_UNMODULE;
                   end;
        end else if acurrent^.typ = OP_UNMODULE then
        begin
            moduleName := '';
        end else if acurrent^.typ = OP_CLASS_CONST then
        begin
            if not inClass then
            if moduleName <> '' then
               with PCodeProperty(acurrent^.oper1.Mem.ptr)^ do
                name := moduleName + defNamespace + name;

        end else if acurrent^.typ in [OP_CYCLE_BREAK,OP_CYCLE_CONTINUE] then
        begin
            if x > -1 then
            begin
              acurrent^.cnt := opcode[FBreakes[x]]^.cnt;
              if acurrent^.typ = OP_CYCLE_BREAK then
                  inc(acurrent^.cnt,1);
                  
              acurrent^.typ := OP_JMP;
            end else
              begin
                  ErrPool.newError(errSyntax,MSG_ERR_BREAK,acurrent^.line);
                  clearSource;
                  exit;
              end;
        end;

        inc(cI);
  end;
end;

procedure TOriCompiler.addIfElse;
  var
  ln: POpcodeLine;
  anext, aprev, acurrent: POpcodeLine;
begin
  cI := 0;
  while (cI < opcode.Count) do
  begin
        acurrent := opcode[cI];
        if cI < opcode.Count - 1 then anext := opcode[cI+1] else anext := nil;
        if cI <> 0 then aprev := opcode[cI-1] else aprev := nil;

        if (acurrent^.typ = OP_SKC) then
        begin

            if (anext = nil) then
            begin
                 if acurrent^.cnt > 0 then
                 if opcode[acurrent^.cnt-1]^.typ in [OP_IF, OP_ELSEIF] then
                 begin
                    ln := opcode[acurrent^.cnt];
                    ln^.typ := OP_JMP;
                    inc(ln^.cnt);
                    acurrent^.typ := OP_NOP;
                    inc(cI); continue;
                 end;
            end;

        end;

        if acurrent^.typ = OP_ELSE then
        begin
             if (aprev <> nil) and (aprev^.typ = OP_SKC) then
             begin
                    ln  := opcode[aprev^.cnt];
                    ln^.cnt := cI+1;
                    ln^.typ := OP_JMP;

                    if anext = nil then
                    begin
                        ErrPool.newError(errSyntax,MSG_ERR_ELSE,acurrent^.line);
                        clearSource;
                        exit;
                    end;

                    aprev^.cnt := anext^.cnt+1;
                    aprev^.typ := OP_JMP;
                    inc(cI); continue;
             end else
             begin
                  ErrPool.newError(errSyntax,MSG_ERR_ELSE,acurrent^.line);
                  clearSource;
                  exit;
                  // ошибка...
             end;
        end else if acurrent^.typ = OP_ELSEIF then
        begin
             if (opcode[acurrent^.cnt] <> nil) and (opcode[acurrent^.cnt]^.typ = OP_SKC) then
             begin
                    acurrent^.typ := OP_IF;
                    aprev := opcode[acurrent^.cnt];

                    ln  := opcode[aprev^.cnt];
                    ln^.cnt := acurrent^.cnt+1;
                    ln^.typ := OP_JMP;

                    aprev^.cnt := anext^.cnt;
                    aprev^.typ := OP_JMP;
                    acurrent^.cnt := -1;
                    inc(cI); continue;
             end else
             begin
                  // ошибка...
             end;
        end;

        inc(cI);
  end;
end;

function TOriCompiler.addOpcode(typ: byte; const create_oper1: boolean = false): POpcodeLine;
begin
     New(Result);
     Result^.typ := typ;
     Result^.toStack := true;
     Result^.checkMemory := false;

     if create_oper1 then
     begin
        Result^.oper1 := TOriMemory.Create;
     end else
        Result^.oper1 := nil;
        Result^.oper2 := nil;

     Result^.line := current^.line;

     Opcode.Add(Result);
     Result^.cnt := -1;
     Result^.id  := -1;
     Result^.ptr := nil;
     Result^.line := curLine;
     //opLine := Result;
end;

function TOriCompiler.checkSyntaxExpr(ncode: TOpcodeArray): Boolean;
   var
   stackLen: Integer;
   i: integer;
begin
   stackLen := 0;
   for i := 0 to ncode.Count - 1 do
   begin
        if ncode[i]^.typ in sOP_PUSH then
        begin
            inc(stackLen);
        end else if ncode[i]^.typ in sOP_CALL_EX then
        begin
            dec(stackLen,ncode[i]^.cnt-1);
            if (ncode[i]^.oper2 <> nil) and (ncode[i]^.oper1.typ <> mvtWord) then
              dec(stackLen);
            if (ncode[i]^.oper1 = nil) and not (ncode[i]^.typ in [OP_GET_HASH,OP_NEW_ARRAY]) then
              dec(stackLen);
        end else if ncode[i]^.typ in sOP_UN_OPER then
        begin
            if stackLen < 1 then
            begin
                Result := false;
                exit;
            end;
            // на место 1го приходит 1
        end else if ncode[i]^.typ in sOP_BIN_OPER then
        begin
            if stackLen < 2 then
            begin
                Result := false;
                exit;
            end;
            dec(stackLen); // на место 2х приходит 1
        end;
   end;

   Result := (stackLen < 2) and (stackLen >= 0);   
end;

procedure TOriCompiler.clearSource;
begin
   discardOpcodeS(Self.opcode);
   Finalize(FBreakes);
   moduleName := '';
   Self.stackGetHash.Clear;
   AddCloneHash := false;
end;


procedure TOriCompiler.compile(source: TPtrArray; dest: TOpcodeArray);
begin
  Self.clearSource;
  Self.compile(source);
  dest := Self.opcode;
end;

procedure TOriCompiler.compile(source: TPtrArray);
  var
  len: integer;
begin
  clearSource;
  len := source.Count;
  cI := 0;
  while (cI < len) do
  begin
        current := source.Values^[cI];
        curLine := current^.line;
        if cI < len-1 then next := source.Values^[cI+1] else next := nil;
        if cI <> 0 then prev := source.Values^[cI-1] else prev := nil;

        case current^.typ of
          ctExpr     : addCompileExpr(current^.val);
          ctToken    : addCompileToken(current^.token_typ);
          ctIf       : addCompileIf();
          ctElseif   : addCompileElseif();
          ctElse     : addCompileElse();
          ctWhile    : addCompileWhile();
          ctDo       : addCompileDo();
          ctFor      : addCompileFor();
          ctForeach  : addCompileForeach();
          ctFunction : addCompileFunction();
          ctModule   : addCompileModule();
          ctReturn   : addCompileReturn();
          ctBreak    : addCompileBreak();
          ctContinue : addCompileContinue();
          ctClass    : addCompileClass();
          ctProperty : addCompileProperty();
          ctUse      : addCompileUse();
        end;

      lastLine := curLine;
      inc(cI);
      if ErrPool.errorExists([errSyntax,errParse]) then
      begin
          clearSource;
           Exit;
      end;

  end;

  if ErrPool.errorExists([errSyntax,errParse]) then
  begin
          clearSource;
          Exit;
  end;

  indexTokens(opcode);

  addLexBlock();
  addIfElse();

  optimizeShort;
  optimizeJump;
  optimizeClear; // очищение от лишних конструкций...
  fixJumpInFunc;
end;


constructor TOriCompiler.create(const initOpcode: boolean = true);
begin
  if initOpcode then
  begin
    Opcode := TOpcodeArray.Create;
  end else
    opcode := nil;

    __FILE__ := '';
    ErrPool := mr_getErrPool;
    FTokens := TArrayToken.Create;
    FTokens2:= TArrayToken.Create;
    stackGetHash := TPtrArray.Create;
end;

destructor TOriCompiler.destroy;
begin
  if Opcode <> nil then
      Opcode.Free;
  ErrPool.isUse := false;
  FTokens.Free;
  FTokens2.Free;
  stackGetHash.Free;
end;

procedure TOriCompiler.fixJumpInFunc;
   var
   i: integer;
   shStack: array[0..31] of Cardinal;
   shI: Integer;
begin
  shI    := -1;
  for i := 0 to Opcode.Count - 1 do
  begin
      with opcode[i]^ do
        case typ of
          OP_DEFINE_FUNC, OP_DEF_METHOD: begin
              if shI <> -1 then
              cnt := cnt - shStack[shI];

              inc(shI);
              shStack[shI] := i+1;
          end;
          OP_UNDEFINE_FUNC: begin
              shStack[shI] := 0;
              dec(shI);
              toStack := false;
          end;
          else begin
                  if shI <> -1 then
                  if opcode[i]^.typ in sOP_JUMP then
                  begin
                    Dec(opcode[i]^.cnt, shStack[shI]);
                   // cnt := cnt - shStack[shI];
                  end;
          end;

        end;
  end;
end;

procedure TOriCompiler.optimizeClear;
   var
   ncode: TOpcodeArray;
   jumps: TOpcodeArray;
   i,realLen,sh: integer;
   shStack: array of cardinal;
begin

  ncode := TOpcodeArray.Create;
  jumps := TOpcodeArray.Create;

  ncode.SetLength( Opcode.Count );
  sh := 0;
  realLen := 0;
  SetLength(shStack, Opcode.Count);


  for i := 0 to Opcode.Count - 1 do
  begin
        shStack[i] := sh;
        if opcode[i]^.typ in sOP_NOP then
        begin
             inc(sh);
        end;

        if opcode[i]^.typ in sOP_JUMP then
        begin
             jumps.Add( opcode[i] );
        end;
  end;

  for i := 0 to Opcode.Count - 1 do
  begin
        if opcode[i]^.typ in sOP_NOP then
        begin
             discardOpcode(opcode[i]);
             continue;
        end;

        if opcode[i]^.typ in sOP_JUMP then
        begin

             if opcode[i]^.cnt >= Opcode.Count then
                dec(opcode[i]^.cnt, shStack [high(shStack)])
             else
                dec(opcode[i]^.cnt, shStack[opcode[i]^.cnt]);
             //correctJump(jumps,sh,i);
        end;

        inc(realLen);
        ncode[realLen-1] := opcode[i];
  end;
  Opcode.Free;
  jumps.Free;

  ncode.SetLength(realLen);
  Opcode := ncode;
end;

procedure TOriCompiler.optimizeJump;
   var
   i,j: integer;
begin

   for i := 0 to Opcode.Count - 1 do
   begin
        if opcode[i]^.typ in [OP_JMP,OP_JMP_D,OP_JMPZ,OP_JMPZ_N] then
        begin
            j := opcode[i]^.cnt;
            if j = -1 then
            begin
                ErrPool.newError(errSyntax,MSG_ERR_EXPR,opcode[i]^.line);
                clearSource;
                exit;
            end else
            while (j < Opcode.Count) and (opcode[j]^.typ in [OP_JMP,OP_JMP_D,OP_JMPZ,OP_JMPZ_N]) do
            begin
                j := opcode[j]^.cnt;
            end;
            opcode[i]^.cnt := j;
        end;
   end;
end;

procedure TOriCompiler.optimizeShort;
  var
  i: integer;
  anext, aprev, acurrent: POpcodeLine;
begin
  I := 0;
  while (I < Opcode.Count) do
  begin
        acurrent := Self.opcode[I];
        if I < Opcode.Count-1 then anext := opcode[I+1] else anext := nil;
        if I <> 0 then aprev := opcode[I-1] else aprev := nil;

        if acurrent^.typ = OP_BREAK then
        begin
            if aprev <> nil then
                aprev^.toStack := false;

        end else if acurrent^.typ = OP_IF then
        begin
           acurrent^.typ := OP_JMPZ;
           acurrent^.cnt := anext^.cnt;
           anext^.typ := OP_NOP;
        end else if acurrent^.typ = OP_IF_N then
        begin
           acurrent^.typ := OP_JMPZ_N;
           acurrent^.cnt := anext^.cnt;
           anext^.typ    := OP_NOP;
        end;

      inc(i);
  end;

end;

function TOriCompiler.popBreak: Integer;
begin
   if length(FBreakes) = 0 then
   begin
    Result := -1;
    ErrPool.newError(errSyntax,MSG_ERR_NOSKOBA, curLine);
    exit;
   end else begin
    Result := FBreakes[high(FBreakes)];
    SetLength(FBreakes,length(FBreakes)-1);
   end;
end;

procedure TOriCompiler.pushBreak(const X: Cardinal);
begin
  SetLength(FBreakes,length(FBreakes)+1);
  FBreakes[high(FBreakes)] := X;
end;

end.
