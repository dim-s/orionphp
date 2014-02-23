unit OriWrap;

// IN PROGRESS !!!!

{$IFDEF FPC}
  {$MODE DELPHI}
  {$MACRO ON}
  {$PACKRECORDS C}
  {$IFDEF LINUX}
    {$DEFINE LINUX_OR_DARWIN}
  {$ENDIF}
  {$IFDEF DARWIN}
    {$DEFINE LINUX_OR_DARWIN}
  {$ENDIF}
{$ENDIF}

{$IFDEF MSWINDOWS}
  {$DEFINE WINDOWS}
{$ENDIF}

interface

  uses SysUtils, vmCrossValues
  {$IFDEF DARWIN}
  ,MacOSAll;
  {$ENDIF}
  ;
  
  function ORION_LOAD(LibName: AnsiString): Boolean;
  procedure ORION_UNLOAD();
  
  {$IFDEF LINUX_OR_DARWIN}
  function dlopen ( Name : PChar; Flags : longint) : Pointer; cdecl; external 'dl';
  function dlclose( Lib : Pointer) : Longint; cdecl; external 'dl';
  function dlsym  ( Lib : Pointer; Name : Pchar) : Pointer; cdecl; external 'dl';
  {$ENDIF}
  
  {$IFDEF WINDOWS}
  function dlopen ( lpLibFileName : PAnsiChar) : HMODULE; stdcall; external 'kernel32.dll' name 'LoadLibraryA';
  function dlclose( hLibModule : HMODULE ) : Boolean; stdcall; external 'kernel32.dll' name 'FreeLibrary';
  function dlsym  ( hModule : HMODULE; lpProcName : PAnsiChar) : Pointer; stdcall; external 'kernel32.dll' name 'GetProcAddress';
  {$ENDIF}

      
  var
    LIB_HANDLE: {$IFDEF LINUX_OR_DARWIN} Pointer {$ENDIF} {$IFDEF WINDOWS} Cardinal {$ENDIF};
    {$IFDEF DARWIN}
    mainBundle   : CFBundleRef;
    tmpCFURLRef  : CFURLRef;
    tmpCFString  : CFStringRef;
    tmpPath      : array[ 0..8191 ] of Char;
    outItemHit   : SInt16;
    {$ENDIF}


  var




// ORI Utils
       ori_version: function (): longint; cdecl;

       ori_newStr: function (size: cardinal): PAnsiChar; cdecl;
       ori_freeStr: procedure (var s: PAnsiChar); cdecl;

// ORI Main
       ori_init: function (): byte; cdecl;
       ori_final: function (): byte; cdecl;

       ori_create: function (): pointer; cdecl;
       ori_destroy: function (const o: pointer): byte; cdecl;
       ori_evalfile: function (const o: pointer; const fileName: PAnsiChar): byte; cdecl;
       ori_evalcode: function (const o: pointer; const Script: PAnsiChar; const Len: cardinal): byte; cdecl;
       ori_err_count: function (o: pointer): longint; cdecl;
       ori_err_get: procedure (o: pointer; const Num: longint; var aLine: longint; var aTyp: byte; var aMsg: PAnsiChar; var aFileName: PAnsiChar); cdecl;

// ORI Variables
       ori_set_var: procedure (o: pointer; const Name: PAnsiChar; val: Pointer); cdecl;
       ori_get_var: function (o: pointer; const Name: PAnsiChar): Pointer; cdecl;

// ORI COnstants
       ori_addconst_int: function (const Name: PAnsiChar; const val: MP_Int): byte; cdecl;
       ori_addconst_float: function (const Name: PAnsiChar; const val: MP_Float): byte; cdecl;
       ori_addconst_str: function (const Name: PAnsiChar; const val: PAnsiChar; const len: cardinal): byte; cdecl;
       ori_addconst_bool: function (const Name: PAnsiChar; const val: byte): byte; cdecl;
       ori_const_exists: function (const Name: PAnsiChar): byte; cdecl;

       ori_getconst_int: function (const Name: PAnsiChar): MP_Int; cdecl;
       ori_getconst_float: function (const Name: PAnsiChar): MP_Float; cdecl;
       ori_getconst_str: procedure (const Name: PAnsiChar; var Result: PAnsiChar); cdecl;
       ori_getconst_bool: function (const Name: PAnsiChar): byte; cdecl;

