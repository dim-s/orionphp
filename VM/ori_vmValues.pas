unit ori_vmValues;

// ������ ������ ��� ���������, ������� � �������
//{$mode objfpc}
{$H+}
{$i './ori_Options.inc'}

interface

uses
  Classes, SysUtils,
  ori_Types,
  ori_FastArrays;

     var
          MANHashes, MANHashes_f,
          MANFuncs, MANFuncs_f: TPtrArray; // ������ ��������� �����...

          MANValues: TPtrArray;

implementation

     uses
     ori_vmTables, ori_vmVariables, ori_vmUserFunc;


initialization
   MANValues := TPtrArray.Create;

finalization
   MANValues.Free;

end.
