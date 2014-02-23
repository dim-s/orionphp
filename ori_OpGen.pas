unit ori_OpGen;

// модуль для генерации обратной польской записи
{$ifdef fpc} {$mode delphi} {$endif}
{$H+}

interface

uses
  Classes, SysUtils,

  ori_StrConsts,
  ori_StrUtils,
  ori_Types,
  ori_Errors,
  ori_FastArrays,
  ori_HashList;

  type
      TToken = record
          typ: byte;
          line: cardinal;
          prior: byte;
          val: MP_String;
          cnt: word;

          callFunc: boolean;
          func: Pointer;
      end;
  PToken = ^TToken;

  //TArrayToken = array of PToken;
  TArrayToken = TPtrArray;

  procedure safeString(const str: MP_String; tokens: TArrayToken);
  function polkaTokens(tokens: TArrayToken; res: TArrayToken; const ErrPool: TOriErrorPool): Byte;
  procedure clearTokens(Tokens: TArrayToken);


  var
    HASH_TOKENS: THashList;
    SEPARATOR_TOKENS: THashList;


implementation

  uses ori_Parser;

   const
    sSET_PREV_OPERS = [opASKo,opBSKo,opSKo,opBreak,opAssign,opParamZ,opHashValue,opIn,
                       opPlus,opMinus,opMod,opMul,opXor,opShl,opShr,
                       opNot,opNotEq,opEq,opMin,opMax,opBitNot,opBitAnd,opBitOr];
                       
    sUNAR_PREV_OPERS = [opSKo,opASKo,opBSKo, opPlus, opMinus, opMul, opDiv, opMod,
                      opAssign,opAnd,opOr,opNot,opConstant,opXor,opBitNot,opBitAnd,opBitOr,
                      opShl,opShr,opLogicXor,
                      opEq,opEqTyp,opNotEq,opNoteqTyp,opMax,opMaxEq,opMin,opMinEq,
                      opMinusAssign,opPlusAssign,opMulAssign,opDivAssign,opConcatAssign,
                    opModAssign];

   var
    OPER_PRIOR: array[0..255] of byte =

    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  // 20

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  // 21..40

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  // 41..60

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  // 61..80

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 81..100

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 101..120

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 121

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 141

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 161

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 181

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 201

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 221

     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 241..255
    );

function getPrior(const opType: byte): Byte; inline; 
begin
  Result := OPER_PRIOR[opType];
end;

procedure InitPriorList;
begin
  OPER_PRIOR[opSKo] := 1; OPER_PRIOR[opASKo]:= 1; OPER_PRIOR[opBSKo]:= 1;
  OPER_PRIOR[opSKc] := 2; OPER_PRIOR[opASKc]:= 2; OPER_PRIOR[opBSKc]:= 2;

  OPER_PRIOR[opAnd] := 5; OPER_PRIOR[opOr] := 5; OPER_PRIOR[opLogicXor] := 5;

  OPER_PRIOR[opAssign] := 5; OPER_PRIOR[opPlusAssign] := 5;
  OPER_PRIOR[opMinusAssign] := 5; OPER_PRIOR[opMulAssign] := 5;
  OPER_PRIOR[opDivAssign] := 5; OPER_PRIOR[opModAssign] := 5;
  OPER_PRIOR[opXorAssign] := 5; OPER_PRIOR[opConcatAssign] := 5;

  OPER_PRIOR[opIn] := 7; OPER_PRIOR[opEq] := 7; OPER_PRIOR[opNotEq] := 7;
  OPER_PRIOR[opMax] := 7; OPER_PRIOR[opMaxEq] := 7; OPER_PRIOR[opMin] := 7;
  OPER_PRIOR[opMinEq] := 7; OPER_PRIOR[opEqTyp] := 7; OPER_PRIOR[opNotEqTyp] := 7;

  OPER_PRIOR[opConcat] := 8;
  OPER_PRIOR[opPlus] := 15; OPER_PRIOR[opMinus] := 15;
  OPER_PRIOR[opMul]  := 20; OPER_PRIOR[opDiv]   := 20;

  OPER_PRIOR[opXor]  := 25; OPER_PRIOR[opMod]   := 25;
  OPER_PRIOR[opShl]  := 25; OPER_PRIOR[opShr]   := 25;
  OPER_PRIOR[opBitAnd]:= 25; OPER_PRIOR[opBitOr]:= 25;

  OPER_PRIOR[opNot] := 80; OPER_PRIOR[opLink]:= 80; OPER_PRIOR[opBitNot]:= 80;
  OPER_PRIOR[opUnarMinus] := 81;

  OPER_PRIOR[opTypInteger] := 82; OPER_PRIOR[opTypDouble] := 82;
  OPER_PRIOR[opTypBoolean] := 82; OPER_PRIOR[opTypString] := 82;
  OPER_PRIOR[opTypArray]   := 82; OPER_PRIOR[opTypObject] := 82;

  OPER_PRIOR[opPlusPlus] := 90; OPER_PRIOR[opMinusMinus] := 90;
  OPER_PRIOR[opPlusPlus] := 90; OPER_PRIOR[opMinusMinus] := 90;
  OPER_PRIOR[opHashValue] := 8;

  OPER_PRIOR[opBreak] := 255; OPER_PRIOR[opParamZ] := 255;