// ORI Byte code
       ori_compilecode: function (const O: Pointer; const script: PAnsiChar; const len: cardinal; var ResultLen: longint): PAnsiChar; cdecl;
       ori_compilefile: function (const O: Pointer; const fileName: PAnsiChar; var ResultLen: integer): PAnsiChar; cdecl;
       ori_evalcompiled: function (const bytecode: PAnsiChar; const Len: cardinal): Pointer; cdecl;

// ORI Modules and funcs
       ori_func_add: procedure (func: Pointer; Name: PAnsiChar; const Cnt: cardinal); cdecl;
       ori_module_add: procedure (func: Pointer); cdecl;

// Ori Values
       vm_value_create: function (const inMan: boolean): pointer; cdecl;
       vm_value_destroy: procedure (v: pointer); cdecl;
       vm_value_type: function (v: pointer): byte; cdecl;
       vm_value_ref: function (v: pointer): word; cdecl;
       vm_value_unset: procedure (v: pointer); cdecl;
       vm_value_free: procedure (v: pointer); cdecl;
       vm_value_clear: procedure (v: pointer); cdecl;

       vm_value_use: procedure (v: pointer); cdecl;
       vm_value_unuse: procedure (v: pointer); cdecl;

       vm_value_assign: procedure (v, Source: pointer); cdecl;
       vm_value_set_null: procedure (v: pointer); cdecl;
       vm_value_set_int: procedure (v: pointer; const L: MP_Int); cdecl;
       vm_value_set_float: procedure (v: pointer; L: MP_Float); cdecl;
       vm_value_set_bool: procedure (v: pointer; const B: byte); cdecl;
       vm_value_set_str: procedure (v: pointer; s: PAnsiChar; const len: longint); cdecl;
       vm_value_set_arr: procedure (v: pointer; P: Pointer); cdecl;
       vm_value_set_func: procedure (v: pointer; P: Pointer); cdecl;
       vm_value_set_ptr: procedure (v: pointer; P: Pointer); cdecl;

       vm_value_get_int: function (v: pointer): MP_Int; cdecl;
       vm_value_get_float: function (v: pointer): MP_Float; cdecl;
       vm_value_get_bool: function (v: pointer): byte; cdecl;
       vm_value_get_str: function (v: pointer; var ResultLen: longint): PAnsiChar; cdecl;
       vm_value_get_ptr: function (v: pointer): Pointer; cdecl;

       vm_value_realptr: function (const v: pointer): pointer; cdecl;

// VM Constants




implementation


function ORION_LOAD(LibName: AnsiString): Boolean;
begin
  {$IFDEF DARWIN}
  mainBundle  := CFBundleGetMainBundle;
  tmpCFURLRef := CFBundleCopyBundleURL( mainBundle );
  tmpCFString := CFURLCopyFileSystemPath( tmpCFURLRef, kCFURLPOSIXPathStyle );
  CFStringGetFileSystemRepresentation( tmpCFString, @tmpPath[ 0 ], 8192 );
  mainPath    := tmpPath + '/Contents/';
  LibName     := mainPath + 'Frameworks/' + LibName;
  {$ENDIF}
  LIB_HANDLE := dlopen( PAnsiChar( LibName ) {$IFDEF LINUX_OR_DARWIN}, $001 {$ENDIF} );
  {$IFDEF LINUX_OR_DARWIN} 
  Result := LIB_HANDLE <> nil;
  {$ELSE}
  Result := LIB_HANDLE <> 0;
  {$ENDIF}
  if Result then
  begin
// ORI Utils
      ori_version := dlsym(LIB_HANDLE, 'ori_version');
      ori_newStr := dlsym(LIB_HANDLE, 'ori_newStr');
      ori_freeStr := dlsym(LIB_HANDLE, 'ori_freeStr');
// ORI Main
      ori_init := dlsym(LIB_HANDLE, 'ori_init');
      ori_final := dlsym(LIB_HANDLE, 'ori_final');
      ori_create := dlsym(LIB_HANDLE, 'ori_create');
      ori_destroy := dlsym(LIB_HANDLE, 'ori_destroy');
      ori_evalfile := dlsym(LIB_HANDLE, 'ori_evalfile');
      ori_evalcode := dlsym(LIB_HANDLE, 'ori_evalcode');
      ori_err_count := dlsym(LIB_HANDLE, 'ori_err_count');
      ori_err_get := dlsym(LIB_HANDLE, 'ori_err_get');
