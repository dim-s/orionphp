unit ori_vmEval;

{$H+}
{$IFDEF FPC}
    {$mode delphi}
   {.$DEFINE USE_INLINE}
{$ELSE}
   {.$DEFINE USE_INLINE}
{$ENDIF}

interface

uses
  Classes, SysUtils, StrUtils,

  ori_StrConsts,
  ori_StrUtils,
  ori_Types,
  ori_vmTypes,
  ori_Stack,
  ori_vmShortApi,

  ori_vmValues,
  ori_vmCrossValues,
  ori_vmVariables,
  ori_vmConstants,
  ori_vmTables,
  ori_vmClasses,
  ori_Errors,
  ori_vmNativeFunc,
  ori_vmMemory,
  ori_FastArrays
  {ori_vmCompiler};

  type
  TCallbackDebug = procedure(Eval: Pointer; line: cardinal);

  type
  { TOriEval }
  TOriEval = class(TObject)
     protected
        s1,s2,sRes: TOriMemory;
        mval: TOriMemory;
        FExit: Boolean;

        arr: TOriTable;
        func: Pointer;

        procedure callBreak();
        procedure callPushL(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callPushD(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callPushB(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callPushS(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callPushMS(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callPushN(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callPushV(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callPushGV(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callPush(); {$IFDEF USE_INLINE} inline; {$ENDIF}

        procedure callInc(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callDec(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callAssign();  

        procedure callCallNative();
        procedure callCall();
        procedure callCallStatic();

        procedure callPlus();
        procedure callMinus();
        procedure callUnarMinus();
        procedure callMul();
        procedure callDiv();
        procedure callConcat();
        procedure callXor();
        procedure callMod();
        procedure callHashValue();

        procedure callShl();
        procedure callShr();

        procedure callPlusAssign();
        procedure callMinusAssign();
        procedure callMulAssign();
        procedure callDivAssign();
        procedure callModAssign();
        procedure callXorAssign();
        procedure callConcatAssign();

        procedure callMinEq();
        procedure callMaxEq();
        procedure callMax();
        procedure callMin();
        procedure callEqual();
        procedure callNoequal();
        procedure callEqualType();
        procedure callNoequalType();

        procedure callNot();
        procedure callBitNot();

        procedure callAnd();
        procedure callOr();
        procedure callLogicXor();
        procedure callBitAnd();
        procedure callBitOr();

        procedure callIn();


        procedure callLink();

        procedure callTypedInt();
        procedure callTypedDouble();
        procedure callTypedBool();
        procedure callTypedStr();
        procedure callTypedAray();
        procedure callTypedObject();


        procedure callNewArray();
        procedure callGetHash(Clone: Boolean);
        procedure callGlobal();

        procedure callReturn(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callUnset();

        procedure callIF(var i: integer); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure callNotIf(var i: integer); {$IFDEF USE_INLINE} inline; {$ENDIF}

        procedure callForeach();
        procedure callForeachInit();

        procedure callClassConst();
        procedure callClassProperty();
        procedure callUseAs();

        procedure get2xParams(); {$IFDEF USE_INLINE} inline; {$ENDIF}
        procedure get1xParams(); {$IFDEF USE_INLINE} inline; {$ENDIF}

        procedure checkArrElement(s: TOriMemory); {$IFDEF USE_INLINE} inline; {$ENDIF}
     public
        
        cashFuncParams: TOriMemoryStack;
        cashFuncReturn: TOriMemory;
        stackList: TPtrArray;

        tk: POpcodeLine;
        prevTk: POpcodeLine;
        ToStack: Boolean;

        Owner: TOriClass;
        DefClass: TOriClass;

        InManager: Boolean;
        isUse: Boolean;
        isRun: Boolean;

        Variables: TOriVariables;
        Stack: TOriMemoryStack;
        ErrPool: TOriErrorPool;

        code: TOpcodeArray;

        DebugFunc: TCallbackDebug;

        procedure Run;
        procedure StackVariable(M: TOriMemory);

        constructor Create(const initStack: boolean = true);
        destructor Destroy; override;

        procedure ClearInfo; inline;
        procedure ToExit; inline;

        // кладет из стека N элементов в список cashFuncParams...
        procedure getPopN(const N: Integer);
        procedure AddToStackList(p: pointer);

        //property ToStack: Boolean read ReadToStack;
  end;
  
implementation

  uses
    ori_vmUserFunc,
    ori_Parser,
    ori_ManRes,
    ori_hash32;


procedure TOriEval.stackVariable(M: TOriMemory);
  var
  id: integer;
begin
  case M.typ of
      mvtVariable:
        begin
              M.Mem.ptr := Variables.getVariablePtr(M.Mem.str);
        end;
      mvtGlobalVar:
        begin
              M.Mem.ptr := ori_vmVariables.GlobalVars.getVariablePtr(M.Mem.str);
        end;
      mvtWord:
        begin
            if M.id = -1 then
                M.id := VM_Constants.getConstant( M.Mem.str );

            if M.id <> -1 then
                VM_Constants.putVMConstant( M, VM_Constants.Constants[M.id] )
            else begin
                M.ValType(mvtString);
            end;

        end;
  end;
end;

procedure TOriEval.Run;
   var
   i: integer;
begin
   FExit := false;
   isRun := true;
   //try
   i := 0;
   while (i < code.Count) do
   begin
        if FExit then
        begin
           clearManMemory();
           Stack.discardAll;
           break;
        end;
        
        tk := code.Values^[i];
        ToStack := tk^.toStack;
        case tk^.typ of
            OP_NOP   : begin inc(i); continue; end;
            OP_RET   : begin
                        callReturn();
                        break;
            end;
            OP_USE_AS: callUseAs();

            OP_BREAK : callBreak();
            OP_PUSH_L: callPushL();
            OP_PUSH_D: callPushD();
            OP_PUSH_S: callPushS();
            OP_PUSH_MS: callPushMS();
            OP_PUSH_B: callPushB();
            OP_PUSH_V: callPushV();
            OP_PUSH_GV: callPushGV();
            OP_PUSH_N: callPushN();
            OP_PUSH  : callPush();
            OP_ASSIGN: callAssign();
            OP_CALL  : callCall();
            OP_CALL_NATIVE  : callCallNative();
            //OP_CALL_DYN     : callCallNativeDyn();

            OP_PLUS  : callPlus();
            OP_MINUS : callMinus();
            OP_MUL   : callMul();
            OP_DIV   : callDiv();
            OP_CONCAT: callConcat();
            OP_XOR: callXor();
            OP_MOD: callMod();
            OP_UNARMINUS: callUnarMinus();
            OP_HASH_VALUE: callHashValue();

            OP_PLUS_ASSIGN: callPlusAssign();
            OP_MINUS_ASSIGN: callMinusAssign();
            OP_MUL_ASSIGN: callMulAssign();
            OP_DIV_ASSIGN: callDivAssign();
            OP_MOD_ASSIGN: callModAssign();
            OP_XOR_ASSIGN: callXorAssign();
            OP_CONCAT_ASSIGN: callConcatAssign();

            OP_ISMAX_EQ: callMaxEq();
            OP_ISMAX   : callMax();
            OP_ISMIN_EQ: callMinEq();
            OP_ISMIN   : callMin();

            OP_EQUAL   : callEqual();
            OP_NOEQUAL : callNoequal();
            OP_EQUAL_T : callEqualType();
            OP_NOEQUAL_T:callNoequalType();

            OP_NOT     : callNot();
            OP_BIT_NOT : callBitNot();
            OP_AND     : callAnd();
            OP_OR      : callOr();
            OP_LOGIC_XOR : callLogicXor();
            OP_IN      : callIn();

            OP_BIT_AND : callBitAnd();
            OP_BIT_OR  : callBitOr();

            OP_SHL     : callShl();
            OP_SHR     : callShr();

            OP_INC     : callInc();
            OP_DEC     : callDec();

            OP_LINK    : callLink();

            OP_TYPED_INT : callTypedInt();
            OP_TYPED_DOUBLE : callTypedDouble();
            OP_TYPED_BOOL : callTypedBool();
            OP_TYPED_STR : callTypedStr();
            OP_TYPED_ARRAY : callTypedAray();
            OP_TYPED_OBJ : callTypedObject();

            OP_UNSET   : callUnset();

            OP_NEW_ARRAY: callNewArray();
            OP_GET_HASH: callGetHash(false);
            OP_GET_CLONE_HASH: callGetHash(true);
            OP_CALL_STATIC: callCallStatic();
            OP_GLOBAL  : callGlobal;

            OP_FOREACH : begin
                           prevTk := code[i-1];
                           callForeach();
                           if not Stack.Pop.AsBoolean then
                           begin
                              i := tk^.cnt+1;
                              continue;
                           end;
                         end;
            OP_FOREACH_INIT: begin
                           callForeachInit();
                           if tk^.ptr = nil then
                           begin
                              i := code[i+1]^.cnt;
                              continue;
                           end;
                        end;

            OP_JMP     : begin i := tk^.cnt; continue; end;
            OP_JMP_D   : begin i := tk^.cnt; continue; end;
            OP_JMPZ    : if not sRes.AsBoolean then
                         begin
                              i := tk^.cnt;
                              continue;
                         end;
            OP_JMPZ_N  : if sRes.AsBoolean then
                         begin
                              i := tk^.cnt;
                              continue;
                         end;

            OP_IF,OP_ELSEIF : callIF(i);
            OP_IF_N: callNotIf(i);
            OP_ELSE    : begin inc(i); continue; end;


            OP_CLASS_CONST: callClassConst();
            OP_CLASS_PROPERTY: callClassProperty();
            
            OP_DEFINE_FUNC: begin

                  func := ori_vmUserFunc.createFunction( tk^.oper1.Mem.ptr, code, i+1, tk^.cnt-1,ErrPool );
                  if ErrPool.existsFatalError then
                  begin
                    ErrPool.setLineToLastErr(tk^.line);
                    exit;
                  end;
                    i := tk^.cnt;
                    if tk^.toStack then
                    begin
                        tk := code[i]; // ТАК ДОЛЖНО БЫТЬ!!!!!!
                        Stack.Push.ValFunction(func);
                        callAssign;
                    end else
                        tk := code[i];
            end;
            OP_DEF_METHOD: begin
                
                  func := ori_vmUserFunc.createFunctionEx( tk^.oper1.Mem.ptr, code, i+1, tk^.cnt-1 );
                  Self.DefClass.SetMethod( TUserFunc(func).info^.name,
                                           TUserFunc(func).info^.modifer, omtUser,
                                           TUserFunc(func).info^.isStatic ,func );
                  TUserFunc(func).DefClass := DefClass;
                  i := tk^.cnt;
                  Continue;
            end;
            OP_DEF_CLASS: begin
                Self.DefClass := TOriClass.Create();
                ori_vmClasses.addNamedClass( tk^.oper1.Mem.str, Self.DefClass, ErrPool );
                if ErrPool.existsFatalError then
                begin
                   ErrPool.setLineToLastErr(tk^.line);
                   exit;
                end;
                
                if tk^.oper2 <> nil then
                begin
                    Self.DefClass.parent := ori_vmClasses.findByName( tk^.oper2.Mem.str );
                    if Self.DefClass.parent = nil then
                    begin
                        ErrPool.newError(errFatal,
                                        Format(MSG_ERR_CLASS_NOEXISTS, [tk^.oper2.Mem.str]),
                                        tk^.line);
                        exit;
                    end;
                end;
            end;
            OP_UNDEF_CLASS: begin
                Self.DefClass := nil;
            end;
        end;
        
            if tk^.checkMemory then
            begin
                clearManMemory();
                if stackList <> nil then
                   stackList.CacheClear;

                if Assigned(DebugFunc) then
                  DebugFunc(Self, tk^.Line);
                   
                if not toStack then
                  Stack.discardAll;
            end;

            if ErrPool.existsFatalError then
            begin
                ErrPool.setLineToLastErr(code[i]^.line);
                exit;
            end;

        inc(i);
   end;

        {except
           on E: Exception do begin
             ErrPool.newError(errCoreFatal, e.Message, tk^.line);
           end;
        end;}
   isRun := false;
end;


//#

procedure TOriEval.callBreak(); 
begin
    Stack.discardAll();
end;

//#
procedure TOriEval.callPushL(); 
begin
   sRes := Stack.Push;
   sRes.ValL(tk^.oper1.Mem.lval);
end;

//#
procedure TOriEval.callPushD(); 
begin
    sRes := Stack.Push;
    sRes.ValF(tk^.oper1.Mem.dval);
end;

procedure TOriEval.callPushGV;
begin
      sRes     := Stack.Push;
      sRes.Typ := mvtVariable;
      sRes.Mem.Ptr := GlobalVars.getVariablePtr(tk^.oper1.Mem.str);
end;

//#
procedure TOriEval.callPushB(); 
begin
   sRes := Stack.Push;
   sRes.Val(tk^.oper1.Mem.bval);
end;

//#
procedure TOriEval.callPushS(); 
begin
   sRes := Stack.Push;
   sRes.Val(tk^.oper1.Mem.Str);
end;

//#
procedure TOriEval.callPushMS(); 
begin
   sRes := Stack.Push;
   sRes.Val(tk^.oper1.Mem.Str);
end;

//#
procedure TOriEval.callPushN();
begin
  sRes := Stack.Push;
  sRes.ValType(mvtNull);
end;

procedure TOriEval.callPushV();
begin
     sRes     := Stack.Push;
     sRes.Typ := mvtVariable;
     sRes.Mem.Ptr := variables.getVariablePtr(tk^.oper1.Mem.str);
end;


procedure TOriEval.callReturn;
begin
      cashFuncReturn.Val(Stack.pop, true);
      cashFuncReturn.UseObjectAll;
end;

procedure TOriEval.callShl;
begin
  get2xParams;
  if not toStack then exit;

  sRes.ValL( s1.AsInteger shl s2.AsInteger );
end;

procedure TOriEval.callShr;
begin
  get2xParams;
  if not toStack then exit;

  sRes.ValL( s1.AsInteger shr s2.AsInteger );
end;

procedure TOriEval.callTypedAray;
begin
  get1xParams;
  if toStack then
  begin
      case s1.typ of
      mvtVariable, mvtGlobalVar:
        begin
          with s1.AsRealMemory do
          begin
              if typ = mvtHash then
                  arr := TOriTable(Mem.ptr)
              else
                  arr := TOriTable.CreateInManager;
          end;
        end;
      mvtHash: arr := TOriTable(s1.Mem.ptr);
      else
          arr := TOriTable.CreateInManager;
      end;
      sRes.ValTable(arr);
  end;
end;

procedure TOriEval.callTypedBool;
begin
  get1xParams;
  if toStack then
    sRes.Val( s1.AsBoolean );
end;

procedure TOriEval.callTypedDouble;
begin
  get1xParams;
  if toStack then
    sRes.ValF( s1.AsFloat );
end;

procedure TOriEval.callTypedInt;
begin
  get1xParams;
  if toStack then
    sRes.ValL( s1.AsInteger );
end;

procedure TOriEval.callTypedObject;
begin

end;

procedure TOriEval.callTypedStr;
begin
  get1xParams;
  if toStack then
    sRes.Val( s1.AsString );
end;

//# если есть константа, ставим в стек...
procedure TOriEval.callPush();
begin
    if tk^.id = -1 then
        tk^.id := VM_Constants.getConstant( tk^.oper1.Mem.str );

    sRes := Stack.Push;

    if tk^.id <> -1 then
        VM_Constants.putVMConstant( sRes, VM_Constants.Constants[tk^.id] )
    else begin
        sRes.Val(tk^.oper1.Mem.str);
    end;
end;

//#
procedure TOriEval.callIn;
  var
  S: MP_String;
  N: MP_Float;
  B: Boolean;
  i  : integer;
  label type_arr,type_str,type_num,fin_true;
begin
    get2xParams;
    if toStack then
    begin
        case s2.typ of
            mvtVariable,mvtGlobalVar:
            begin
                mval := s2.AsMemory;
                if mval.typ = mvtPointer then
                  mval := mval.AsMemory;

                case mval.typ of
                    mvtHash: begin
                              arr := mval.Mem.ptr;
                              goto type_arr;
                            end;
                    mvtString: begin
                              S := mval.Mem.str;
                              goto type_str;
                            end;
                    else
                       goto type_num;
                end;
             end;
            mvtHash:
              begin
                 arr := s2.Mem.ptr;
                 goto type_arr;
              end;
            mvtString:
              begin
                S := s2.Mem.str;
                goto type_str;
              end
            else
              goto type_num;
        end;

        type_arr:
            case s1.typ of
                    mvtInteger,mvtDouble: N := s1.AsFloat;
                    mvtString,mvtPChar:   S := s1.AsString;
                    mvtBoolean,mvtNull,mvtNone: B := s1.AsBoolean;
                end;

            for i := 0 to arr.count-1 do
            begin
                case s1.typ of
                    mvtInteger,mvtDouble:
                        if N = arr[i].AsFloat then
                          goto fin_true;
                    mvtString,mvtPChar:
                        if S = arr[i].AsString then
                          goto fin_true;
                    mvtBoolean,mvtNull,mvtNone:
                        if B = arr[i].AsBoolean then
                          goto fin_true;
                end;
                if S = arr[i].AsString then
                begin
                  sRes.Val(true);
                  exit;
                end;
            end;
            sRes.Val(false);
            exit;

            fin_true:
              sRes.Val(true);
        exit;

        type_str:

            sRes.Val( Pos(s1.AsString, S) > 0 );
        exit;

        type_num:
          sRes.Val( false );
    end;
end;

procedure TOriEval.callInc();
begin
  get1xParams();
  if s1.typ in [mvtVariable,mvtGlobalVar] then
  begin
      mval := s1.AsRealMemory;
      case mval.typ of
          mvtNull: begin
                     mval.ValL(0);
                     if toStack then sRes.ValL(0);
                  end;
          mvtInteger: begin
                    inc(mval.Mem.lval);
                    if toStack then sRes.ValL(mval.Mem.lval);
                   end;
                     
          mvtDouble : begin
                    mval.Mem.dval := mval.Mem.dval + 1;
                    if toStack then sRes.ValF(mval.Mem.dval);
                 end;
          else
            begin
                mval.ValF( mval.AsFloat + 1 );
                if toStack then sRes.ValF(mval.Mem.dval);
            end;
      end;
  end else
           ErrPool.newError(errFatal, MSG_ERR_NOPTR, tk^.line);
end;



procedure TOriEval.callLink;
begin
  get1xParams;

  if s1.typ in [mvtVariable,mvtGlobalVar] then
  begin
      mval := s1.AsMemory.AsPtrMemory;

        sRes.Typ := mvtLink;
        sRes.Mem.ptr := mval;

  end else if s1.typ in [mvtWord,mvtString] then
  begin
      tk^.id := ori_vmUserFunc.findByNameIndex(LowerCase(s1.Mem.str));
      if tk^.id > -1 then
          sRes.ValFunction( ori_vmUserFunc.findByIndex(tk^.id) )
      else
          sRes.ValNull;

  end else if s1.typ = mvtHashValue then
  begin
      // -- TODO
      {TOriTable(s1^.ptr).addValue(s1^.str, createVMValue(vtNull));
      sRes^.typ := svtLink;
      sRes^.ptr := TOriTable(s1^.ptr).Values.V^[TOriTable(s1^.ptr).count-1];}
  end else
      sRes.ValNull;
end;

procedure TOriEval.callLogicXor;
begin
  get2xParams;
  if toStack then
      sRes.Val( s1.AsBoolean xor s2.AsBoolean );
end;

procedure TOriEval.callDec();
begin
  get1xParams();
  if s1.typ in [mvtVariable,mvtGlobalVar] then
  begin
      mval := s1.AsRealMemory;
      case mval.typ of
          mvtNull: begin
                     mval.ValL(0);
                     if toStack then sRes.ValL(0);
                  end;
          mvtInteger: begin
                    dec(mval.Mem.lval);
                    if toStack then sRes.ValL(mval.Mem.lval);
                   end;
                     
          mvtDouble : begin
                    mval.Mem.dval := mval.Mem.dval - 1;
                    if toStack then sRes.ValF(mval.Mem.dval);
                 end;
          else
            begin
                mval.ValF( mval.AsFloat - 1 );
                if toStack then sRes.ValF(mval.Mem.dval);
            end;
      end;
  end else
           ErrPool.newError(errFatal, MSG_ERR_NOPTR, tk^.line);
end;

procedure TOriEval.callAssign();
  label 1,2;
begin

  get2xParams();
  checkArrElement(s1);


   if s1.typ in [mvtVariable,mvtGlobalVar] then
   begin
        s1.AsRealMemory.UnuseObjectAll;

        with s2 do
        begin
            case typ of
                mvtHash: begin
                    arr := TOriTable(Mem.ptr);
                    1:

                        mval := s1.AsRealMemory;
                        begin
                          //inc(arr.ref_count);
                          arr.Use;
                          mval.ValTable(arr);
                        end;

                          if toStack then
                              sRes.ValTable(arr);
                    exit;
                end;
                (*mvtVariable,mvtGlobalVar: begin
                   // если чему присваиваем    _НЕПОНЯТНЫЙ КОД
                   {if s1.AsMemory.typ = mvtHash then
                   begin
                      arr := TOriTable(s1.AsMemory.Mem.ptr);
                   goto 1;
                   end else goto 2;}
                end; *) // WTF ???
                mvtNone: begin
                    checkArrElement(s2);
                end
                else begin
                     2:
                            mval := s1.AsRealMemory;
                            mval.Val( s2, false );

                            //if s2^.typ <> svtLink then
                            mval.UseObjectAll;
                end;
            end;

        end;

        if toStack then
             sRes.Val(s2, true);
             
   end else if s1.typ = mvtPChar then
   begin
      s1.Mem.pchar^ := s2.AsChar;
      if toStack then
        sRes.Val(s1.Mem.pchar^);

   end else
        ErrPool.newError(errFatal, MSG_ERR_ASSIGN, tk^.line);
end;

procedure TOriEval.callCallNative();
  var
  func: PNativeFunc;
  proc: TNativeProcedure;
  cnt{i}: Cardinal;
begin
  //func := ori_vmNativeFunc.findByIndex(tk^.id);
  func := Native_Functions[tk^.id];

      cnt := tk^.cnt;
      if cnt < func^.cnt then
      begin
         ErrPool.newError(errFatal, Format(MSG_ERR_PRMCNT_F, [func^.name,func^.cnt]), tk^.line);
         exit;
      end;

      cashFuncReturn.ValNull;
      getPopN(tk^.cnt);
      {$IFDEF THREAD_SAFE}
      cashFuncParams.UseObjectAll;
      {$ENDIF}

      proc := TNativeProcedure(func^.func);
      proc(cashFuncParams, cnt, cashFuncReturn, self);

      {$IFDEF THREAD_SAFE}
      cashFuncParams.UnuseObjectAll;
      {$ENDIF}

      if toStack then
      begin
        sRes := Stack.Push;
        sRes.Val( cashFuncReturn, false );
      end;
end;

procedure TOriEval.callCallStatic;
   var
   id: Integer;
   obj: TOriClass;
   m: POriMethod;
   label 1,2;
begin
  get2xParams;
  if s1.typ in [mvtVariable,mvtGlobalVar] then
  begin
       mval := s1.AsRealMemory;
       if not(mval.typ in [mvtHash,mvtObject,mvtString]) then
       begin
          mval.UnuseObjectAll;
          mval.Mem.ptr := TOriTable.CreateInManager;
          TOriTable(mval.Mem.ptr).Use;
          mval.ValType(mvtHash);
          
          if ToStack then
          begin
              sRes.Mem.ptr := TOriTable(mval.Mem.ptr).GetCreateValue( s2.AsString );
              sRes.typ := mvtVariable;
          end;
       end;

     case mval.typ of
        mvtHash: begin
          sRes.Mem.ptr := TOriTable(mval.Mem.ptr).GetCreateValue( s2.AsString );
          sRes.typ := mvtVariable;

        end else
        begin
          
          obj := ori_vmClasses.findByName(mval.AsString);
          goto 1;
        end;
     end;
  end else begin
          // if null then SELF or PARENT constant
          if s1.typ = mvtNull then
          begin
              case s1.id of
                0: obj := DefClass;
                1: if DefClass <> nil then
                   begin
                     obj := DefClass.parent;
                     m := obj.GetInMethod(s2.AsString, obj);
                     // goto 2, for call private props in class OBJ
                     goto 2;
                   end
                   else obj := nil;
              end;
              if obj = nil then
              begin
                ErrPool.newError(errFatal, MSG_ERR_NO_CLASS_OR_OBJECT, tk^.line);
                exit;
              end;
          end
          // else CLASS from Name
          else begin
              if s1.IsString then begin
                  if tk^.id = -1 then begin
                      tk^.id := ori_vmClasses.findByNameIndex(s1.Mem.str);
                      if tk^.id = -1 then
                        obj := nil
                      else
                        obj := ori_vmClasses.ClassPtrs[ tk^.id ];
                  end else
                      obj := ori_vmClasses.ClassPtrs[ tk^.id ];
              end
              else
                  obj := ori_vmClasses.findByName(s1.AsString);
                  
              if obj = nil then
              begin
                ErrPool.newError(errFatal, Format(MSG_ERR_NO_CLASS_OR_OBJECT,[' "'+s1.AsString+'" ']), tk^.line);
                exit;
              end;
          end;
          1:
          // get method in class
          if s2.IsString then
          begin
              if tk^.id <> -1 then begin
                if tk^.ptr = nil then
                  tk^.ptr := obj.GetInMethod(ori_StrLower(s2.Mem.str), Self.DefClass);
                m := tk^.ptr;
              end else
                m := obj.GetInMethod(ori_StrLower(s2.Mem.str), Self.DefClass)
          end
          else
              m := obj.GetInMethod(ori_StrLower(s2.AsString), Self.DefClass);
          2:
          if m = nil then
          begin
              ErrPool.newError( errFatal, Format(MSG_ERR_NOMETHOD_IN_CLASS,[s2.AsString]), tk^.line );
              exit;
          end
          else
          if ((m^.modifer = ommPublic) and not (m^.isStatic)) then
          begin
              ErrPool.newError(errFatal, Format(MSG_ERR_NOCAN_CALL_STATIC,[s2.AsString]), tk^.line);
              exit;
          end;

          if m^.typ in [omtProp,omtConst] then
          begin
              
              if toStack then begin
                  sRes.typ     := mvtVariable;
                  sRes.Mem.ptr := m^.ptr;
                  //assignStackValue(PVMValue(m^.ptr), sRes);
              end;
          end
          else begin
             sRes.typ     := mvtMethod;
             sRes.Mem.ptr := m;
          end;

          Exit;
  end;

  ErrPool.newError(errFatal, format(MSG_ERR_CALLSTATIC,[s2.AsString]), tk^.line);
end;

procedure TOriEval.callClassConst;
  var
  prop: PCodeProperty;
begin
  if DefClass = nil then
  begin
      prop := PCodeProperty(tk^.oper1.Mem.ptr);
      if VM_Constants.getConstant(prop^.name) > -1 then
      begin
          ErrPool.newError(errFatal, Format(MSG_ERR_CONSTEX_F,[prop^.name]),tk^.line);
          exit;
      end;

      VM_Constants.addConstant(prop^.name, Stack.pop() );
  end else
   if not DefClass.SetConst( tk^.oper1.Mem.ptr, Stack.pop() ) then
   begin
       prop := PCodeProperty(tk^.oper1.Mem.ptr);
       ErrPool.newError(errFatal, Format(MSG_ERR_CONSTEX_F,[prop^.name]),tk^.line);
   end;
end;

procedure TOriEval.callClassProperty;
  var
  prop: PCodeProperty;
begin
  if DefClass = nil then
  begin
        ErrPool.newError(errFatal, Format(MSG_ERR_NO_CLASS_OR_OBJECT,[' ']), tk^.line);
        exit;
  end else begin
        prop := PCodeProperty(tk^.oper1.Mem.ptr);
        if prop^.expr <> '' then
            s1 := Stack.pop()
        else
            s1 := nil;

        if not DefClass.SetProperty(prop, s1) then
        begin
            ErrPool.newError(errFatal, Format(MSG_ERR_PROPERTEX_F,[prop^.name]),tk^.line);
        end;
  end;
end;

procedure TOriEval.callCall();
  var
  st: TOriMemory;
  m: POriMethod;
  evFunc: TOriEval;
  label err, 1, call, aResult;
begin
   Func := nil;
   if (tk^.oper1 = nil) then
   begin
      if tk^.cnt < 1 then begin
          st := Stack.pop;
          sRes := nil;
      end
      else if tk^.oper2 <> nil then begin
          st := Stack[Stack.Count - tk^.cnt];  // т.к. одно значение лежит не в стеке а в регистре...
          sRes := st;
      end
      else begin
          st := Stack[tk^.cnt];
          sRes := st;
      end;
          
      with st do begin
          if typ in [mvtVariable,mvtGlobalVar] then
          begin
              with st.AsRealMemory do
              begin
                  if typ = mvtString then
                  begin
                      Func := ori_vmUserFunc.findByName(Mem.Str);
                      if func = nil then
                      begin
                        tk^.id := ori_vmNativeFunc.findByNameIndex( Mem.str );
                        goto 1;
                      end;
                  end
                  else if typ = mvtFunction then
                      Func := TUserFunc(Mem.ptr)
                  else
                      goto err;
              end;
          end else if typ = mvtString then
          begin
               Func := ori_vmUserFunc.findByName(st.Mem.str);
               if func = nil then
               begin
                  tk^.id := ori_vmNativeFunc.findByNameIndex( st.Mem.str );
                  goto 1;
               end;
          end else if typ = mvtMethod then begin
               M := st.Mem.ptr;
               if M = nil then goto err;
               
               case M^.typ of
                  omtNative: begin
                      
                  end;
                  omtUser: begin
                     Func := TUserFunc(M^.ptr);
                     goto call;
                  end;
                  else
                      goto err; 
               end;
          end else goto err;

      end;

   end 
   else begin
      if tk^.id = -1 then
        tk^.id := ori_vmUserFunc.findByNameIndex(tk^.oper1.Mem.str);

      if tk^.id = -1 then
      begin
        Func := nil;
      end
      else begin
        Func := ori_vmUserFunc.findByIndex( tk^.id );
        if toStack then
        begin
            sRes := nil;
            goto call;
        end;
      end;
   end;
   
   if ( Func = nil ) then
   begin
         tk^.id := ori_vmNativeFunc.findByNameIndex( tk^.oper1.Mem.str );
         1:
         if tk^.id <> -1 then
         begin
              tk^.typ := OP_CALL_NATIVE;
              {if ori_vmNativeFunc.findByIndex(tk^.id)^.isDynamic then
              begin
                  tk^.typ := OP_CALL_DYN;
                  callCallNativeDyn();
              end else} begin
                  tk^.typ := OP_CALL_NATIVE;
                  callCallNative();
              end;
              exit;
         end;
         ErrPool.newError(errFatal,
            Format(MSG_ERR_NOTFOUND_FUNC,[tk^.oper1.Mem.str]),tk^.line);
   end else begin
      call:

      if tk^.cnt < TUserFunc(func).MinParamCount then
      begin
         ErrPool.newError(errFatal, Format(MSG_ERR_PRMCNT_F, [TUserFunc(func).name,TUserFunc(func).MinParamCount]), tk^.line);
         exit;
      end;

      if tk^.cnt = 0 then begin
          evFunc := TUserFunc(Func).Invoke(ErrPool);
      end
      else
          evFunc := TUserFunc(Func).Invoke(Self);

      if evFunc = nil then exit;
      if toStack then
      begin
          aResult:
            if sRes = nil then sRes := Stack.push;
               sRes.Val( evFunc.cashFuncReturn, true );
            //useVMValue(evFunc.cashFuncReturn);
      end;
     tryObjectiveFree(evFunc.cashFuncReturn);

      
      if evFunc.InManager then
        evFunc.isUse := false
      else
        evFunc.Free;
   end;
   exit;

   err:
    ErrPool.newError(errFatal,MSG_ERR_NOTFUNC,tk^.line);
end;

procedure TOriEval.callGetHash(Clone: Boolean);
  Var
  hash: TOriTable;
  id: Integer;
begin
  if tk^.cnt = 2 then
  begin
        get2xParams();

        if s1.typ in [mvtVariable,mvtGlobalVar] then
        begin
          mval := s1.AsRealMemory;

          case mval.typ of
              mvtString : if toStack then
                          begin
                            with sRes do
                            begin
                              Mem.pchar :=  @mval.Mem.str[s2.AsInteger+1];
                              typ       := mvtPChar;
                            end;
                            exit;
                         end;
              mvtHash: ;
              else begin
                    hash := TOriTable.CreateInManager;
                    mval.ValTable(hash);
              end;
          end;
          hash := TOriTable(mval.Mem.ptr);
        end else if s1.typ = mvtHash then
              hash := TOriTable(s1.Mem.ptr)
        else if s1.typ = mvtHashValue then begin

              hash := TOriTable(s1.Mem.ptr);
              mval := TOriMemory.GetMemory;
              hash.Add(s1.Mem.Str, mval); // add
              hash := TOriTable.CreateInManager;
              AddToStackList(hash);
              // --TODO  ???
              //hash.parent := s1^.ptr;

              mval.ValTable(hash);

        end else begin
            ErrPool.newError(errFatal, MSG_ERR_ARR, tk^.line);
            exit;
        end;

              if toStack then
              begin
                  if hash = GlobalVars then
                  begin
                    sRes.Mem.ptr := hash.GetCreateValue(ori_StrLower(s2.AsString))
                  end
                  else begin
                    if Clone then begin
                      if hash.ref_count > 1 then
                      begin
                          hash.Unuse;

                          hash := hash.Clone(false);
                          hash.Use;
                          mval.Mem.ptr := hash;
                      end;
                    end;

                    // --TODO ???
                    {if s2^.typ = svtInteger then
                      id := hash.byNameIntIndex(s2^.lval)
                    else}
                      id := hash.byNameIndex(s2.AsString);
                      
                    if id = -1 then
                    begin
                      sRes.Val(s2.AsString);
                      sRes.typ := mvtHashValue;
                      sRes.Mem.ptr := hash;
                      AddToStackList(hash);
                      exit;
                    end else begin
                      sRes.Mem.ptr := hash.Value[id];
                    end;
                  end;

                    sRes.Typ := mvtVariable;

              end;// else
                  //hash.getValue(stackToString(s2));

  end else if tk^.cnt = 1 then
  begin
        get1xParams();
        if s1.typ in [mvtVariable,mvtGlobalVar] then
        begin
            mval := s1.AsRealMemory;
            if mval.typ <> mvtHash then
            begin
                mval.ValTable( TOriTable.CreateInManager );
            end;
            AddToStackList(mval.Mem.ptr);

            sRes.typ     := mvtHashValue;
            sRes.Mem.ptr := mval.Mem.ptr;
            with TOriTable(mval.Mem.ptr) do begin
                Inc(LastNum);
                sRes.Mem.str := IntToStr(LastNum);
            end;
        end;
  end;
end;


procedure TOriEval.callGlobal;
   var
   i,id: integer;
   v,r: TOriMemory;
begin
  if tk^.cnt > 0 then begin
  for i := tk^.cnt - 1 to 0 do
  begin
      if i = 0 then begin
          if tk^.oper2 = nil then
            s1 := Stack.Pop
          else
            s1 := tk^.oper2;
      end else
          s1 := Stack.Pop;

       // --TODO
       v := GlobalVars.GetCreateValue( s1.Mem.str );
       v.Use;
       v.UseObjectAll;


       r := variables.GetCreateValue( s1.Mem.str );
       r.UnuseObjectAll;
       r.ValPtr( v );
       r.ValType( mvtPointer );

  end;
      //Stack.push(svtVariable)^.ptr := r;
  end;
end;

procedure TOriEval.callHashValue;
begin
  if tk^.oper2 <> nil then
  begin
     stackVariable(tk^.oper2);
     s2 := Stack.push;
     s2.Assign(tk^.oper2);
  end else begin
     s2   := Stack.getTop;
  end;

  if tk^.oper1 = nil then
  begin
      s1 := Stack.pop();
      if not toStack then Stack.discardAll;
  end else begin
      stackVariable(tk^.oper1);
      s1 := tk^.oper1;
  end;

   if toStack then
   begin
      with Stack.push do
      begin
        typ := mvtHashValue;
        Mem.Str := s1.AsString;
        Mem.Ptr := s2;
      end;
   end;
end;

procedure TOriEval.get2xParams();
begin
  if tk^.oper2 <> nil then
  begin
     s2 := tk^.oper2;
     stackVariable(tk^.oper2);
  end else begin
     s2   := Stack.pop;
  end;

  if tk^.oper1 = nil then
  begin
      s1 := Stack.getTop();
      sRes := s1;
      if not toStack then Stack.discardAll;
  end else begin

      stackVariable(tk^.oper1);

      s1 := tk^.oper1;
      if toStack then
          sRes := Stack.push
  end;

end;

procedure TOriEval.getPopN(const N: Integer);
  var
  i: integer;
begin
   cashFuncParams.SetLength(N);
   if N > 0 then
   for i := N - 1 downto 0 do
   begin
      if i = 0 then
      begin
         if tk^.oper2 <> nil then
         begin
           s1 := tk^.oper2;
           stackVariable(tk^.oper2);
         end else
            s1 := Stack.pop();
         end else
            s1 := Stack.pop();

         case s1.Typ of
             mvtVariable, mvtGlobalVar: cashFuncParams[i] := s1.AsRealMemory;
             else
                cashFuncParams[i] := s1;
         end;
         //cashFuncParams[i] := s1.AsPtrMemory;

            {with cashFuncParams[i] do begin
              Clear;
              Val(s1, false);
              UseObjectAll;
            end;}
      end;
end;

procedure TOriEval.get1xParams();
begin
  if tk^.oper1 = nil then
  begin
      s1 := Stack.getTop();
      sRes := s1;
      if not toStack then
         Stack.discardAll;
         
  end else begin
      stackVariable(tk^.oper1);
      s1 := tk^.oper1;
      if toStack then
          sRes := Stack.push
      else
          Stack.discardAll;
  end;
end;


procedure TOriEval.callPlus();
begin
  get2xParams();
  if toStack then
    sRes.ValF( s1.AsFloat + s2.AsFloat );
end;

procedure TOriEval.callPlusAssign;
begin
  get2xParams;
  checkArrElement(s1);

  if s1.IsVar then
  begin
      mval := s1.AsRealMemory;
      with mval do begin

        if typ <> mvtDouble then
            ValF( AsFloat );

        Mem.dval := Mem.dval + s2.AsFloat;

        if toStack then sRes.Val( Mval, true );
      end;

  end else
      ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line)
end;

procedure TOriEval.callMinusAssign;
begin
  get2xParams;
  checkArrElement(s1);

  if s1.IsVar then
  begin
      mval := s1.AsRealMemory;
      with mval do begin

        if typ <> mvtDouble then
            ValF( AsFloat );

        Mem.dval := Mem.dval - s2.AsFloat;

        if toStack then sRes.Val( Mval,true );
      end;

  end else
      ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line)
end;

procedure TOriEval.callMulAssign;
begin
  get2xParams;
  checkArrElement(s1);

  if s1.IsVar then
  begin
      mval := s1.AsRealMemory;
      with mval do begin

        if typ <> mvtDouble then
            ValF( AsFloat );

        Mem.dval := Mem.dval * s2.AsFloat;

        if toStack then sRes.Val( Mval,true );
      end;

  end else
      ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line)
end;

procedure TOriEval.callDivAssign;
begin
  get2xParams;
  checkArrElement(s1);

  if s1.IsVar then
  begin
      mval := s1.AsRealMemory;
      with mval do begin

        if typ <> mvtDouble then
            ValF( AsFloat );

        Mem.dval := Mem.dval / s2.AsFloat;

        if toStack then sRes.Val( Mval,true );
      end;

  end else
      ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line)
end;

procedure TOriEval.callModAssign;
begin
  get2xParams;
  checkArrElement(s1);

  if s1.IsVar then
  begin
      mval := s1.AsRealMemory;
      with mval do begin

        if typ <> mvtInteger then
            ValF( AsInteger );

        Mem.lval := Mem.lval mod s2.AsInteger;

        if toStack then sRes.Val( Mval,true );
      end;

  end else
      ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line)
end;

procedure TOriEval.callConcatAssign;
  var
  s: MP_String;
  len: integer;
begin
  get2xParams;
  checkArrElement(s1);
  if s1.IsVar then
  begin
      mval := s1.AsRealMemory;

      if not mval.IsString then
        mval.Val( mval.AsString );


      S := s2.AsString;
      len := length(mval.Mem.str);

      SetLength(mval.Mem.str, len+length(s));
      Move(s[1],mval.Mem.str[len+1],length(s));

      if toStack then
        sRes.Val( Mval,true );
        
  end else
    ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line)
end;

procedure TOriEval.callXorAssign;
begin
  get2xParams;
  checkArrElement(s1);

  if s1.IsVar then
  begin
      mval := s1.AsRealMemory;
      with mval do begin

        if typ <> mvtInteger then
            ValF( AsInteger );

        Mem.lval := Mem.lval xor s2.AsInteger;

        if toStack then sRes.Val( Mval,true );
      end;

  end else
      ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line)
end;

procedure TOriEval.checkArrElement(s: TOriMemory);
   var
   i: integer;
begin
   if (S.typ = mvtHashValue) then
   begin
   
        mval := TOriMemory.GetMemory;
        mval.ValNull;

        arr := TOriTable(s.Mem.ptr);
        //mval.table := arr;

        arr.Add(s.Mem.str, mval, true);

        S.typ := mvtVariable;
        S.Mem.ptr := mval;
        if stackList <> nil then
        for i := 0 to stackList.Count - 1 do
         with TOriTable( stackList.Values^[ i ] ) do
         if Ref_Count < 1 then
           Use;
   end;
end;

procedure TOriEval.callMinus();
begin
  get2xParams;
  if toStack then
      sRes.ValF( s1.AsFloat - s2.AsFloat );
end;

procedure TOriEval.callUnarMinus();
begin
  get1xParams;
  if toStack then
      sRes.ValF( - s1.AsFloat );
end;

procedure TOriEval.callUnset;
   var
   i,id: integer;
   v,r: TOriMemory;
   arr: TOriTable;
   label 1;
begin
  if tk^.cnt > 0 then begin
  for i := tk^.cnt - 1 to 0 do
  begin
      if i = 0 then begin
          if tk^.oper2 = nil then
            s1 := Stack.Pop
          else
            s1 := tk^.oper2;
      end else
          s1 := Stack.Pop;

      if s1.IsString and (length(s1.Mem.str)>1) then
      begin
          if s1.Mem.str[1] = '$' then
          begin

              variables.Delete(Copy(s1.Mem.str,2,length(s1.Mem.str)-1));
              
          end else if s1.Mem.str[1] = '@' then
          begin

              GlobalVars.Delete(Copy(s1.Mem.str,2,length(s1.Mem.str)-1));
          end else begin
              s1.Mem.str := LowerCase(s1.Mem.str);
              
              if not ori_vmUserFunc.delNamedFunc( s1.Mem.str ) then
              ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line)
          end;
      end else if s1.typ = mvtVariable then begin

          if s1.Mem.ptr <> nil then
          begin
          v := s1.Mem.ptr;
          1:
          if v.table <> nil then
          begin
              id := TOriTable(v.table).byPointer(v);
              if id > -1 then
                  TOriTable(v.table).Delete(id);
          end;
          end;
          
      end else if s1.typ = mvtHash then begin
          // --WTF ???
          {if TOriTable(s1.Mem.ptr).parent <> nil then
          begin
                v := TOriMemory(TOriTable(s1.Mem.ptr).parent);
                goto 1;
          end;}
      end else begin

        if not ori_vmUserFunc.delNamedFunc( LowerCase(s1.AsString) ) then
              ErrPool.newError(errFatal,MSG_ERR_NOPTR,tk^.line);
      end;

  end;
  end;
end;


procedure TOriEval.callUseAs;
   var
   t1,t2: MP_String;
   NFunc: PNativeFunc;
   UFunc: TUserFunc;
   aClass: TOriClass;
begin
   t1 := tk^.oper1.Mem.str;
   t2 := tk^.oper2.Mem.str;

   NFunc := ori_vmNativeFunc.findByName(t2);
   if NFunc <> nil then
   begin
      ori_vmNativeFunc.addNativeFunc(t1, NFunc^.cnt, NFunc^.func);
      exit;
   end;

   UFunc := ori_vmUserFunc.findByName(LowerCase(t2));
   if UFunc <> nil then
   begin
      ori_vmUserFunc.addNamedFunc(t1, UFunc, Self.ErrPool);
      inc(UFunc.ref_count);
      exit;
   end;

   aClass := ori_vmClasses.findByName(t2);
   if aClass <> nil then
   begin
       ori_vmClasses.addNamedClass(t1, aClass, Self.ErrPool);
       inc(aClass.ref_count);
       exit;
   end;

   ErrPool.newError(errFatal, Format(MSG_ERR_NOFIND_IND,[t2]), tk^.line);
end;

procedure TOriEval.callMul();
begin
  get2xParams();
  if toStack then
    sRes.ValF(s1.AsFloat * s2.AsFloat);
end;

procedure TOriEval.callDiv();
begin
  get2xParams();
  if toStack then
    sRes.ValF(s1.AsFloat / s2.AsFloat);
end;

procedure TOriEval.callConcat();
begin
  get2xParams();
  if toStack then
    sRes.Val(s1.AsString + s2.AsString);
end;

procedure TOriEval.callXor();
begin
  get2xParams;
  if toStack then
    sRes.ValL(s1.AsInteger xor s2.AsInteger);
end;

procedure TOriEval.clearInfo;
begin
   Self.DefClass := nil;
   Self.variables.clear;
   Self.Stack.discardAll;
end;

constructor TOriEval.Create(const initStack: boolean = true);
   var
   i: integer;
begin
  code := nil;
  if initStack then
      Stack := TOriMemoryStack.Create
  else
      Stack := nil;

   cashFuncParams := TOriMemoryStack.Create;

   cashFuncReturn := TOriMemory.Create;
   cashFuncReturn.ValNull;

   Variables := TOriVariables.Create;
   ErrPool := TOriErrorPool.Create;

   stackList := nil;
   DebugFunc := nil;
end;

destructor TOriEval.destroy;
   var
   i: integer;
begin
   inherited Destroy;
   //clearInfo;

   cashFuncParams.Free;
   cashFuncReturn.Destroy;
   
    if Stack <> nil then
        Stack.Free;

    if stackList <> nil then
        stackList.Free;

    variables.Destroy;
    ErrPool.Destroy;
end;

procedure TOriEval.toExit;
begin
  FExit := true;
end;

procedure TOriEval.callMod();
begin
  get2xParams();
  if toStack then
     sRes.ValL( s1.AsInteger mod s2.AsInteger );
end;


procedure TOriEval.callMax();
begin
  get2xParams();
  if toStack then
     sRes.Val( s1.AsFloat > s2.AsFloat );
end;

procedure TOriEval.callMaxEq();
begin
  get2xParams();
   if toStack then
     sRes.Val( s1.AsFloat >= s2.AsFloat );
end;

procedure TOriEval.callMin();
begin
  get2xParams();
  if toStack then
     sRes.Val( s1.AsFloat < s2.AsFloat );
end;

procedure TOriEval.callMinEq();
begin
  get2xParams();
   if toStack then
     sRes.Val( s1.AsFloat <= s2.AsFloat );
end;

procedure TOriEval.callEqual();
begin
  get2xParams();
  if toStack then
      if s1.IsRealString then
          sRes.Val( s1.AsString = s2.AsString )
      else
          sRes.Val( s1.AsFloat = s2.AsFloat);
end;

procedure TOriEval.callEqualType;
  var
  t1,t2: MVT_Type;
begin
  get2xParams;
  if not toStack then exit;

  t1 := s1.GetRealType;
  t2 := s2.GetRealType;

  if t1 = mvtInteger then t1 := mvtDouble;
  if t2 = mvtInteger then t2 := mvtDouble;

  if t1 <> t2 then
        sRes.Val(false)
  else
       case t1 of
          mvtString,mvtPChar: sRes.Val(s1.AsString = s2.AsString);
          mvtDouble: sRes.Val(s1.AsFloat = s2.AsFloat);
          mvtBoolean: sRes.Val(s1.AsBoolean = s2.AsBoolean);
          else
              sRes.Val(false);
       end;
end;

procedure TOriEval.callForeach;
  var
  arr: TOriTable;
  label 1;
begin
  if prevTk^.ptr = nil then goto 1;

  arr := TOriTable(prevTk^.ptr);

  if (arr.Seek = arr.count-1) then
  begin

      if prevTk^.cnt > 0 then
      begin
           //unuseVMValue(variables.table.Values[ tk^.id ]);


           Variables.Value[ tk^.id ].Clear;


          //variables.table.Values[ tk^.id ] := createVMValue(vtNone);
      end;

      Dec(arr.ref_count);
      1:
      Stack.Push.Val(false);
      exit;
  end
  else begin
      Stack.Push.Val(true);
  end;

  if tk^.id = -1 then
     tk^.id := variables.getVariable(tk^.oper1.Mem.str);

  if prevTk^.cnt > 0 then
      Variables.setVariable(tk^.oper1.Mem.str, arr.next,true)
  else begin

    Variables.Value[ tk^.id ].Val( arr.Next, false );
  end;
  
  //variables.table.setValue(tk^.oper1^.str, arr.Values[arr.aSeek]);

  if tk^.oper2 <> nil then begin
    prevTk^.id := variables.getVariable(tk^.oper2.Mem.str);
    Variables.Value[ prevTk^.id ].Val( arr.Names.Values^[arr.Seek] );
    
    {MVAL_STRING( PVMValue(variables.table.Values.V^[ prevTk^.id ]),
       arr.Names.Values^[arr.aSeek] );}
  end;
end;

procedure TOriEval.callForeachInit;
  var
  arr: TOriTable;
begin
  get1xParams;
  case s1.typ of
      mvtHash: arr := TOriTable(s1.Mem.ptr);
      mvtVariable,mvtGlobalVar:
          begin
                mval := s1.AsRealMemory;
                if mval.typ = mvtHash then
                  arr := TOriTable(mval.Mem.ptr)
                else begin
                  tk^.ptr := nil;
                  ErrPool.newError(errWarning,MSG_ERR_EXPR_ARR,tk^.line);
                  exit;
                end;
          end;
  end;

  tk^.ptr := arr;
        with arr do begin
            Seek := -1;
            inc(ref_count);
        end;
end;


procedure TOriEval.callNewArray;
   var
   i: integer;
   arr: TOriTable;
begin
  arr := TOriTable.CreateInManager;
  if tk^.cnt > 0 then
  begin
  cashFuncParams.Count := 0;
  cashFuncParams.NewSize(tk^.cnt);
  
  for i := tk^.cnt - 1 downto 0 do
  begin
      if i = 0 then begin
          if tk^.oper2 = nil then
             s1 := Stack.pop
          else begin
            s1 := tk^.oper2;
            stackVariable(s1);
          end;
      end else
          s1 := Stack.pop;

      if s1.typ = mvtHashValue then
          Stack.discard;

      cashFuncParams.Add(s1);
  end;

  for i := cashFuncParams.Count - 1 downto 0 do
  begin
  s1 := cashFuncParams[i];
  
             if s1.typ = mvtHashValue then
             begin
                mval := TOriMemory.GetMemory;
                mval.val( s1.AsMemory, false );
                arr[s1.Mem.Str] := mval;

                //assignVMValue(PStackValue(s1^.ptr), v, false);
                // --to
                //arr.setValue(s1^.str, v);
             end else begin
                mval := TOriMemory.GetMemory;
                mval.Val(s1, false);
                arr.Add(mval);
                //arr.Add();
                // --todo
                //arr.addValue(v);
             end;
             mval.UseObjectAll;
  end;
  end;

      Stack.push.ValTable( arr );
end;

procedure TOriEval.callNoequal();
begin
  get2xParams();
  if toStack then
  if s1.IsRealString then
    sRes.Val( s1.AsString <> s2.AsString )
  else
    sRes.Val( s1.AsFloat <> s2.AsFloat );
end;


procedure TOriEval.callNoequalType;
  var
  t1,t2: MVT_Type;
begin
  get2xParams;
  if not toStack then exit;

  t1 := s1.GetRealType;
  t2 := s2.GetRealType;

  if t1 = mvtInteger then t1 := mvtDouble;
  if t2 = mvtInteger then t2 := mvtDouble;

  if t1 <> t2 then
        sRes.Val(true)
  else
       case t1 of
          mvtString,mvtPChar: sRes.Val(s1.AsString <> s2.AsString);
          mvtDouble: sRes.Val(s1.AsFloat <> s2.AsFloat);
          mvtBoolean: sRes.Val(s1.AsBoolean <> s2.AsBoolean);
          else
              sRes.Val(false);
       end;
end;

procedure TOriEval.callNot();
begin
  get1xParams();
  if toStack then
    sRes.Val( not s1.AsBoolean );
end;


procedure TOriEval.callBitAnd;
begin
  get2xParams;
  if toStack then
    sRes.ValL( s1.AsInteger and s2.AsInteger );
end;

procedure TOriEval.callBitNot;
begin
  get1xParams;
  if toStack then
    sRes.ValL( not s1.AsInteger );
end;


procedure TOriEval.callBitOr;
begin
  get2xParams;
  if toStack then
    sRes.ValL( s1.AsInteger or s2.AsInteger );
end;

procedure TOriEval.AddToStackList(p: pointer);
begin
  if stackList = nil then
    stackList := TPtrArray.Create;
  stackList.Add(p); 
end;

procedure TOriEval.callAnd();
begin
  get2xParams;
  if toStack then
    sRes.Val( s1.AsBoolean and s2.AsBoolean );
end;

procedure TOriEval.callOr();
begin
  get2xParams;
  if toStack then
    sRes.Val( s1.AsBoolean or s2.AsBoolean );
end;


procedure TOriEval.callIF(var i: integer);
begin
  if (sRes.typ = mvtBoolean) and sRes.Mem.bval then
      inc(i)
  else
    if sRes.AsBoolean then
      Inc(i);
end;

procedure TOriEval.callNotIF(var i: integer); 
begin
  //if not stackToBool(Stack.pop) then  WTF ???
  if sRes.AsBoolean then
      Inc(i);
end;

initialization
  DecimalSeparator := '.';

end.
