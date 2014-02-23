unit ori_CoreMath;


//{$mode objfpc}
{$H+}
{$WARNINGS OFF}

interface

uses
  SysUtils,
  Math,
  ori_Math,
  ori_Types,
  ori_vmCrossValues,

  ori_StrUtils,
  ori_vmTypes,
  ori_Errors,
  ori_vmValues,
  ori_StrConsts,
  ori_vmNativeFunc,
  ori_vmConstants,
  ori_vmMemory;

  const
    RAND_MAX = High(Longint);

implementation

procedure x_srand(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
    // srand ^_^
    if cnt > 0 then
      RandSeed := pr[0].AsInteger
    else
      RandSeed := Random(RAND_MAX);
      
    Randomize;
end;

procedure x_rand(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;

 {$ifdef fpc}
 procedure RandomRange(const AFrom, ATo: Integer): Integer;
 begin
  if AFrom > ATo then
    Result := Random(AFrom - ATo) + ATo
  else
    Result := Random(ATo - AFrom) + AFrom;
  end;
 {$endif}
begin
case cnt of
  0: Return.ValL( Random(RAND_MAX) );
  1: Return.ValL( Random(pr[0].AsInteger) );
  2: Return.ValL( RandomRange(pr[0].AsInteger,pr[1].AsInteger) );
end;
end;

procedure x_abs(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
 Return.ValF( Abs(pr[0].AsFloat) );
end;


procedure x_acos(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  try
    Return.ValF( Math.ArcCos(pr[0].AsFloat) );
  except
    Return.ValF(NaN);
  end;
end;


procedure x_acosh(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
try
Return.ValF( Math.ArcCosh(pr[0].AsFloat) );
except
    Return.ValF(NaN);
  end;
end;


procedure x_asin(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  try
  Return.ValF( Math.ArcSin(pr[0].AsFloat) );
  except Return.ValF(NaN); end;
end;

procedure x_asinh(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
try
  Return.ValF( Math.ArcSinh(pr[0].AsFloat) );
  except Return.ValF(NaN); end;
end;

procedure x_atan2(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
try
  Return.ValF( Math.ArcTan2(pr[0].AsFloat, pr[1].AsFloat) );
  except Return.ValF(NaN); end;
end;

procedure x_atan(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
try
  Return.ValF( ArcTan(pr[0].AsFloat) );
  except Return.ValF(NaN); end;
end;

procedure x_atanh(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
try
  Return.ValF( ArcTanh(pr[0].AsFloat) );
  except Return.ValF(NaN); end;
end;

procedure x_base_convert(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val(
  ori_Math.base_convert(pr[0].AsString, pr[1].AsInteger, pr[2].AsInteger)
  );
end;

procedure x_bindec(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( ori_Math.bindec( pr[0].AsString ) );
end;

procedure x_decbin(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_Math.decbin( pr[0].AsInteger ) );
end;

procedure x_dechex(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_Math.dechex( pr[0].AsInteger ) );
end;

procedure x_hexdec(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( ori_Math.hexdec( pr[0].AsString ) );
end;

procedure x_decoct(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_Math.decoct( pr[0].AsInteger ) );
end;

procedure x_octdec(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( ori_Math.octdec( pr[0].AsString ) );
end;

procedure x_sin(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Sin(pr[0].AsFloat) );
end;

procedure x_cos(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Cos(pr[0].AsFloat) );
end;

procedure x_cosh(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Cosh(pr[0].AsFloat) );
end;

procedure x_tan(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Tan(pr[0].AsFloat) );
end;

procedure x_pi(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
 Return.ValF( Pi );
end;

procedure x_pow(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
 Return.ValF( Power(pr[0].AsFloat,pr[1].AsFloat) );
end;

procedure x_round(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  precision: Integer;
begin
 if cnt = 1 then
    Return.ValL( Round(pr[0].AsFloat) )
 else begin
    precision := pr[1].AsInteger;
    if (precision > 37) or (precision < 0) then precision := 0;

    Return.ValF( RoundTo(pr[0].AsFloat,precision) );
 end;
end;

procedure x_floor(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( Floor(pr[0].AsFloat) );
end;

procedure x_ceil(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( Ceil(pr[0].AsFloat) );
end;

procedure x_sqrt(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Sqrt(pr[0].AsFloat) );
end;

procedure x_sqr(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Sqr(pr[0].AsFloat) );
end;

procedure x_exp(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Exp(pr[0].AsFloat) );
end;

procedure x_fmod(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  x, y: MP_Float;
begin
  x := pr[0].AsFloat;
  y := pr[1].AsFloat;
  Return.ValF( x - y * Trunc(x / y) );
end;

procedure x_rad2deg(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( RadToDeg(pr[0].AsFloat) );
end;

procedure x_deg2rad(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( DegToRad(pr[0].AsFloat) );
end;

procedure x_log10(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Log10(pr[0].AsFloat) );
end;

procedure x_log1p(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( LnXP1(pr[0].AsFloat) );
end;

procedure x_log(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( Ln(pr[0].AsFloat) );
end;

procedure x_logn(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValF( LogN(pr[0].AsFloat, pr[1].AsFloat) );
end;

procedure x_is_nan(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( IsNan(pr[0].AsFloat) );
end;

procedure x_is_infinite(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( IsInfinite(pr[0].AsFloat) );
end;

procedure x_is_finite(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( not IsInfinite(pr[0].AsFloat) );
end;


procedure x_hypot(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  a,b: MP_Float;
begin
  a := pr[0].AsFloat;
  b := pr[1].AsFloat;
  Return.ValF( Sqrt(a*a + b*b) );
end;



function loadModule(init: boolean): byte;
begin
    if init then
    begin
          Randomize;

          addNativeFunc('rand',0,@x_rand);
            addNativeFunc('mt_rand',0,@x_rand);
            addNativeFunc('lcg_value',0,@x_rand);
          addNativeFunc('srand',0,@x_srand);
            addNativeFunc('mt_srand',0,@x_srand);

          addNativeFunc('abs',1,@x_abs);
          addNativeFunc('acos',1,@x_acos);
          addNativeFunc('acosh',1,@x_acosh);
          addNativeFunc('asin',1,@x_asin);
          addNativeFunc('asinh',1,@x_asinh);
          addNativeFunc('atan2',2,@x_atan2);
          addNativeFunc('atan',1,@x_atan);
          addNativeFunc('atanh',1,@x_atanh);
          addNativeFunc('base_convert',3,@x_base_convert);
          addNativeFunc('bindec',1,@x_bindec);
          addNativeFunc('ceil',1,@x_ceil);
          addNativeFunc('cos',1,@x_cos);
          addNativeFunc('cosh',1,@x_cosh);
          addNativeFunc('decbin',1,@x_decbin);
          addNativeFunc('dechex',1,@x_dechex);
          addNativeFunc('decoct',1,@x_decoct);

          addNativeFunc('hexdec',1,@x_hexdec);
          addNativeFunc('octdec',1,@x_octdec);

          addNativeFunc('sin',1,@x_sin);

          addNativeFunc('tan',1,@x_cos);
          addNativeFunc('pi', 0,@x_pi);
          addNativeFunc('pow',2,@x_pow);
          addNativeFunc('round',1,@x_round);
          addNativeFunc('floor',1,@x_floor);

          addNativeFunc('sqrt',1,@x_sqrt);
          addNativeFunc('sqr',1,@x_sqr);
          addNativeFunc('exp',1,@x_exp);
          addNativeFunc('fmod',1,@x_fmod);

          addNativeFunc('rad2deg',1,@x_rad2deg);
          addNativeFunc('deg2rad',1,@x_deg2rad);

          addNativeFunc('hypot',1,@x_hypot);
          addNativeFunc('log10',1,@x_log10);
          addNativeFunc('log1p',1,@x_log1p);
          addNativeFunc('log',1,@x_log);
          addNativeFunc('logn',2,@x_logn);

          addNativeFunc('is_nan',1,@x_is_nan);
          addNativeFunc('is_finite',1,@x_is_finite);
          addNativeFunc('is_infinite',1,@x_is_infinite);

          with VM_Constants do begin
            addConstant('M_PI', 3.14159265358979323846);
            addConstant('M_E', 2.7182818284590452354);
            addConstant('M_LOG2E', 1.4426950408889634074);
            addConstant('M_LOG10E', 0.43429448190325182765);
            addConstant('M_LN2', 0.69314718055994530942);
            addConstant('M_LN10', 2.30258509299404568402);
            addConstant('M_PI_2', 1.57079632679489661923);
            addConstant('M_PI_4', 0.78539816339744830962);
            addConstant('M_1_PI', 0.31830988618379067154);
            addConstant('M_2_PI', 0.63661977236758134308);
            addConstant('M_SQRTPI', 1.77245385090551602729);
            addConstant('M_2_SQRTPI', 1.12837916709551257390);
            addConstant('M_SQRT2', 1.41421356237309504880);
            addConstant('M_SQRT3', 1.73205080756887729352);
            addConstant('M_SQRT1_2', 0.70710678118654752440);
            addConstant('M_LNPI', 1.14472988584940017414);
            addConstant('M_EULER', 0.57721566490153286061);

            addConstant('RAND_MAX',RAND_MAX);
          end;
    end;
end;


initialization
   addNativeModule(@loadModule);




end.