// ORI Variables
      ori_set_var := dlsym(LIB_HANDLE, 'ori_set_var');
      ori_get_var := dlsym(LIB_HANDLE, 'ori_get_var');
// ORI COnstants
      ori_addconst_int := dlsym(LIB_HANDLE, 'ori_addconst_int');
      ori_addconst_float := dlsym(LIB_HANDLE, 'ori_addconst_float');
      ori_addconst_str := dlsym(LIB_HANDLE, 'ori_addconst_str');
      ori_addconst_bool := dlsym(LIB_HANDLE, 'ori_addconst_bool');
      ori_const_exists := dlsym(LIB_HANDLE, 'ori_const_exists');
      ori_getconst_int := dlsym(LIB_HANDLE, 'ori_getconst_int');
      ori_getconst_float := dlsym(LIB_HANDLE, 'ori_getconst_float');
      ori_getconst_str := dlsym(LIB_HANDLE, 'ori_getconst_str');
      ori_getconst_bool := dlsym(LIB_HANDLE, 'ori_getconst_bool');
// ORI Byte code
      ori_compilecode := dlsym(LIB_HANDLE, 'ori_compilecode');
      ori_compilefile := dlsym(LIB_HANDLE, 'ori_compilefile');
      ori_evalcompiled := dlsym(LIB_HANDLE, 'ori_evalcompiled');
// ORI Modules and funcs
      ori_func_add := dlsym(LIB_HANDLE, 'ori_func_add');
      ori_module_add := dlsym(LIB_HANDLE, 'ori_module_add');
// Ori Values
      vm_value_create := dlsym(LIB_HANDLE, 'vm_value_create');
      vm_value_destroy := dlsym(LIB_HANDLE, 'vm_value_destroy');
      vm_value_type := dlsym(LIB_HANDLE, 'vm_value_type');
      vm_value_ref := dlsym(LIB_HANDLE, 'vm_value_ref');
      vm_value_unset := dlsym(LIB_HANDLE, 'vm_value_unset');
      vm_value_free := dlsym(LIB_HANDLE, 'vm_value_free');
      vm_value_clear := dlsym(LIB_HANDLE, 'vm_value_clear');
      vm_value_use := dlsym(LIB_HANDLE, 'vm_value_use');
      vm_value_unuse := dlsym(LIB_HANDLE, 'vm_value_unuse');
      vm_value_assign := dlsym(LIB_HANDLE, 'vm_value_assign');
      vm_value_set_null := dlsym(LIB_HANDLE, 'vm_value_set_null');
      vm_value_set_int := dlsym(LIB_HANDLE, 'vm_value_set_int');
      vm_value_set_float := dlsym(LIB_HANDLE, 'vm_value_set_float');
      vm_value_set_bool := dlsym(LIB_HANDLE, 'vm_value_set_bool');
      vm_value_set_str := dlsym(LIB_HANDLE, 'vm_value_set_str');
      vm_value_set_arr := dlsym(LIB_HANDLE, 'vm_value_set_arr');
      vm_value_set_func := dlsym(LIB_HANDLE, 'vm_value_set_func');
      vm_value_set_ptr := dlsym(LIB_HANDLE, 'vm_value_set_ptr');
      vm_value_get_int := dlsym(LIB_HANDLE, 'vm_value_get_int');
      vm_value_get_float := dlsym(LIB_HANDLE, 'vm_value_get_float');
      vm_value_get_bool := dlsym(LIB_HANDLE, 'vm_value_get_bool');
      vm_value_get_str := dlsym(LIB_HANDLE, 'vm_value_get_str');
      vm_value_get_ptr := dlsym(LIB_HANDLE, 'vm_value_get_ptr');
      vm_value_realptr := dlsym(LIB_HANDLE, 'vm_value_realptr');
// VM Constants

  end;
end;

procedure ORION_UNLOAD();
begin
  dlclose( LIB_HANDLE );
end;

end.