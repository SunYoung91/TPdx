{ Этот файл был автоматически создан Lazarus. Н�
  � редактировать!
  Исходный код используется только для комп�
    �ляции и установки пакета.
 }

unit paradoxlaz; 

interface

uses
  RegisterPDX, conv, pdx, LazarusPackageIntf;

implementation

procedure Register; 
begin
  RegisterUnit('RegisterPDX', @RegisterPDX.Register); 
end; 

initialization
  RegisterPackage('paradoxlaz', @Register); 
end.
