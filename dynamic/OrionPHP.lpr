library OrionPHP;


// IN PROGRESS!!!

{$IFDEF WINDOWS}{$R OrionPHP.rc}{$ENDIF}

//{$R *.res}

uses
  SysUtils,
  Classes,
  vmShortApi;

exports
  ori_version,

  ori_newStr,
  ori_freeStr,

  ori_init,
  ori_final,
  ori_create,
  ori_destroy,
  ori_evalfile,
  ori_evalcode,
  ori_err_count,
  ori_err_get,

  ori_func_add,
  ori_module_add,

  ori_set_var,
  ori_get_var,

  ori_compilecode,
  ori_evalcompiled,

  ori_addconst_int,
  ori_addconst_float,
  ori_addconst_str,
  ori_addconst_bool,
  ori_const_exists,
  ori_getconst_int,
  ori_getconst_float,
  ori_getconst_str,
  ori_getconst_bool,

  vm_value_create,
  vm_value_destroy,
  vm_value_type,
  vm_value_ref,
  vm_value_unset,
  vm_value_use,
  vm_value_unuse,
  vm_value_free,
  vm_value_assign,
  vm_value_clear,
  vm_value_set_null,
  vm_value_set_int,
  vm_value_set_float,
  vm_value_set_bool,
  vm_value_set_str,
  vm_value_set_arr,
  vm_value_set_func,
  vm_value_set_ptr,
  vm_value_get_int,
  vm_value_get_float,
  vm_value_get_bool,
  vm_value_get_str,
  vm_value_get_ptr,
  vm_value_realptr;

end.