end;

procedure InitLexList;
  const
    opExists = 190;
begin
  HASH_TOKENS := THashList.Create();
  SEPARATOR_TOKENS := THashList.Create();

  SEPARATOR_TOKENS.setValue('!',1);
  SEPARATOR_TOKENS.setValue('%',1);
  SEPARATOR_TOKENS.setValue('^',1);
  SEPARATOR_TOKENS.setValue('&',1);
  SEPARATOR_TOKENS.setValue('*',1);
  SEPARATOR_TOKENS.setValue('(',1);
  SEPARATOR_TOKENS.setValue(')',1);
  SEPARATOR_TOKENS.setValue('-',1);
  SEPARATOR_TOKENS.setValue('=',1);
  SEPARATOR_TOKENS.setValue('+',1);
  SEPARATOR_TOKENS.setValue('[',1);
  SEPARATOR_TOKENS.setValue(']',1);
  SEPARATOR_TOKENS.setValue('{',1);
  SEPARATOR_TOKENS.setValue('}',1);
  SEPARATOR_TOKENS.setValue(';',1);
  SEPARATOR_TOKENS.setValue('.',1);
  SEPARATOR_TOKENS.setValue('~',1);
  SEPARATOR_TOKENS.setValue('>',1);
  SEPARATOR_TOKENS.setValue('<',1);
  SEPARATOR_TOKENS.setValue(':',1);
  SEPARATOR_TOKENS.setValue(',',1);

  HASH_TOKENS.setValue(';', opBreak);
  HASH_TOKENS.setValue('(', opSKo);
  HASH_TOKENS.setValue(')', opSKc);
  HASH_TOKENS.setValue('[', opASKo);
  HASH_TOKENS.setValue(']', opASKc);
  HASH_TOKENS.setValue('{', opBSKo);
  HASH_TOKENS.setValue('}', opBSKc);

  HASH_TOKENS.setValue( defNew, opNew );
  HASH_TOKENS.setValue( defHashValue, opHashValue );
  HASH_TOKENS.setValue(  defConcat, opConcat );
  HASH_TOKENS.setValue(  defParamZ, opParamZ );
  HASH_TOKENS.setValue(  defXor, opXor );
  HASH_TOKENS.setValue(  defPlus, opPlus );
  HASH_TOKENS.setValue(  defMinus, opMinus );
  HASH_TOKENS.setValue(  defDiv, opDiv );
  HASH_TOKENS.setValue(  defMul, opMul );
  HASH_TOKENS.setValue(  defAnd, opAnd );
  HASH_TOKENS.setValue(  defMod, opMod );
  HASH_TOKENS.setValue(  defOr, opOr );
  HASH_TOKENS.setValue(  defShl, opShl );
  HASH_TOKENS.setValue(  defShr, opShr );
  HASH_TOKENS.setValue(  defNot, opNot );
  HASH_TOKENS.setValue(  defBitNot, opBitNot );
  HASH_TOKENS.setValue(  defBitAnd, opBitAnd );
  HASH_TOKENS.setValue(  defBitAnd2, opBitAnd );
  HASH_TOKENS.setValue(  defBitOr, opBitOr );
  HASH_TOKENS.setValue(  defBitOr2, opBitOr );
  HASH_TOKENS.setValue(  defExAnd, opAnd );
  HASH_TOKENS.setValue(  defExOr, opOr );
  HASH_TOKENS.setValue(  defLogicXor, opXor );
  HASH_TOKENS.setValue(  defIn, opIn );
  HASH_TOKENS.setValue(  defExNot, opNot );
  HASH_TOKENS.setValue(  defMax, opMax );
  HASH_TOKENS.setValue(  defMin, opMin );
  HASH_TOKENS.setValue(  defMaxEq, opMaxEq );
  HASH_TOKENS.setValue(  defMinEq, opMinEq );
  HASH_TOKENS.setValue(  defNotEq, opNotEq );
  HASH_TOKENS.setValue(  defNotEq2, opNotEq );
  HASH_TOKENS.setValue( defStatic, opCallStatic);

  HASH_TOKENS.setValue(  defEq, opEq );
  HASH_TOKENS.setValue(  defPris, opAssign );

  HASH_TOKENS.setValue(  defTypEq, opEqTyp );
  HASH_TOKENS.setValue(  defNotTypEq, opNoteqTyp );

  HASH_TOKENS.setValue(  defNull, opNull );
  HASH_TOKENS.setValue(  defTrue, opTrue );
  HASH_TOKENS.setValue(  defFalse, opFalse );


  HASH_TOKENS.setValue( defPlusPlus, opPlusPlus );
  HASH_TOKENS.setValue( defMinusMinus, opMinusMinus );
  HASH_TOKENS.setValue( defPlusAssign, opPlusAssign );
  HASH_TOKENS.setValue( defMinusAssign, opMinusAssign );
  HASH_TOKENS.setValue( defMulAssign, opMulAssign );
  HASH_TOKENS.setValue( defDivAssign, opDivAssign );
  HASH_TOKENS.setValue( defConcatAssign, opConcatAssign );
  HASH_TOKENS.setValue( defModAssign, opModAssign );
  HASH_TOKENS.setValue( defXorAssign, opXorAssign );
