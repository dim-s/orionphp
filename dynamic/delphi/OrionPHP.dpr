library OrionPHP;


// IN PROGRESS!!!

{$I ../../VM/ori_Options.inc}

uses
  SysUtils,
  Classes,
  Orion,
  ori_vmShortApi;

{$R *.res}

const
  {$IFDEF DARWIN}
  prefix = '_';
  {$ELSE}
  prefix = '';
  {$ENDIF}



 exports
    ori_version name prefix + 'ori_version',

    ori_newStr name prefix + 'ori_newStr',
    ori_freeStr name prefix + 'ori_freeStr',

    ori_init name prefix + 'ori_init',
    ori_final name prefix + 'ori_final',
    ori_create name prefix + 'ori_create',
    ori_destroy name prefix + 'ori_destroy',
    ori_evalfile name prefix + 'ori_evalfile',
    ori_evalcode name prefix + 'ori_evalcode',
    ori_err_count name prefix + 'ori_err_count',
    ori_err_get name prefix + 'ori_err_get',

    ori_func_add name prefix + 'ori_func_add',
    ori_module_add name prefix + 'ori_module_add',

    ori_set_var name prefix + 'ori_set_var',
    ori_get_var name prefix + 'ori_get_var',

    ori_compilecode name prefix + 'ori_compilecode',
    ori_evalcompiled name prefix + 'ori_evalcompiled',

    ori_addconst_int name prefix + 'ori_addconst_int',
    ori_addconst_float name prefix + 'ori_addconst_float',
    ori_addconst_str name prefix + 'ori_addconst_str',
    ori_addconst_bool name prefix + 'ori_addconst_bool',
    ori_const_exists name prefix + 'ori_const_exists',
    ori_getconst_int name prefix + 'ori_getconst_int',
    ori_getconst_float name prefix + 'ori_getconst_float',
    ori_getconst_str name prefix + 'ori_getconst_str',
    ori_getconst_bool name prefix + 'ori_getconst_bool',

    vm_value_create name prefix + 'vm_value_create',
    vm_value_destroy name prefix + 'vm_value_destroy',
    vm_value_type name prefix + 'vm_value_type',
    vm_value_ref name prefix + 'vm_value_ref',
    vm_value_unset name prefix + 'vm_value_unset',
    vm_value_use name prefix + 'vm_value_use',
    vm_value_unuse name prefix + 'vm_value_unuse',
    vm_value_free name prefix + 'vm_value_free',
    vm_value_assign name prefix + 'vm_value_assign',
    vm_value_clear name prefix + 'vm_value_clear',
    vm_value_set_null name prefix + 'vm_value_set_null',
    vm_value_set_int name prefix + 'vm_value_set_int',
    vm_value_set_float name prefix + 'vm_value_set_float',
    vm_value_set_bool name prefix + 'vm_value_set_bool',
    vm_value_set_str name prefix + 'vm_value_set_str',
    vm_value_set_arr name prefix + 'vm_value_set_arr',
    vm_value_set_func name prefix + 'vm_value_set_func',
    vm_value_set_ptr name prefix + 'vm_value_set_ptr',
    vm_value_get_int name prefix + 'vm_value_get_int',
    vm_value_get_float name prefix + 'vm_value_get_float',
    vm_value_get_bool name prefix + 'vm_value_get_bool',
    vm_value_get_str name prefix + 'vm_value_get_str',
    vm_value_get_ptr name prefix + 'vm_value_get_ptr',
    vm_value_realptr name prefix + 'vm_value_realptr';

end.
