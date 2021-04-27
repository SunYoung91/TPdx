{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Kudriavtsev Pavel

  This unit registers the TPdx component of the FCL.
}
unit RegisterPDX;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, LazarusPackageIntf, PropEdits, pdx;

resourcestring
  pdxAllDbasefiles = 'Paradox Files';

procedure Register;

implementation

type

  { TPdxFileNamePropertyEditor }

  TPdxFileNamePropertyEditor=class(TFileNamePropertyEditor)
  protected
    function GetFilter: String; override;
  end;

  { TPdxLangEditor }

  TPdxLangPropertyEditor = class(TStringProperty)
  public
    function  GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    function  GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TPdxLangEditor }

function TPdxLangPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList];
end;

procedure TPdxLangPropertyEditor.GetValues(Proc: TGetStrProc);
var
  i: integer;

begin
  for i := 1 to 118 do
    Proc(PdxLangTable[i].Name);
end;

function TPdxLangPropertyEditor.GetValue: string;
begin
  Result := GetStrValue;
end;

procedure TPdxLangPropertyEditor.SetValue(const Value: string);
begin
  SetStrValue(Value);
end;

{ TPdxFileNamePropertyEditor }

function TPdxFileNamePropertyEditor.GetFilter: String;
begin
  Result := pdxAllDbaseFiles+' (*.db)|*.db;*.DB';
  Result:= Result+ '|'+ inherited GetFilter;
end;

procedure RegisterUnitPdx;
begin
  RegisterComponents('Data Access',[TPdx]);

  RegisterPropertyEditor(TypeInfo(string),
    TPdx, 'TableName', TPdxFileNamePropertyEditor);
    
  RegisterPropertyEditor(TypeInfo(string),
    TPdx, 'Language', TPdxLangPropertyEditor);
end;

procedure Register;
begin
  RegisterUnit('pdx', @RegisterUnitPdx);
end;

initialization
  {$i registerpdx.lrs}
end.