end;

procedure clearTokens(Tokens: TArrayToken);
  var
  i: integer;
begin
  for i := 0 to Tokens.Count - 1 do
  if Tokens.Values^[i] <> nil then
    Dispose(PToken(Tokens.Values^[i]));
end;


function token(const typ, prior: byte; const val: MP_String;
               const line: cardinal = 0; const cnt: integer = 0): PToken;
begin
  new(Result);
  Result^.typ := typ;
  Result^.prior := prior;
  Result^.val := val;
  Result^.line:= line;
  Result^.cnt := cnt;
  Result^.callFunc := false;
end;

function token2(const typ: byte; const val: MP_String;
               const line: cardinal = 0; const cnt: integer = 0): PToken;
begin
  new(Result);
  Result^.typ := typ;
  Result^.prior := getPrior(typ);
  Result^.val := val;
  Result^.line:= line;
  Result^.cnt := cnt;
  Result^.callFunc := false;
end;



function isTypeFuncCall(const opType: byte): Boolean;
begin
    Result := opType in [opCallFunc, opIf, opElseif, opWhile,
      opWhileDo, opSwitch, opInclude, opRequire,
      opDie, opNew, opReturn, opGlobal, opDefine, opCallHash, opCallStatic];
end;

// возвращает true, если функция может писаться без скобок
function isSpaceFunc(typ: Byte): boolean;
begin
    Result := typ in [opInclude,opRequire,opEcho,opGlobal,opReturn,
                      opIf,opElseif,opWhile,opWhileDo,opSwitch,opDie, opConstanT];
