unit ori_Parser;

{$ifdef fpc}
  {$mode delphi}
{$endif}

{$H+}
{$i './VM/ori_Options.inc'}

interface

uses
  Classes, SysUtils,

  ori_Types,
  ori_StrUtils,
  ori_StrConsts,
  ori_Stack,
  ori_Errors,
  ori_FastArrays,
  ori_Hash32,
  ori_vmMemory;


  const
       useMagicString = true;
       varNameRegister = true;

  const
       defClass = 'class';
       defNew   = 'new';         
       defFunc  = 'function';
       defMethod= 'function';
       defExtends = 'extends';
       defSelf  = 'self';
       defParent = 'parent';

       defClassStatic    = 'static';
       defClassPublic    = 'public';
       defClassConst     = 'const';
       defClassVar       = 'var';
       defClassPrivate   = 'private';
       defClassProtected = 'protected';

       {$IFDEF NAMESPACE_PHP_STYLE}
       defNamespace = '\';
       {$ELSE}
       defNamespace = ':';
       {$ENDIF}

       defStatic  = '::';
       defDynamic = '->';
       defHashValue = '=>';
       defConcat  = '.';
       defParamZ  = ',';
       defXor     = '^';
       defPlus    = '+';
       defMinus   = '-';
       defDiv     = '/';
       defMul     = '*';
       defBegin   = '{';
       defEnd     = '}';
       defBreak   = ';';
       defAnd     = '&&';
       defOr      = '||';
       defShl     = '<<';
       defShr     = '>>';
       defNot     = '!';
       defBitNot  = '~';
       defBitOr   = '|';
       defBitOr2  = 'bor';
       defBitAnd  = '&';
       defBitAnd2  = 'band';
       defMod     = '%';
       defExAnd   = 'and';
       defExOr    = 'or';
       defLogicXor= 'xor';
       defIn      = 'in';
       defExNot   = 'not';
       defMax     = '>';
       defMin     = '<';
       defMaxEq   = '>=';
       defMinEq   = '<=';
       defNotEq   = '!=';
       defNotEq2  = '<>';
       defEq      = '==';
       defPris    = '=';

       defTypEq   = '===';
       defNotTypEq= '!==';

       defPlusPlus= '++';
       defMinusMinus = '--';
       defPlusAssign = '+=';
       defMinusAssign = '-=';
       defMulAssign = '*=';
       defDivAssign = '/=';
       defConcatAssign = '.=';
       defModAssign = '%=';
       defXorAssign = '^=';

       defNull   = 'null';
       defTrue   = 'true';
       defFalse  = 'false';
       defEcho   = 'echo';
       defPrint  = 'print';
       defGlobal = 'global';
       defUnset  = 'unset';
       defVStatic= 'static';
       defInclude= 'include';
       defIncludeOnce='include_once';
       defRequire= 'require';
       defRequireOnce = 'require_once';
       defReturn = 'return';
       defExit   = 'exit';
       defArray  = 'array';
       defDie    = 'die';
       defDefine = 'define';

       {$IFDEF NAMESPACE_PHP_STYLE}
       defModule = 'namespace';
       defConstModule = '__NAMESPACE__';
       {$ELSE}
       defModule = 'module';
       defConstModule = '__MODULE__';
       {$ENDIF}

       defUse = 'use';

       defCycleBreak = 'break';
       defCycleContinue = 'continue';

       defIf     = 'if';
       defSwitch = 'switch';
       defCase   = 'case';
       defElse   = 'else';
       defElseif = 'elseif';
       defFor    = 'for';
       defForeach= 'foreach';
       defAs     = 'as';
       defTo     = 'to';
       defWhile  = 'while';
       defDo     = 'do';
       defWhiledo= 'while';

       defTypString  = 'string';
       defTypInteger = 'integer';
       defTypInt     = 'int';
       defTypBoolean = 'boolean';
       defTypBool    = 'bool';
       defTypArray   = 'array';
       defTypDouble  = 'double';
       defTypObject  = 'object';

       defPreFILE = '__FILE__';
       defPreDIR  = '__DIR__';
       defPreLINE = '__LINE__';
       defPreCLASS= '__CLASS__';
       defPreFUNCTION = '__FUNCTION__';
       defPreMETHOD = '__METHOD__';

  const
       /// op-code type
       opNone   = 0;
       opSpace  = 254;
       opFunc   = 1;
       opClass  = 2;
       opVar    = 3;
       opHash   = 4; // [..]
       opMethod = 5;
       opGlobalVar = 6;
       opStaticVar = 7;
       opClassVar  = 8;
       opGlobal    = 9;
       opStatic    = 10;
       opPublic    = 53;
       opInclude   = 11;
       opRequire   = 12;
       opReturn    = 13;
       opExit      = 14;
       opEcho      = 15;
       opDie       = 16;
       opBegin     = 17;
       opEnd       = 18;
       opIf        = 19;
       opElse      = 20;
       opElseif    = 21;
       opWhile     = 22;
       opDo        = 23;
       opWhileDo   = 24;
       opFor       = 25;
       opForeach   = 26; // foreach ($arr as $key=>$value)

       opString    = 27; // 'mystr'
       opMagicString = 28; // "$d + $c"
       opBoolean   = 29; // 5
       opCallHash     = 30; // ]
       opCallStatic = 31; // ::method()
       opCallStaticConstant = 32;  // ::CONSTANT
       opConstant = 33; // CONSTANT
       opCallMethod = 34; // ->method()
       opCallFunc = 35; // func()
       opArray = 36; // array( ... )
       opNew   = 37;

       opPlus = 38;  // +
       opMinus = 39; // -
       opDiv  = 40; // /
       opMul  = 41; // *
       opAnd  = 42; // &&
       opOr   = 43; // ||
       opNot  = 44; // !
       opXor  = 52; // ^

       opMax  = 45; // >
       opMin  = 46; // <
       opMaxEq= 47; // >=
       opMinEq= 48; // <=
       opNotEq= 49; // !=
       opEq   = 50; // ==
       opAssign = 51; // =

       // 54
       opNull = 54;
       opCycleBreak = 55;  // break
       opCycleContinue = 56;   // continue

       opSKo  = 57;  // (
       opSKc  = 58; // )
       opASKo = 59; // [
       opASKc = 60; // ]
       opBSKo = 61; // {
       opBSKc = 62; // }

       opUnarMinus = 63;
       opMod = 64;

       opEqTyp   = 65; // ===
       opNoteqTyp = 66; // ===

       opPlusAssign = 67; // +=
       opMinusAssign = 68; // -=
       opMulAssign  = 69; // *=
       opDivAssign  = 70; // /=
       opConcatAssign = 71; // .=
       opModAssign = 72; // %=
       opXorAssign = 73; // ^=
       opPlusPlus  = 74; // $a++
       opMinusMinus = 75; // $b--
       opConcat = 76; // .

       opLink = 77; // &$x

       opPrivate = 78;
       opProtected = 79;
       opCallPublic = 80;
       opAs = 81; // as
       opForDynamic = 82; // =>

       opTypInteger = 83;
       opTypDouble  = 84;
       opTypBoolean = 85;
       opTypString  = 86;
       opTypArray   = 87;
       opTypObject  = 88;
       opTrue = 89;
       opFalse = 90;

       opInteger = 91;
       opDouble  = 92;

       opWord = 93; // просто строка токена, без типа
       opLocaleVar = 94; // локальная переменная
       opParamZ = 95; // ,

       opSwitch = 96;
       opCase   = 97;
       opLinkWord = 98;

       opCallFuncVar = 99;
       opAssignLink = 100;

       opDefine = 101;

       opIn = 102;
       opHashValue = 103;

       opLogicXor = 104;
       opBitNot   = 105;

       opShl = 106;
       opShr = 107;
       opBitAnd = 108;
       opBitOr  = 109;
       opHexNumber = 110;

       // задание кол-во параметров одному оп-коду
       opParamCount = 200; // ???
       opBreak = 255;  // ;

  type
      TOriMethod_type = (omtNative,omtUser,omtProp,omtConst);
      TOriMethod_modifer = (ommSuperPublic, ommPrivate, ommProtected, ommPublic);

  type
        TVMConstant = record
              typ : MVT_Type;
              str: MP_String;
              modifer: TOriMethod_modifer;
              case longint of
                1: (lval: MP_Int);
                2: (dval: MP_Float);
                3: (bval: Boolean);
              end;
        TArrayVMConstant = array of TVMConstant;

  type
      TCodeType = (ctToken, ctExpr, ctIf, ctElseif, ctElse, ctFor, ctWhile, ctWhiledo,
                    ctDo, ctForeach, ctSwitch, ctCase, ctFunction, ctClass, ctModule,
                    ctReturn,ctBreak,ctContinue, ctGlobal,
                    ctProperty, ctUse);

      TLine = record
            line: cardinal; // реальный номер строки в исходниках
            str: MP_String; // само выражение
            strQ: MP_String;
      end;
      
  const
      sCodeBlockSet = [ctIf, ctElseif, ctElse, ctFor, ctWhile, ctWhiledo, ctDo, ctForeach];


  type
      TCodeBlock = record
          line: cardinal;
          typ: TCodeType;
          token_typ: byte;
          val: MP_String;
          param: MP_String;
          block: Pointer; // = nil
      end;
      
  PCodeBlock = ^TCodeBlock;
  TArrayCode = array of PCodeBlock;


  type
      TCodeFor = record         // for (

          param : MP_ArrayString; // $i = 0
          cond  : MP_String;       // $i < 1000
          iter  : MP_ArrayString; // $i++
      end;
      PCodeFor = ^TCodeFor;

      TCodeForeach = record // foreach (
          param : MP_String; // expr, push array
          key   : MP_String; // $key
          value : MP_String; // $value
          value_link: boolean; // is &$value
      end;
      PCodeForeach = ^TCodeForeach;


      TCodeFunction = record
          modifer: TOriMethod_modifer; // 0 none, 1 private, 2 protected, 3 public
          isStatic: boolean; // +static
          name: AnsiString;
          assign: MP_String;
          vars: MP_ArrayString;
          vars_link: array of boolean;
          defs: TArrayVMConstant;
          eval: TArrayCode;
      end;
      PCodeFunction = ^TCodeFunction;

      TCodeProperty = record
          modifer: TOriMethod_modifer; // 0 none, 1 private, 2 protected, 3 public
          isStatic: boolean; // +static
          isConst : boolean;
          expr: MP_String;
          name: AnsiString;
      end;
      PCodeProperty = ^TCodeProperty;

      TCodeClass = record
          name: AnsiString;
          parent_class: AnsiString;
      end;
      PCodeClass = ^TCodeClass;


 TOriParser = class(TObject)
   protected
       moduleName: MP_String;
       
       startConst: boolean;
       startConstPrefix: MP_String;

       function createFor(const Line: Cardinal; const StrQ: MP_String): PCodeBlock;
       function createWhile(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
       function createForeach(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
       function createFunction(const Line: Cardinal; const Str,StrQ: MP_String; const isAssign: boolean): PCodeBlock;
       function createClass(const Line: Cardinal; const Str: MP_String): PCodeBlock;
       function createProperty(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;

       function createIf(const Line: Cardinal; const StrQ: MP_String): PCodeBlock;
       function createElseif(const Line: Cardinal; const StrQ: MP_String): PCodeBlock;

       function createModule(const Line: Cardinal; const Str: MP_String): PCodeBlock;
       function createUse(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
       function createReturn(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
       function createBreak(const Line: Cardinal): PCodeBlock;
       function createContinue(const Line: Cardinal): PCodeBlock;

       function createGlobal(const Line: Cardinal; const Str: MP_String): PCodeBlock;
       function createUnset(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;

       function createExpr(const Line: Cardinal; const StrQ: MP_String): PCodeBlock;


       function checkLexWord(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
       function checkToken(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;


       procedure AddBlock(const Line: Cardinal; const Str,StrQ: MP_String);
   public
       isUse: Boolean;
       blocks: TPtrArray;
       ErrPool: TOriErrorPool;
       procedure clearBlocks();
       procedure Parse(const src: MP_String);
       procedure fixShortBlock();

       constructor Create();
       destructor Destroy(); override;
 end;

  function validVarName(const s: MP_String): Boolean;
  function validFuncName(const s: MP_String): Boolean;

  function getLexOpType(word: MP_String; typ: byte = 0): Byte;

implementation

  uses ori_ManRes, ori_vmConstants;

function validVarName(const s: MP_String): Boolean;
  var
  i: integer;
begin
   Result := false;
   for i := 1 to length(s) do
      if Pos(s[i], varName) = 0 then  exit;
   Result := true;
end;

function validFuncName(const s: MP_String): Boolean;
  var
  i: integer;
begin
   Result := false;
   for i := 1 to length(s) do
      if Pos(s[i], funcName) = 0 then  exit;
   Result := true;
end;

function isStrictLex(const word: MP_String): Boolean;
begin
       if defFunc = word then Result := true
       else if defMethod = word then Result := true
       else if defIf = word then Result := true
       else if defElseif = word then Result := true
       else if defFor = word then Result := true
       else if defForeach = word then Result := true
       else if defWhile = word then Result := true
       else
         Result := false;
end;

function isPropertyLex(const word: MP_String): Boolean;
begin
      if defClassStatic = word then Result := true
      else if defClassPublic = word then Result := true
      else if defClassConst = word then Result := true
      else if defClassVar = word then Result := true
      else if defClassPrivate = word then Result := true
      else if defClassProtected = word then Result := true
      else
          Result := false;
end;

// typ: 0 - all, 1 - with (), 2 - without - ()
function getLexOpType(word: MP_String; typ: byte = 0): Byte;
begin
  Result := 0;
  word   := LowerCase(word);

  if (typ = 0) or (typ = 2) then
  begin
     if defClass = word then Result := opClass;
     if defNew = word then Result := opNew;
     if defClassStatic = word then Result := opStatic;
     if defClassPublic = word then Result := opPublic;
     if defClassVar = word then Result := opClassVar;
     if defReturn = word then Result := opReturn;
     if defCycleBreak = word then Result := opCycleBreak;
     if defCycleContinue = word then Result := opCycleContinue;
     if defElse = word then Result := opElse;
     if defDo = word then Result := opDo;
     if defNull = word then Result := opNull;
     if defExAnd = word then Result := opAnd;
     if defExOr = word then Result := opOr;
     if defEcho = word then Result := opEcho;
     if defPrint = word then Result := opEcho;
     if defUnset = word then Result := 1;
     //if defGlobal = word then Result := opGlobal;
     if defInclude = word then Result := opInclude;
     if defRequire = word then Result := opRequire;
     if defIncludeOnce = word then Result := opInclude;
     if defRequireOnce = word then Result := opRequire;
    { if defExAnd = word then Result := opAnd;
     if defExOr = word then Result := opOr; }
  end;

  if (typ = 0) or (typ = 1) then
  begin
       if defFunc = word then Result := opFunc;
       if defMethod = word then Result := opMethod;
       if defVStatic = word then Result := opStatic;
       if defInclude = word then Result := opInclude;
       if defRequire = word then Result := opRequire;
       if defIncludeOnce = word then Result := opInclude;
       if defRequireOnce = word then Result := opRequire;
       if defExit = word then Result := opExit;
       if defArray = word then Result := opArray;
       if defDie = word then Result := opDie;
       if defIf = word then Result := opIf;
       if defElseif = word then Result := opElseif;
       if defFor = word then Result := opFor;
       if defForeach = word then Result := opForeach;
       if defWhile = word then Result := opWhile;
       if defFunc = word then Result := opFunc;
  end;
end;

procedure getBreak(const src: MP_String; var inst: MP_String; const i: integer; var LineX: TLine);
  var
  ch: MP_Char;
  xFunc: String[30];
  p: integer;
begin
  ch := src[i];
  LineX.Line := 1;

    if ch = defBegin then
        LineX.Str := defBegin
    else if ch = defEnd then
        LineX.Str := defEnd
    else if ch = defBreak then
        LineX.Str := defBreak
    else if ch = ' ' then
    begin
        xFunc := copy(inst,length(inst)-length(defElse)-1,length(defElse));
        if (xFunc <> defElse) or (trim(inst) = defElseif) then
        begin
            xFunc := copy(inst,length(inst)-1,2);
            if xFunc <> defDo then
              LineX.line := 0
            else
              LineX.Str  := ''
        end
        else
            LineX.Str := '';
    end
    else if ch = ')' then
    begin
        p := Pos('(', inst);
        if p = 0 then
            LineX.Line := 0
        else begin
            xFunc := Trim( Copy(inst,1,p-1) );
            LineX.Str  := '';
            LineX.StrQ := '';

            if not isStrictLex(xFunc) then
                LineX.line := 0
            else
                inst := inst + ch;
        end;

    end else
        LineX.Line := 0;
end;

function TOriParser.checkLexWord(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
   var
   xFunc: MP_String;
   p: integer;
begin

   if Pos('(', Str) > 0 then
   begin
   xFunc := Trim( CopyL(Str,'(') );

        if xFunc = defFor  then
            Result := Self.createFor(Line, StrQ)
        else if xFunc = defForeach then
            Result := Self.createForeach(Line, Str,StrQ)
        else if xFunc = defWhile then
            Result := Self.createWhile(Line, Str,StrQ)
        else if xFunc = defIf then
            Result := self.createIf(Line, StrQ)
        else if xFunc = defElseif then
            Result := self.createElseif(Line, StrQ)
        else if xFunc = defUnset then
            Result := self.createUnset(Line, Str,StrQ)
        else if Pos(defReturn+' ', Str) = 1 then
            Result := createReturn(Line, Str,StrQ)
        else if xFunc = defReturn then
            Result := createReturn(Line, Str,StrQ)
        else if Pos(defGlobal+' ', Str) = 1 then
            Result := createGlobal(Line, Str)
        else if (Pos(' ',xFunc)>0) and (getLexOpType(xFunc,2) > 0) then
        begin
            if xFunc = defUnset then begin
                Result := createUnset(Line, Str,xFunc+'('+CopyR(StrQ,' ')+')');
            end               
            else
                Result := createExpr(Line, xFunc+'('+CopyR(StrQ,' ')+')');
        end
        else begin
            p := PosR(defFunc+' ', xFunc);
            if p > 0 then
            begin
                if p = 1 then
                begin
                  Result := self.createFunction(Line, Str,StrQ, false)
                end else if p = length(xFunc)-length(defFunc)+1 then
                  Result := self.createFunction(Line, Str,StrQ, true)
                else
                  Result := self.createFunction(Line, Str,StrQ, true);
            end
            else begin
              p := PosR(defFunc, xFunc);
              if (p > 0) and (p = length(xFunc)-length(defFunc)+1) then
                Result := self.createFunction(Line, Str,StrQ, true)
              else
                Result := nil;
            end;
        end;
   end else
   begin
      if Pos(' ',Str) > 0 then
        xFunc := CopyL(Str,' ')
      else
        xFunc := Str;

      if xFunc = defReturn then
         Result := createReturn(Line, Str,StrQ)
      else if xFunc = defGlobal then
         Result := createGlobal(Line, Str)
      else if xFunc = defUnset then
      begin
         Result := createUnset(Line, Str,xFunc + '(' + CopyR(StrQ,' ')+')')
      end
      else if xFunc = defClass then
         Result := createClass(Line, Str)
      else if xFunc = defModule then
         Result := createModule(Line, Str)
      else if xFunc = defCycleBreak then
         Result := createBreak(Line)
      else if xFunc = defCycleContinue then
         Result := createContinue(Line)
      else if xFunc = defUse then
         Result := createUse(Line, Str,StrQ)
      else if isPropertyLex(xFunc) then
         Result := createProperty(Line, Str,StrQ)
      else
          Result := nil;
   end;
end;

// компиляция строк в блоки кодов
function TOriParser.checkToken(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
   Var
   aStr,aStrQ: MP_String;
begin

     {if StrQ = '' then
     begin
        Result := nil;
        exit;
     end;}

     new(Result);

     if Str = ';' then
     begin
         Result^.token_typ := opBreak;
         Result^.typ       := ctToken;
     end else if Str = '{' then
     begin
         Result^.token_typ := opBSKo;
         Result^.typ       := ctToken;
     end else if Str = '}' then
     begin
         Result^.token_typ := opBSKc;
         Result^.typ       := ctToken;
         Self.startConst := false;
     end else begin
          aStr := trim(Str);
          if aStr = defElse then
              Result^.typ := ctElse
          else if aStr = defDo then
              Result^.typ := ctDo
          else begin
              if Self.startConst then
              begin
                aStr := Self.startConstPrefix +' '+ Str;
                aStrQ := Self.startConstPrefix +' '+ StrQ;
                Dispose(Result);
                Result := createProperty(Line, aStr,aStrQ);
                exit;
              end else begin
                Result^.typ := ctExpr;
                Result^.val := StrQ;
              end;
          end;
     end;
     Result^.block := nil;
     Result^.line  := Line;
end;

procedure TOriParser.clearBlocks;
  var
  i,len: cardinal;
  b: PCodeBlock;
begin
  self.startConst := false;
  len := Blocks.Count;
  if len > 0 then
  for i := 0 to len - 1 do
    begin
        b := PCodeBlock( blocks.Values^[i] );
        if not (b^.typ in [ctToken,ctExpr]) then
        begin
             case b^.typ of
                  ctFunction: Dispose(PCodeFunction(b^.block));
                  ctProperty: Dispose(PCodeProperty(b^.block));
                  ctClass:    Dispose(PCodeClass(b^.block));
                  ctFor:      Dispose(PCodeFor(b^.block));
                  ctForeach:  Dispose(PCodeForeach(b^.block));
                  else
                     if b^.block <> nil then
                        Dispose(PCodeBlock(b^.block));
             end;

        end;
        Dispose(b);
    end;
 blocks.Clear;
end;

procedure TOriParser.fixShortBlock;
   type
      TCodeState = record
         openBlock: Word;
         prevBlock: Boolean;
         skC: Word;
   end;
   procedure insertElement( var A: TArrayCode; Index: integer;
                                       ANew: PCodeBlock );
    var Len : integer;
    begin
      Len:= Length( A );

      if Index >= Len-1 then
      begin
          SetLength(A, Len+1);
          A[Len] := ANew;
          exit;
      end;

        setLength( A, Len+1);
        move( A[Index], A[ Index+1 ],
         (Len-Index) * sizeof( A[Index] ));
      A[Index] := ANew;
    end;

   function isToken(item: PCodeBlock; const x: Integer): boolean; inline;
   begin
       Result :=  (item^.typ = ctToken) and (item^.token_typ = x);
   end;

   function blockToken(const x: integer): PCodeBlock; inline;
   begin
      New(Result);
      with Result^ do begin typ := ctToken; token_typ := x; end;
   end;

   procedure resetState(var state: TCodeState); inline;
   begin
      with state do
      begin
          openBlock := 0;
          skC       := 0;
          prevBlock := false;
      end;
   end;

   var
   i,h: integer;
   item: PCodeBlock;
   sI: Byte;
   state: array[0..127] of TCodeState;
   s: string;
   label do_continue;
begin
   sI := 0;
   resetState(state[sI]);

   h := blocks.Count - 1;
   i := -1;

   while True do
   begin
        Inc(i);
        if i > h then break;
        
        item := PCodeBlock(blocks.Values^[i]);

        if state[sI].prevBlock then
        begin
          if not isToken(item, opBSKo) then
          begin
               blocks.Insert(i, blockToken(opBSKo) );
               Inc(state[sI].openBlock);
               inc(h);
               goto do_continue;
          end else
               begin
                  if sI <> 127 then inc(sI);

                  resetState(state[sI]);
                  state[sI].skC := 1;
               end;
        end else
        begin
            if (item^.typ = ctToken) then
            begin
               if item^.token_typ = opBSKo then inc(state[sI].skC)
               else if item^.token_typ = opBSKc then
               begin
                 dec(state[sI].skC);
                 if state[sI].skC = 0 then
                    if sI <> 0 then dec(sI);
               end;
            end;
        end;

        if item^.typ in sCodeBlockSet then
        begin
             if not (
                (item^.typ = ctWhile)
                and
                ((i = h-1) or ((i < h-1) and isToken(PCodeBlock(blocks.Values^[i+1]), opBreak)))
                )
                then begin

                    state[sI].prevBlock := true;
                    Continue;
                end;
        end;

        if state[sI].openBlock > 0 then
        begin
            if (i < h-1) and ( isToken(PCodeBlock(blocks.Values^[i+1]), opBreak) ) then
                blocks.Insert(i+2, blockToken(opBSKc))
                //insertElement(blocks, i+2, blockToken(opBSKc) )
            else  
                blocks.Insert(i+1, blockToken(opBSKc));
                //insertElement(blocks, i+1, blockToken(opBSKc) );

            dec(state[sI].openBlock);
            inc(h); inc(i);
        end;

      do_continue:
        state[sI].prevBlock := false;
   end;

   with state[sI] do
   begin
      if openBlock > 0 then
      begin
        //SetLength(blocks, h+openBlock+1);
        blocks.SetLength(h + openBlock + 1);
        for i:=0 to openBlock-1 do
        begin
              blocks.Values^[h+i+1] := blockToken(opBSKc);
        end;
      end;
   end;

   (*
$i = 0;
for($i=0;$i<3;$i++)
  for($j=0;$j<3;$j++){

      while ($x<10)
        for($y=0;$y<3;$y++)
           echo $x;
     $d = '222';
  }

echo $i;

   for i := 0 to blocks.Count - 1 do
   begin
      item := blocks.Values^[ i ];
      if (item^.typ = ctToken) then
      begin
               if item^.token_typ = opBSKo then s := s + '{' + #13
               else if item^.token_typ = opBSKc then s := s + '}' + #13;
      end else if item^.typ = ctForeach then
          s := s + 'foreach' + #13
      else if item^.typ = ctWhile then
          s := s + 'while' + #13
      else if item^.typ = ctFor then
          s := s + 'for' + #13
      else if item^.typ = ctDo then
          s := s + 'do' + #13
      else
      s := s + item^.val + #13;
   end;
   raise Exception.Create(s);   *)
end;


procedure TOriParser.AddBlock(const Line: Cardinal; const Str,StrQ: MP_String);
   var
   b: PCodeBlock;
begin
    b := checkLexWord( Line, Str,StrQ );
    if b = nil then
       b := checkToken( Line, Str,StrQ );

    if b <> nil then
    Blocks.Add(b);
end;


constructor TOriParser.Create;
begin
 ErrPool := mr_getErrPool;
 blocks  := TPtrArray.Create;
 startConst := false;
end;

function TOriParser.createBreak(const Line: Cardinal): PCodeBlock;
begin
    New( Result ); Result^.line := Line;
    Result^.typ   := ctBreak;
    Result^.block := nil;
end;

function TOriParser.createClass(const Line: Cardinal; const Str: MP_String): PCodeBlock;
   var
   cl: PCodeClass;
   S: MP_String;
begin
   New(Result);
   New(cl);
   Result^.block := cl;
   Result^.typ   := ctClass;
   Result^.line := Line;

   if Pos(defExtends, Str) > 0 then
   begin
      S := StrStr(Str, defExtends);
      cl^.name := Trim(Copy(Str, length(defClass)+1,
            length(Str)-(length(s)+length(defClass))-1));
      cl^.parent_class := Trim(Cut(S, 1, length(defExtends)));
   end else begin
      cl^.name := Trim(Cut(Str, 1, length(defClass)));
      cl^.parent_class := '';
   end;
end;

function TOriParser.createContinue(const Line: Cardinal): PCodeBlock;
begin
    New( Result ); Result^.line := Line;
    Result^.typ   := ctContinue;
    Result^.block := nil;
end;

function TOriParser.createElseif(const Line: Cardinal; const StrQ: MP_String): PCodeBlock;
begin
    New( Result ); Result^.line := Line;
    Result^.typ  := ctElseif;

    Result^.val := copy(StrQ,length(defElseif)+2,length(StrQ)-(length(defElseif)+2));

    if Trim(Result^.val) = '' then
        ErrPool.newError(errSyntax, MSG_ERR_COND, Line);

    Result^.block := nil;
end;

function TOriParser.createExpr(const Line: Cardinal; const StrQ: MP_String): PCodeBlock;
begin
    new(Result);
    Result^.typ := ctExpr;
    Result^.val := StrQ;
    Result^.block := nil;
    Result^.line  := Line;
end;

function TOriParser.createFor(const Line: Cardinal; const StrQ: MP_String): PCodeBlock;
  var
  cFor: PCodeFor;
  S,V: MP_String;
  prms: MP_ArrayString;
  p: Integer;
  label 1;
begin
    New( Result );
    Result^.line := Line;
    Result^.typ  := ctFor;
    New(cFor);
    Result^.block := Pointer(cFor);

    ori_StrUtils.GetParamStr( copy(StrQ,length(defFor)+2,length(StrQ)-(length(defFor)+2)), prms, ';');

    case Length(prms) of
      1: begin
          S := prms[0];
          p := Pos(' '+defTo+' ',S);
          if p > 0 then
          begin
              SetLength(prms, 3);
              prms[0] := CopyL(S,' '+defTo+' ');
              V := Trim(CopyL(prms[0],'='));
              if V = '' then begin
                V := prms[0];
                prms[0] := '';
              end;

              prms[1] := V + defMinEq + CopyR(S, ' '+defTo+' ');
              prms[2] := V + defPlusPlus;
          end else
           goto 1;
      end;
      3: ;

      else begin
        1:
        ErrPool.newError(errSyntax, MSG_ERR_FORPRMS, Line);
        exit;
      end;
    end;

    ori_StrUtils.GetParamStr(prms[0], cFor^.param, ',');
    ori_StrUtils.GetParamStr(prms[2], cFor^.iter, ',');
    cFor^.cond := prms[1];
end;

function TOriParser.createForeach(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
  var
  cFor: PCodeForeach;
  prms: MP_ArrayString;
  s: MP_String;
  p: Integer;
begin
    New( Result );
    Result^.line := Line;
    Result^.typ  := ctForeach;
    New(cFor);

    Result^.block := Pointer(cFor);

    S := copy(StrQ,length(defForeach)+2,length(StrQ)-(length(defForeach)+2));
    ori_StrUtils.GetParamStr( S, prms, ' ');

    cFor^.param := prms[0];
    if (prms[1] <> defAs) or (Length(prms) < 3) then
    begin
        ErrPool.newError(errSyntax, MSG_ERR_FOREACH, Line);
        exit;
    end;

    p := Pos(defHashValue,prms[2]);
    if p = 0 then begin
       cFor^.value := Trim(prms[2]);
       cFor^.key   := '';
    end else begin
       cFor^.key := Copy(prms[2],1,p-1);
       cFor^.value := Cut(prms[2],1,p+1);
    end;

    cFor^.value_link := cFor^.value[1] = '&';
    if cFor^.value_link then
      Delete(cFor^.value,1,1);

    if not validVarName(cFor^.key) or not validVarName(cFor^.value) then
    begin
        ErrPool.newError(errSyntax, MSG_ERR_FOREACH, Line);
        exit;
    end;
    Delete(cFor^.key,1,1);
    Delete(cFor^.value,1,1);
end;

function TOriParser.createFunction(const Line: Cardinal; const Str,StrQ: MP_String; const isAssign: boolean): PCodeBlock;
   var
   f: PCodeFunction;
   p,i: integer;
   prms,pr: MP_ArrayString;
   s: MP_String;
   aStrQ,aStr: MP_String;
   label do_err;
begin
    new(f);
    New( Result ); Result^.line := Line;
    Result^.typ := ctFunction;

    Result^.block := f;
    f^.isStatic := false;
    f^.modifer  := ommSuperPublic;

    if isAssign then
    begin
        f^.assign := CopyL(StrQ, '=');
        aStrQ := TrimLeft(CopyR(StrQ, '='));
    end else begin
        f^.assign := '';
        aStrQ := StrQ;
    end;

    p := Pos(defFunc, aStrQ);
    if p <> 1 then
    begin
        S := Trim(Copy(aStrQ,1,p-1));
        aStrQ := Cut(aStrQ,1,p-1);
        ori_explode(' ', S, prms);
        case length(prms) of
          1: begin

             if prms[0] = defClassStatic then f^.isStatic := true
             else if prms[0] = defClassPrivate then f^.modifer := ommPrivate
             else if prms[0] = defClassProtected then f^.modifer := ommProtected
             else if prms[0] = defClassPublic then f^.modifer := ommPublic
             else
                ErrPool.newError(errSyntax,
                      format(MSG_ERR_FUNC_MODIFER_F,[prms[0]]), Line);

             end;
          2: begin
               if prms[0] = defClassStatic then f^.isStatic := true
               else
                ErrPool.newError(errSyntax,
                      format(MSG_ERR_FUNC_MODIFER_F,[prms[0]]), Line);

               if prms[1] = defClassPrivate then f^.modifer := ommPrivate
               else if prms[1] = defClassProtected then f^.modifer := ommProtected
               else if prms[1] = defClassPublic then f^.modifer := ommPublic
               else
                 ErrPool.newError(errSyntax,
                      format(MSG_ERR_FUNC_MODIFER_F,[prms[1]]), Line);
             end;
          3:  ;
        end;

    end;

    Delete(aStrQ, 1, length(defFunc));
    aStrQ := Trim(aStrQ);
    p := Pos('(', aStrQ );
    if p = 1 then
      f^.name := ''
    else begin
      f^.name := (copy(aStrQ,1,p-1));
      Delete(aStrQ, 1, length(f^.name));
    end;

    Delete(aStrQ,1,1); Delete(aStrQ,length(aStrQ),1);
    f^.name := ori_StrLower(f^.name);
    // узнаем параметры функции
    if aStrQ <> '' then
    begin
        ori_StrUtils.GetParamStr(aStrQ, prms, ',');
        SetLength(f^.vars, length(prms));
        SetLength(f^.vars_link, length(prms));
        for i := 0 to high(prms) do
        begin             
             ori_StrUtils.GetParamStr(prms[i], pr, '=');
             if length(pr) = 0 then goto do_err;

             f^.vars[i] := Trim(pr[0]);

             if Pos('&',f^.vars[i]) > 0 then
             begin
                Delete(f^.vars[i],1,1);
                
                if not validVarName(f^.vars[i]) then goto do_err;

                Delete(f^.vars[i],1,1);
                f^.vars_link[i] := true;
             end else
             begin
                if not validVarName(f^.vars[i]) then goto do_err;

                Delete(f^.vars[i],1,1);
                f^.vars_link[i] := false;
             end;

             if length(pr) = 2 then begin
                SetLength(f^.defs, length(f^.defs)+1);

                with f^.defs[ high(f^.defs) ] do
                begin
                  pr[1] := (FastStringReplace(Trim(pr[1]),' ','',[rfReplaceAll]));
                  p := is_number(pr[1]);
                  case p of
                    1: begin typ := mvtInteger; lval := StrToInt(pr[1]); end;
                    2: begin typ := mvtDouble; dval := StrToFloatDef(pr[1],0); end;
                    3: goto do_err;
                    0: begin
                           pr[1] := ori_StrLower(pr[1]);
                           if pr[1] = defNull then
                              typ := mvtNull
                           else if pr[1] = defTrue then
                           begin
                              typ := mvtBoolean;
                              bval := true;
                           end else if pr[1] = defFalse then
                           begin
                              typ  := mvtBoolean;
                              bval := false;
                           end else if pr[1] = defArray+'('+')' then
                           begin
                              typ  := mvtHash;
                           end else begin

                              str  := pr[1];
                              if str[1] in [defQuote,defMQuote] then
                              begin
                                 typ  := mvtString;
                                 Delete(str,1,1);
                                 if length(str) = 0 then goto do_err;
                                 Delete(str,length(str),1);
                              end else
                              begin
                                 typ  := mvtWord;
                              end;
                           end;
                       end;
                  end;
                end;

             end;
        end;
    end else begin
      setLength(f^.vars, 0);
      SetLength(f^.defs, 0);
    end;

    //SetLength(f.eval, 0);
    exit;
    do_err:
      ErrPool.newError(errParse, Format(MSG_ERR_PARAMFUNC,[f^.name]), Line);
      clearBlocks;
      Exit;
end;

function TOriParser.createGlobal(const Line: Cardinal; const Str: MP_String): PCodeBlock;
   var
   vars: MP_ArrayString;
   i,h: integer;
   aStrQ: MP_String;
begin
   GetParamStr(CopyR(Str,' '),vars);
   aStrQ := defGlobal + '(';
   h := high(vars);
   for i := 0 to h do
   begin
        aStrQ := aStrQ + ''''+ ori_StrLower( Copy(vars[i],2,length(vars[i])-1) )+'''';
        if i <> h then
            aStrQ := aStrQ + ',';
   end;
   Result := createExpr(Line,aStrQ+')');
end;

function TOriParser.createIf(const Line: Cardinal; const StrQ: MP_String): PCodeBlock;
begin
    New( Result ); Result^.line := Line;
    Result^.typ  := ctIf;

    Result^.val := copy(StrQ,length(defIf)+2,length(StrQ)-(length(defIf)+2));

    if Trim(Result^.val) = '' then
        ErrPool.newError(errSyntax, MSG_ERR_COND, Line);

    Result^.block := nil;
end;

function TOriParser.createModule(const Line: Cardinal; const Str: MP_String): PCodeBlock;
begin
  moduleName := LowerCase( Trim( CopyR(Str,' ') ) );
  New(Result);
  Result^.block := nil;
  Result^.val := moduleName;
  Result^.typ := ctModule;
  Result^.line := Line;
end;

function TOriParser.createProperty(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
  var
  prop: PCodeProperty;
  prms: MP_ArrayString;
  h: integer;
  noPris: Boolean;
  label 1;
begin
  New(Result);
  New(prop);

  Result^.line  := Line;
  Result^.block := prop;
  Result^.typ   := ctProperty;

  // if assign value exists
  if Pos(defPris, Str) > 0 then
  begin
      noPris := false;
      prop^.expr := CopyR(StrQ,'=');
      ori_explode(' ', Trim(CopyL(Str,'=')), prms);
  end else begin
      prop^.expr := '';
      ori_explode(' ', Str, prms);
      noPris := true;
  end;

  h := high(prms);
  prop^.isStatic := false;
  prop^.isConst  := false;
  prop^.modifer  := ommSuperPublic;
  case h of
    1: begin
       if prms[0] = defClassStatic then prop^.isStatic := true
       else if prms[0] = defClassPrivate then prop^.modifer := ommPrivate
       else if prms[0] = defClassProtected then prop^.modifer := ommProtected
       else if prms[0] = defClassConst then prop^.isConst := true
       else prop^.modifer := ommPublic;

       prop^.name := prms[1];
    end;
    2: begin
       if (prms[0] = defClassStatic) or (prms[1] = defClassStatic) then prop^.isStatic := true;
       if (prms[0] = defClassPrivate) or (prms[1] = defClassPrivate) then prop^.modifer := ommPrivate;
       if (prms[0] = defClassProtected) or (prms[1] = defClassProtected) then prop^.modifer := ommProtected;
       if (prms[0] = defClassConst) or (prms[1] = defClassConst) then prop^.isConst := true;

       prop^.name := prms[2];
    end;
    0: begin
        if prms[0] = defClassConst then
        begin
            1:
            Self.startConst := true;
            Self.startConstPrefix := Str;
            Result^.token_typ := opBreak;
            Result^.typ       := ctToken;
            Result^.block     := nil;
            Dispose(prop);
            exit;
        end;
    end;
  end;

  if noPris and (h = 1) and (prop^.expr = '') and ((prms[0]=defClassConst) or (prms[1]=defClassConst)) then
  begin
       goto 1;
  end;
  

  if not prop^.isConst then
      Delete(prop^.name,1,1);

  prop^.name := ori_StrLower(prop^.name);  
end;

function TOriParser.createReturn(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
begin
    New( Result );
    Result^.line := Line;
    Result^.typ  := ctReturn;

    Result^.val := CopyR(StrQ,defReturn);

    Result^.block := nil;
end;

function TOriParser.createUnset(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
   var
   vars: MP_ArrayString;
   i,h: integer;
   aStr,aStrQ: MP_String;
begin
   aStrQ := StrQ;
   Delete(aStrQ,1,Length(defUnset)+1);
   Delete(aStrQ,length(aStrQ),1);
   GetParamStr(aStrQ,vars);
   h := high(vars);
   aStr := '';
   for i := 0 to h do
   begin
        if validVarName(vars[i]) then
            aStr := aStr + ''''+ ori_StrLower(vars[i])+''''
        else
            aStr := aStr + ori_StrLower(vars[i]);
        if i <> h then
            aStr := aStr + ',';
   end;
   Result := createExpr(Line,defUnset+'('+aStr+')');
end;

function TOriParser.createUse(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
  var
  vars: MP_ArrayString;
  block: PCodeBlock;
begin
  New( Result );
  Result^.line := Line;
  Result^.typ  := ctUse;
  Result^.block := nil;

  ori_explode(' ', FastStringReplace(Str,'  ',' ',[rfReplaceAll]), vars);
  if (length(vars)<4) or (vars[2] <> defAs) then
  begin
      ErrPool.newError(errParse, MSG_ERR_NOSKOBA);
      exit;
  end;

  Result^.val := LowerCase(vars[1]);
  Result^.param := LowerCase(vars[3]);
end;

function TOriParser.createWhile(const Line: Cardinal; const Str,StrQ: MP_String): PCodeBlock;
begin
    New( Result );
    Result^.line := Line;
    Result^.typ  := ctWhile;

    // 'while('
    Result^.val := copy(StrQ,length(defWhile)+2,length(StrQ)-(length(defWhile)+2));

    if Trim(Result^.val) = '' then
        Result^.val := defTrue;

    Result^.block := nil;
end;

destructor TOriParser.Destroy;
begin
  clearBlocks;
  ErrPool.isUse := false;
  blocks.Free;
end;


procedure TOriParser.Parse(const src: MP_String);
   var
   len, i, line: cardinal;
   inst, instQ: MP_String;
   isStr: boolean;
   ch: MP_Char;
   lineX: TLine;
   quoCh: MP_char;
   quoLine: Cardinal;
   skO: integer; // кол-во открытых скобок
   lastCmt: Byte; // тип коммента 0 - нет коммента, 1 - //, 2 - #, 3 - /* */
begin
   clearBlocks;
   ErrPool.clearErrors;
   
   isStr := false;
   len   := Length(src);
   i     := 0;
   line  := 1;
   lastCmt := 0;

   quoCh := #0;
   skO := 0;
   quoLine := 1;
   
   i := 0;
   while (true) do begin
       inc(i);
       if i > len then
         break;
         
       ch := src[i];
       if not isStr then
          ch := LowCase(ch);

       if ch = #13 then
          inc(line);

       if not isStr then
       if lastCmt > 0 then
       begin
           if ((ch = #13) or (ch = #10)) and (lastCmt in [1,2]) then
           begin
              lastCmt := 0;
           end else
              if (ch = '*') and (src[i+1] = '/') then
              begin
                lastCmt := 0;
                Inc(i);
              end;
           Continue;
       end else
           if ch = '#' then
           begin
              lastCmt := 2;
              Continue;
           end
           else
           if ch = '/' then begin
              case src[i+1] of
                '/': lastCmt := 1;
                '*': lastCmt := 3;
              end;
              if lastCmt > 0 then
              begin
                  inc(i);
                  continue;
              end;
           end;

       if isStr or ((ch <> ' ') or ((ch = ' ') and (src[i+1] <> '('))) then
       begin
          instQ := instQ + ch;
       end;

       if isQuote(src, i, quoCh) then
          begin
             isStr := not isStr;
             if isStr then begin
               quoCh := ch;
               quoLine := line;
             end
             else quoCh := #0;

             if ch = defQuote then inst := inst + defQuote;
             if ch = defMQuote then inst := inst + defMQuote;

             Continue;
          end;

       if not isStr then begin

          case ch of
              '(': inc(skO);
              ')': dec(skO);
          end;

          if skO < 0 then
          begin
              ErrPool.newError(errSyntax, MSG_ERR_SKOBA, line);
              exit;
          end;

          if skO = 0 then
          begin
            getBreak(src, inst, i, lineX);
              if ( lineX.line = 1 ) then
              begin
                inst := TrimLeft(inst);

                if inst <> '' then
                begin
                    if lineX.str = '' then
                      AddBlock(Line - char_count(inst,#13),
                               TrimRight(inst),
                               trim( copy(instQ,1,length(instQ)-1) ) + ')')
                    else
                      AddBlock(Line - char_count(inst,#13),
                               TrimRight(inst),
                               trim( copy(instQ,1,length(instQ)-1) ));

                    end;

                if lineX.str <> '' then
                begin
                  if line = 1 then
                    AddBlock(1, lineX.str, lineX.str)
                  else
                    AddBlock(line-1, lineX.str, lineX.str);
                end;

                if ErrPool.existsFatalError then
                begin
                    clearBlocks;
                    exit;
                end;
                

                instQ := '';
                inst  := '';
                Continue;
              end else
                inst   := inst + ch;
           end else
                inst   := inst + ch;
       end;

     end;

     if skO <> 0 then
     begin
          ErrPool.newError(errParse, MSG_ERR_NOSKOBA, line);
          Exit;
     end;

     if quoCh <> #0 then
     begin
         ErrPool.newError(errParse, Format(MSG_ERR_NOQUOTE_F, [quoCh]), quoLine);
         exit;
     end;

     fixShortBlock;
end;


end.