end;

// 0 - false, 1 - string, 2 - magic string
function is_string(const s: MP_String): byte;
begin
  Result := 0;
  if Length(s) < 2 then
      exit
  else begin
      if s[1] = '''' then
        Result := 1
      else if s[1] = '"' then
        Result := 2;
      // последняя кавычка должна быть по любому такая же
      // все равно анализатор проверяет на ошибки синтаксиса
  end;
end;

function is_space(const Ch: AnsiChar): Boolean; inline;
begin
    Result := Ch in [' ',#9,#13,#10,#0];
end;

function is_separator(const Ch: AnsiChar): Boolean; inline;
begin
    //Result := Pos(ch, '!%^&*()-=+[]{};.~><:') > 0;
    Result := Ch in ['!','%','^','&','*','/','(',')','-','=','+','[',
             ']','{','}',';','.','~','>','<',':',',','|'];
    //Result := SEPARATOR_TOKENS.ItemHasKey( HashTable_Func2(ch,1) );
end;

// возвращает тип токена, если он есть и он из 1 символа
// если 0 вернет, значит был не разделитель - ЭТО ВАЖНО!
function checkS1Token(const s,inst: MP_String; const i,len,instLen: integer): Integer;
begin
   Result := HASH_TOKENS.getHashValue(inst, instLen);

   if Result = opConcat then
   begin
       if (((i-1 <> 0) and (s[i-1] in ['0'..'9']))
                or (i-1 = 0))

                and

                (((i+1 <= len) and (s[i+1] in ['0'..'9']))
                or (i+1 > len))
              then
                  Result := 0
              else
                  Result := opConcat;
   end else
   if (Result = opMinus) and (s[i-1] in ['e','E']) then
      Result := 0;
end;

function checkInstToken(const S,Inst: MP_String; const i,len: integer): byte;
  var
  r: byte;
  lenInst: Integer;
begin
   lenInst := length(Inst);
   if lenInst > 0 then
   begin

   Result := HASH_TOKENS.getHashValueEx( Inst );
   if Result = 0 then
      Result := opWord;

    if lenInst > 1 then
    begin
      case Inst[1] of
          '$': Result := opVar;
          '@': Result := opGlobalVar;
      end;
    end;

     if (lenInst > 3) and (ori_StrLower(inst[1]+inst[2])='0x') then
      begin
        Result := opHexNumber;
      end;

      if Result = opWord then begin
      // проверяем на число
             case is_number(Inst) of
                  1: Result := opInteger;
                  2: Result := opDouble;
                  {else
                      Result := opString;}
             end;
      end;

   end else
      Result := 0;
end;

// функция определяет конкретный тип двойственных токенов
// например: "." - конкатенация, но в то же время - 2.3 - дробное число
// (-a+b): "-a" - минус унарный, для польской записи его надо перевести в иной символ
procedure safeString(const str: MP_String; tokens: TArrayToken);
   var
   len,line, lastI: cardinal;
   c,i: integer;
   ch,quoCh: mp_char;
   isStr: boolean;
   lastTyp: byte;
   s2: MP_String;
   //s3: MP_String;
   inst: MP_String;
   typ, ktyp, ltyp: byte;
   prev,item: PToken;
   lastCmt: Byte; // тип коммента 0 - нет коммента, 1 - //, 2 - #, 3 - /* */
   label 1,_continue;
begin

   quoCh := #0;
   lastTyp := 0;
   line  := 1;
   i := 0;
   inst := '';
   isStr := false;
   lastCmt := 0;
   tokens.Clear;

   len := Length(str);
   if len > 0 then
   while (true) do
   begin
       inc(i);
       if i > len+1 then
         break;

       ch := str[i];

       if ch = #13 then
          inc(line);

       if isQuote(str, i, quoCh) then
          begin
             isStr := not isStr;

             if isStr then
             begin
                quoCh := ch;
                lastI := i;
             end
                else begin
                   quoCh := #0;
                   inst := Copy(str,lastI+1,i-lastI-1);
                   // TODO: Fix, is no good ^_^
                   if ch = defQuote then
                   begin
                      ktyp := opString;
                      inst := StringReplace(inst, '\''', '''', [rfReplaceAll]);
                   end
                   else begin
                      ktyp := opMagicString;
                      inst := StringReplace(inst, '\n', #13, [rfReplaceAll]);
                      inst := StringReplace(inst, '\r', #10, [rfReplaceAll]);
                      inst := StringReplace(inst, '\"', '"', [rfReplaceAll]);
                   end;

                   tokens.Add(token(ktyp,0,inst,line));
                   inst := '';
                end;
             Continue;
       end;

       if isStr then continue;
       
       if is_space(ch) then
       begin
          typ := checkInstToken(str, inst, i, len);
          if typ > 0 then
            tokens.Add( token(typ, getPrior(typ), inst, line) );
            
          inst := '';
          continue;
       end else

       if is_separator(ch) then
       begin
          c := i;
          typ := 0;
          while is_separator(str[i+1]) do
          begin
              if i - c > 1 then break; 
              inc(i);
          end;

          case i - c of
              0: begin
                   lastTyp := checkS1Token(str, ch, i, len, 1);
                   if lastTyp > 0 then
                   begin
                       typ := checkInstToken(str, inst, i, len); if typ > 0 then tokens.Add(token2(typ, inst, line));

                       tokens.Add( token2(lastTyp, '', line) )
                   end else
                      goto _continue;
                 end;
              1: begin

                    lastTyp := checkS1Token(str, copy(str, c, i-c+1), i, len, 2);
                    if lastTyp = 0 then
                    begin
                        lastTyp := checkS1Token(str, ch, i-1, len, 1);
                        if lastTyp > 0 then begin
                           typ := checkInstToken(str, inst, i, len); if typ > 0 then tokens.Add(token2(typ, inst, line));
                           tokens.Add( token2(lastTyp, '', line) )
                        end else
                           goto _continue;
                           dec(i);

                    end else begin
                        typ := checkInstToken(str, inst, i, len); if typ > 0 then tokens.Add(token2(typ, inst, line));
                        
                        tokens.Add( token2(lastTyp, '', line) );
                    end;
                 end;
              2: begin

                  s2 := copy(str, c, i-c+1);
                  lastTyp := checkS1Token(str, s2, i, len, 3);
                  if lastTyp = 0 then
                  begin
                        lastTyp := checkS1Token(str, s2, i-1, len, 2);
                        if lastTyp > 0 then begin
                             typ := checkInstToken(str, inst, i, len); if typ > 0 then tokens.Add(token2(typ, inst, line));
                             tokens.Add( token2(lastTyp, '', line) );
                             dec(i,1);
                        end
                        else begin
                           lastTyp := checkS1Token(str, s2, i-2, len, 1);
                           if lastTyp > 0 then begin
                              typ := checkInstToken(str, inst, i, len); if typ > 0 then tokens.Add(token2(typ, inst, line));
                              tokens.Add( token2(lastTyp, '', line) );
                              dec(i,2);
                           end
                           else goto _continue;
                        end;
                        
                  end else begin
                      typ := checkInstToken(str, inst, i, len); if typ > 0 then tokens.Add(token2(typ, inst, line));
                      tokens.Add( token2(lastTyp, '', line) );
                  end;
              end;
          end;

          if lastTyp = opASKo then
          begin
            tokens.SetLength( tokens.Count + 1 );
            tokens.Values^[ tokens.Count - 1 ] := tokens.Values[ tokens.Count - 2 ];
            tokens.Values^[ tokens.Count - 2 ] := token2(opCallHash, inst, line) ;
          end;

          if typ > 0 then
              inst := '';
          continue;
       end;


       _continue:
       //if (not isStr and ((ch<>#13) and (ch<>#10) and (ch<>' '))) then
       inst := inst + ch;
   end;

   c := tokens.Count - 1;
   i := -1;
   while (true) do
   begin
        inc(i);
        if i > c then break;

        item := PToken(tokens.Values^[i]);
        if i > 0 then
            prev := PToken(tokens.Values^[i-1])
        else
            prev := nil;
            
        // fix bit and operator
        if item^.typ = opBitAnd then
        begin
           if (i = 0) or (prev^.typ in sUNAR_PREV_OPERS) then
           begin
                  item^.typ := opLink;
                  item^.prior := getPrior(opLink);
                  
           end;
        end else
        // fix unar minus
        if item^.typ = opMinus then
        begin
            if (i = 0) or (prev^.typ in sUNAR_PREV_OPERS) then
            begin
                      item^.typ := opUnarMinus;
                      item^.prior := getPrior(opUnarMinus);
            end;
        end else
        // fix array sets, example: $arr = [1,2,3,4];
        if item^.typ = opCallHash then
        begin
            if (i = 0) or (prev^.typ in sSET_PREV_OPERS) then
            begin
                      with item^ do begin
                        typ := opCallFunc;
                        val := defArray;
                        prior := getPrior(opCallFunc);
                        callFunc := true;
                      end;
            end;
        end else

        if (i > 0) then
            begin
              if (prev^.typ = opCallStatic) then
              begin
                 prev^.typ := opASKo;
                 prev^.prior := getPrior(opASKo);
                 prev^.val := '';
                 case item^.typ of
                  opWord: begin
                    item^.typ := opString;
                    item^.val := ori_StrLower(item^.val);
                    end;
                  opVar: begin
                    item^.typ := opClassVar;
                    Delete(item^.val,1,1);
                  end;
                 end;

                 if i > 1 then
                 begin
                    with PToken(tokens.Values^[i-2])^ do
                    if typ = opWord then
                    begin
                      typ := opString;
                      val := ori_StrLower(val);
                    end;
                 end;

                 tokens.Insert(i+1, token2( opASKc, '', item^.line ));

                 //token_Insert(tokens, token( opCallFunc, getPrior(opCallFunc), '', tokens[i]^.line ), i+2 );
                 tokens.Insert(i-1, token2( opCallStatic, '', item^.line ));
                 inc(c,2);
                 inc(i,2);
                 item := PToken( tokens.Values^[i] );

                //continue;
              end;
            end;

            
        // fix for support func call
        if (i <> c) then
        begin
        if item^.typ in [opWord,opVar,opASKc,opSKc] then
        begin

            // fix typed syntax: (int)$x
            if (i > 1) and (item^.typ = opSKc) then
            begin
                 if (prev^.typ = opWord) and (PToken(tokens.Values^[i-2])^.typ = opSKo) then
                 begin
                     with prev^ do begin
                        if val = defTypArray then
                            typ := opTypArray
                        else if (val = defTypInteger) or (val = defTypInt) then
                            typ := opTypInteger
                        else if (val = defTypBoolean) or (val = defTypBool) then
                            typ := opTypBoolean
                        else if (val = defTypString) then
                            typ := opTypString
                        else if (val = defTypDouble) then
                            typ := opTypDouble
                        else if (val = defTypObject) then
                            typ := opTypObject
                        else
                            goto 1;

                        with PToken(tokens.Values^[i-2])^ do
                        begin
                            typ   := opNone;
                            prior := 0;
                        end;

                        item^.typ   := opNone;
                        item^.prior := 0;

                        prev^.prior := getPrior(prev^.typ);
                        Continue;
                     end;

                 end;
            end;
            
            1:
            if (item^.typ = opWord) and (ori_Parser.getLexOpType(item^.val,2) > 0) then
            begin
                 item^.typ := opCallFunc;
                 item^.prior := getPrior(opCallFunc);
                 tokens.Insert(i+1, token( opSKo, getPrior(opSKo), '(', item^.line ));
                 inc(c); inc(i);

                 tokens.Add(token( opSKc, getPrior(opSKc), ')', item^.line ));
                 continue;
            end;

            if (PToken(tokens.Values^[i+1])^.typ = opSKo) then
            if (i = 0) or ((i <> 0) and (not (prev^.typ in [opFunc]))) then
            begin
                if item^.typ <> opWord then
                begin
                    tokens.Insert(i+1, token( opCallFunc, getPrior(opCallFunc), '', item^.line ));
                    inc(c); inc(i);
                end else begin
                    item^.typ  := opCallFunc;
                    item^.prior := getPrior(opCallFunc);
                end;
            end;
        end;


        end;
   end;
end;



function polkaTokens(tokens: TArrayToken; res: TArrayToken; const ErrPool: TOriErrorPool): Byte;
   var
   stackBr: array of byte; // стек для скобок,
   stackPrCount: array of integer; // стек для кол-ва параметров
   // в стеке хранится тип последней открывающей скобки
   // он необходим, надо учитывать вложенность скобок
   stack: TArrayToken; // стек для операторов, т.е. токенов с приоритем > 0
   i, len, j, k: integer;
   prior,topPrior, typ,skTyp: byte;
   skCh: MP_Char;
   tk,nextTk,prevTk: PToken;
   label _exit;
begin
   result := 0; // no err
   res.Clear;

   len := tokens.Count;
   if len = 0 then exit;

   SetLength(stackPrCount,0);
   stack := TArrayToken.Create;

   for i := 0 to len - 1 do
   begin
        tk := tokens.Values^[i];
        
        prior := tk^.prior;
        typ := tk^.typ;
        //if typ = 0 then continue;
        

        if i <> 0 then prevTk := tokens.Values^[i-1]
        else           prevTk := nil;

        if i <> len-1 then nextTk := tokens.Values^[i+1]
        else           nextTk := nil;

        // слово без приоритета
        if prior = 0 then
        begin
            if not isTypeFuncCall(tk^.typ) then
              res.Add(tk);
            continue;
        end else
        begin

           // встретилась открывающая скобка
           if typ in [opSKo, opASKo, opBSKo] then
           begin
                if prevTk <> nil then
                if isTypeFuncCall(prevTk^.typ) then
                begin
                    tk^.callFunc := true;
                    tk^.func     := prevTk;
                    SetLength(stackPrCount, length(stackPrCount)+1);
                    stackPrCount[High(stackPrCount)] := 0;
                end;

                SetLength(stackBr, length(stackBr)+1);
                stackBr[high(stackBr)] := typ;

                stack.Add(tk);
                res.Add(tk);
                
                Continue;
           end else
           // встретилась закрывающая скобка, идем на съедение
           if typ in [opSKc, opASKc, opBSKc] then
           begin
                if length(stackBr) = 0 then
                begin
                  Result := 1;
                   ErrPool.newError(errSyntax,MSG_ERR_EXPR, tk^.line);
                  exit;
                end else
                  skTyp := stackBr[high(stackBr)];
                  k     := 0;
                if prevTk^.typ in [opSKo,opASKo] then
                begin
                  if length(stackPrCount) = 0 then
                  begin
                      ErrPool.newError(errParse, MSG_ERR_SKOBA);
                      Result := 1;
                      goto _exit;
                  end
                  else
                    dec(stackPrCount[High(stackPrCount)]);
                end;

                for j := stack.Count - 1 downto 0 do
                begin
                      if stack.Values^[j] = nil then continue;

                      if PToken(stack.Values^[j])^.typ = skTyp then
                      begin

                          with PToken(stack.Values^[j])^ do
                          begin
                          if stack.Values^[j] <> nil then
                            if (callFunc) then // подобии функций
                            begin
                                callFunc := false;
                                cnt := stackPrCount[high(stackPrCount)] + 1;
                                PToken(func)^.cnt := cnt;

                                res.Add(func);
                                SetLength(stackPrCount,length(stackPrCount)-1);
                            end;
                          end;

                          // else
                            stack.Pop;

                          break;
                      end;
                      inc(k);
                      res.Add(stack.Values^[j]);
                end;

                if tk^.typ = opBSKc then
                  res.Add(tk);

                SetLength(stackBr,length(stackBr)-1);

                //SetLength(stack, length(stack)-k); // +1 открывающая скобка
                stack.SetLength(stack.Count - k);
            //    end;

           end else
           if typ = opParamZ then
           begin
                k     := 0;
                if stack.Count = 0 then begin
                    ErrPool.newError(errSyntax, MSG_ERR_PARAMZ);
                    Result := 1;
                    goto _exit;
                end;

                inc(stackPrCount[ high(stackPrCount) ]);
                for j := stack.Count - 1 downto 0 do
                begin
                      if stack.Values^[j] = nil then continue;

                      if PToken(stack.Values^[j])^.typ in [opSKo, opASKo, opBSKo] then
                          break;

                        inc(k);
                        res.Add(stack.Values^[j]);
                        
                      if j = 0 then
                      begin
                         // ошибочка...
                         ErrPool.newError(errSyntax, MSG_ERR_PARAMZ);
                         Result := 2;
                         goto _exit;
                      end;
                end;
                res.Add(tk);

                stack.SetLength(stack.Count - k);
                // SetLength(stack, length(stack)-k); // +1 не надо, т.к. скобка нам еще нужна будет

           end else
           {if typ = opAssign then begin

                addToken2(stack, tk);
           end else}
           if typ = opBreak then
           begin
                  if stack.Count > 0 then
                    for j := stack.Count - 1 downto 0 do
                    begin
                      if stack.Values^[j] = nil then continue;

                      if not (PToken(stack.Values^[j])^.typ in [opSKo,opASKo,opBSKo]) then
                        res.Add(stack.Values^[j]);
                  end;

                  res.Add(tk);
                  stack.Clear;
           end else
           begin

                if stack.Count > 0 then
                begin
                topPrior := PToken(stack.Values^[stack.Count - 1])^.prior;

                if (topPrior > prior) then
                begin
                     for j := stack.Count - 1 downto 0 do
                     begin
                           if stack.Values^[j] = nil then continue;

                           if PToken(stack.Values^[j])^.prior >= prior then
                           begin
                                if not (PToken(stack.Values^[j])^.typ in [opSKo,opASKo,opBSKo]) then
                                begin
                                  res.Add(stack.Values^[j]);
                                  //addToken2(res,stack[j]);
                                  stack.Values^[j] := nil;
                                end else
                                  break;
                           end else
                              Break;
                     end;
                end;
                end;

                stack.Add(tk);
                if isSpaceFunc(typ) then
                begin
                  if i+1 < len then
                  if nextTk^.typ <> opSKo then
                     res.Add(token(opSKo,getPrior(opSKo),'(',tk^.line));
                     //addToken2(res, token(opSKo,getPrior(opSKo),'(',tk^.line));
                end;
           end;

        end;
   end;

   if stack.Count > 0 then
   for i := stack.Count - 1 downto 0 do
   begin
        if stack.Values^[i] = nil then continue;

        if not (PToken(stack.Values[i])^.typ in [opSKo,opASKo,opBSKo]) then
        begin
            res.Add(stack.Values^[i]);
        end else begin
           if PToken(stack.Values^[i])^.callFunc then
           begin
            
            PToken(PToken(stack.Values^[i])^.func)^.cnt := stackPrCount[high(stackPrCount)] + 1;
            res.Add(PToken(stack.Values^[i])^.func);
            //addtoken2(res, PToken(stack.Values^[i])^.func);
            SetLength(stackPrCount,length(stackPrCount)-1);
           end;
        end;
   end;

   if length(stackBr) > 0 then
   begin
      ErrPool.newError(errParse, MSG_ERR_NOSKOBA);
      Result := 1;
      goto _exit;
   end;

   _exit:
      stack.Free;
end;


initialization
  InitLexList;
  InitPriorList;

end.

