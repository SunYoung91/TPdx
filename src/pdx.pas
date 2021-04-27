{***************************************************************}
{                                                               }
{         Parodox Component for Lazarus Version 0.7             }
{                                                               }
{ Copyright (c) 2007-2009 Kudriavtsev Pavel (paulkudr@mail.ru)  }
{ Copyright (c) 2007-2008 Gerry Kleinpenning                    }
{ Copyright (c) 2009      Sergey (User32!!!)                    }
{                                                               }
{                                                               }
{     DataSet компонент для чтения файлов paradox.              }
{                                                               }
{     - Файлы открываются только для чтения;                    }
{     - Поддерживаются Blob-поля (не кэшируются);               }
{     - Перекодировка из cp1251 и cp866 в UTF8, cp1251, koi8r;  }
{     - Не поддерживаются индексы.                              }
{                                                               }
{     Roadmap                                                   }
{                                                               }
{     - Поддержка индексов;                                     }
{                                                               }
{  Добавление возможности записи пока не планируется.           }
{                                                               }
{***************************************************************}
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
}
unit pdx;

{$IFDEF FPC}
  {$mode DELPHI}
{$ENDIF}

{$H+}

interface

uses
  DB, Classes, SysUtils, Forms, conv;

const
  { Paradox codes for field types }
  pxfAlpha        = $01;
  pxfDate         = $02;
  pxfShort        = $03;
  pxfLong         = $04;
  pxfCurrency     = $05;
  pxfNumber       = $06;
  pxfLogical      = $09;
  pxfMemoBLOb     = $0C;
  pxfBLOb         = $0D;
  pxfFmtMemoBLOb  = $0E;
  pxfOLE          = $0F;
  pxfGraphic      = $10;
  pxfTime         = $14;
  pxfTimestamp    = $15;
  pxfAutoInc      = $16;
  pxfBCD          = $17;
  pxfBytes        = $18;

type

{$IFDEF FPC}
  TRecordBuffer = PAnsiChar;
{$ELSE}
  TRecordBuffer = PByte;
{$ENDIF}

  { Information about field }

  PFldInfoRec = ^TFldInfoRec;
  TFldInfoRec = packed record
    fType: byte;
    fSize: byte;
  end;

  PDataBlock = ^TDataBlock;
  TDataBlock = packed record
    nextBlock : word;
    blockNumber : word;
    addDataSize : word;
  end;

  { Header of file }

  PPxHeader = ^TPxHeader;
  TPxHeader = packed record
    recordSize              :  word;
    headerSize              :  word;
    fileType                :  byte;
    maxTableSize            :  byte;
    numRecords              :  longint;
    nextBlock               :  word;
    fileBlocks              :  word;
    firstBlock              :  word;
    lastBlock               :  word;
    unknown12x13            :  word;
    modifiedFlags1          :  byte;
    indexFieldNumber 	    :  byte;
    primaryIndexWorkspace   :  pointer;
    unknownPtr1A            :  pointer;
    unknown1Ex20            :  array[$001E..$0020] of byte;
    numFields               :  word;
    primaryKeyFields        :  word;
    encryption1             :  longint;
    sortOrder               :  byte;
    modifiedFlags2          :  byte;
    unknown2Bx2C            :  array[$002B..$002C] of byte;
    changeCount1            :  byte;
    changeCount2            :  byte;
    unknown2F               :  byte;
    tableNamePtrPtr         : ^pchar;
    fldInfoPtr              :  PFldInfoRec;
    writeProtected          :  byte;
    fileVersionID           :  byte;
    maxBlocks               :  word;
    unknown3C               :  byte;
    auxPasswords            :  byte;
    unknown3Ex3F            :  array[$003E..$003F] of byte;
    cryptInfoStartPtr       :  pointer;
    cryptInfoEndPtr         :  pointer;
    unknown48               :  byte;
    autoInc                 :  longint;
    unknown4Dx4E            :  array[$004D..$004E] of byte;
    indexUpdateRequired     :  byte;
    unknown50x54            :  array[$0050..$0054] of byte;
    refIntegrity            :  byte;
    unknown56x57            :  array[$0056..$0057] of byte;
  end;

  PPxDataHeader = ^TPxDataHeader;
  TPxDataHeader = packed record
    { Возможно идентификатор версии файла
      $0105..$0109 version 4.x (обычно = $0109)
      $010A, $010B version 5.x (обычно = $010B)
      $010C        version 7.0 }
    FileVersionID : word;
    { Принимает те же значения, что и FileVersionID }
    FileVersionID2 : word;
    { Равно 0, если файл не зашифрован }
    Encryption2 : longint;
    FileUpdateTime : longint;
    HiFieldID : word;
    HiFieldIDInfo : word;
    SometimesNumFields : word;
    DosGlobalCodePage : word;
    Unknown6Cx6F : array[$006C..$006F] of byte;
    ChangeCount4 : word;
    Unknown72x77 : array[$0072..$0077] of byte;
  end;

  TPxRecordHeader = packed record
    RecordIndex: integer;
    BookmarkFlag: TBookmarkFlag;
  end;
  PPxRecordHeader=^TPxRecordHeader;

  TPxBlob = packed record {10-byte Blob Info Block}
    FileLoc: Integer;
    Length: Integer;
    ModCnt: Word;
  end;

  TPxBlobIdx = packed record {Blob Pointer Array Entry}
    Offset: Byte;
    Len16: Byte;
    ModCnt: Word;
    Len: Byte;
  end;

  TPdxLang = record
    Name: string[20];
    SortOrder: byte;
    CodePage: word;
    SortOrderID: string[8];
  end;

const
  PdxLangTable: array[1..118] of TPdxLang =
    ((Name: 'Access General';        SortOrder: 161; CodePage: 1252; SortOrderID: 'ACCGEN'),
     (Name: 'Access Greece';         SortOrder: 53;  CodePage: 1253; SortOrderID: 'ACCGREEK'),
     (Name: 'Access Japanese';       SortOrder: 49;  CodePage: 932;  SortOrderID: 'ACCJAPAN'),
     (Name: 'Access Nord/Danish';    SortOrder: 58;  CodePage: 1251; SortOrderID: 'ACCNRDAN'),
     (Name: 'Access Swed/Finnish';   SortOrder: 78;  CodePage: 1252; SortOrderID: 'ACCSWFIN'),
     (Name: '''ascii'' ANSI';        SortOrder: 76;  CodePage: 1252; SortOrderID: 'DBWINUS0'),
     (Name: 'Borland ANSI Arabic';   SortOrder: 63;  CodePage: 1256; SortOrderID: 'BLWINAR0'),
     (Name: 'Borland DAN Latin-1';   SortOrder: 20;  CodePage: 1252; SortOrderID: 'BLLT1DA0'),
     (Name: 'Borland DEU Latin-1';   SortOrder: 24;  CodePage: 1252; SortOrderID: 'BLLT1DE0'),
     (Name: 'Borland ENG Latin-1';   SortOrder: 47;  CodePage: 1252; SortOrderID: 'BLLT1UK0'),
     (Name: 'Borland ENU Latin-1';   SortOrder: 55;  CodePage: 1252; SortOrderID: 'BLLT1US0'),
     (Name: 'Borland ESP Latin-1';   SortOrder: 39;  CodePage: 1252; SortOrderID: 'BLLT1ES0'),
     (Name: 'Borland FIN Latin-1';   SortOrder: 30;  CodePage: 1252; SortOrderID: 'BLLT1FI0'),
     (Name: 'Borland FRA Latin-1';   SortOrder: 39;  CodePage: 1252; SortOrderID: 'BLLT1FR0'),
     (Name: 'Borland FRC Latin-1';   SortOrder: 19;  CodePage: 1252; SortOrderID: 'BLLT1CA0'),
     (Name: 'Borland ISL Latin-1';   SortOrder: 43;  CodePage: 1252; SortOrderID: 'BLLT1IS0'),
     (Name: 'Borland ITA Latin-1';   SortOrder: 44;  CodePage: 1252; SortOrderID: 'BLLT1IT0'),
     (Name: 'Borland NLD Latin-1';   SortOrder: 41;  CodePage: 1252; SortOrderID: 'BLLT1NL0'),
     (Name: 'Borland NOR Latin-1';   SortOrder: 44;  CodePage: 1252; SortOrderID: 'BLLT1NO0'),
     (Name: 'Borland PTG Latin-1';   SortOrder: 51;  CodePage: 1252; SortOrderID: 'BLLT1PT0'),
     (Name: 'Borland SVE Latin-1';   SortOrder: 56;  CodePage: 1252; SortOrderID: 'BLLT1SV0'),
     (Name: 'DB2 SQL ANSI DEU';      SortOrder: 5;   CodePage: 1252; SortOrderID: 'db2andeu'),
     (Name: 'dBASE BUL 868';         SortOrder: 181; CodePage: 868;  SortOrderID: 'BGDB868'),
     (Name: 'dBASE CHS cp936';       SortOrder: 233; CodePage: 936;  SortOrderID: 'DB936CN0'),
     (Name: 'dBASE CHT cp950';       SortOrder: 255; CodePage: 950;  SortOrderID: 'DB950TW0'),
     (Name: 'dBASE CSY cp852';       SortOrder: 242; CodePage: 852;  SortOrderID: 'DB852CZ0'),
     (Name: 'dBASE CSY cp867';       SortOrder: 248; CodePage: 867;  SortOrderID: 'DB867CZ0'),
     (Name: 'dBASE DAN cp865';       SortOrder: 222; CodePage: 865;  SortOrderID: 'DB865DA0'),
     (Name: 'dBASE DEU cp437';       SortOrder: 221; CodePage: 437;  SortOrderID: 'DB437DE0'),
     (Name: 'dBASE DEU cp850';       SortOrder: 220; CodePage: 850;  SortOrderID: 'DB850DE0'),
     (Name: 'dBASE ELL GR437';       SortOrder: 109; CodePage: 737;  SortOrderID: 'db437gr0'),
     (Name: 'dBASE ENG cp437';       SortOrder: 244; CodePage: 437;  SortOrderID: 'DB437UK0'),
     (Name: 'dBASE ENG cp850';       SortOrder: 243; CodePage: 850;  SortOrderID: 'DB850UK0'),
     (Name: 'dBASE ENU cp437';       SortOrder: 252; CodePage: 437;  SortOrderID: 'DB437US0'),
     (Name: 'dBASE ENU cp850';       SortOrder: 251; CodePage: 850;  SortOrderID: 'DB850US0'),
     (Name: 'dBASE ESP cp437';       SortOrder: 237; CodePage: 437;  SortOrderID: 'DB437ES1'),
     (Name: 'dBASE ESP cp850';       SortOrder: 235; CodePage: 850;  SortOrderID: 'DB850ES0'),
     (Name: 'dBASE FIN cp437';       SortOrder: 227; CodePage: 437;  SortOrderID: 'DB437FI0'),
     (Name: 'dBASE FRA cp437';       SortOrder: 236; CodePage: 437;  SortOrderID: 'DB437FR0'),
     (Name: 'dBASE FRA cp850';       SortOrder: 235; CodePage: 850;  SortOrderID: 'DB850FR0'),
     (Name: 'dBASE FRC cp850';       SortOrder: 220; CodePage: 850;  SortOrderID: 'DB850CF0'),
     (Name: 'dBASE FRC cp863';       SortOrder: 225; CodePage: 863;  SortOrderID: 'DB863CF1'),
     (Name: 'dBASE HUN cp852';       SortOrder: 148; CodePage: 852;  SortOrderID: 'db852hdc'),
     (Name: 'dBASE ITA cp437';       SortOrder: 241; CodePage: 437;  SortOrderID: 'DB437IT0'),
     (Name: 'dBASE ITA cp850';       SortOrder: 241; CodePage: 850;  SortOrderID: 'DB850IT1'),
     (Name: 'dBASE JPN cp932';       SortOrder: 238; CodePage: 932;  SortOrderID: 'DB932JP0'),
     (Name: 'dBASE JPN Dic932';      SortOrder: 239; CodePage: 932;  SortOrderID: 'DB932JP1'),
     (Name: 'dBASE KOR cp949';       SortOrder: 246; CodePage: 949;  SortOrderID: 'DB949KO0'),
     (Name: 'dBASE NLD cp437';       SortOrder: 238; CodePage: 437;  SortOrderID: 'DB437NL0'),
     (Name: 'dBASE NLD cp850';       SortOrder: 237; CodePage: 850;  SortOrderID: 'DB850NL0'),
     (Name: 'dBASE NOR cp865';       SortOrder: 246; CodePage: 865;  SortOrderID: 'DB865NO0'),
     (Name: 'dBASE PLK cp852';       SortOrder: 116; CodePage: 852;  SortOrderID: 'db852po0'),
     (Name: 'dBASE PTB cp850';       SortOrder: 247; CodePage: 850;  SortOrderID: 'DB850PT0'),
     (Name: 'dBASE PTG cp860';       SortOrder: 248; CodePage: 860;  SortOrderID: 'DB860PT0'),
     (Name: 'dBASE RUS cp866';       SortOrder: 129; CodePage: 866;  SortOrderID: 'db866ru0'),
     (Name: 'dBASE SLO cp852';       SortOrder: 116; CodePage: 852;  SortOrderID: 'db852sl0'),
     (Name: 'dBASE SVE cp437';       SortOrder: 253; CodePage: 437;  SortOrderID: 'DB437SV0'),
     (Name: 'dBASE SVE cp850';       SortOrder: 253; CodePage: 850;  SortOrderID: 'DB850SV1'),
     (Name: 'dBASE THA cp874';       SortOrder: 117; CodePage: 874;  SortOrderID: 'db874th0'),
     (Name: 'dBASE TRK cp857';       SortOrder: 0;   CodePage: 857;  SortOrderID: 'DB857TR0'),
     (Name: 'FoxPro Czech 1250';     SortOrder: 120; CodePage: 1250; SortOrderID: 'FOXCZWIN'),
     (Name: 'FoxPro Czech DOS895';   SortOrder: 48;  CodePage: 895;  SortOrderID: 'FOXCZ895'),
     (Name: 'FoxPro German 1252';    SortOrder: 100; CodePage: 1252; SortOrderID: 'FOXDEWIN'),
     (Name: 'FoxPro German 437';     SortOrder: 20;  CodePage: 437;  SortOrderID: 'FOXDE437'),
     (Name: 'FoxPro Nordic 1252';    SortOrder: 120; CodePage: 1252; SortOrderID: 'FOXNOWIN'),
     (Name: 'FoxPro Nordic 437';     SortOrder: 40;  CodePage: 437;  SortOrderID: 'FOXNO437'),
     (Name: 'FoxPro Nordic 850';     SortOrder: 39;  CodePage: 850;  SortOrderID: 'FOXNO850'),
     (Name: 'Hebrew dBASE';          SortOrder: 35;  CodePage: 862;  SortOrderID: 'dbHebrew'),
     (Name: 'MSSQL ANSI Greek';      SortOrder: 122; CodePage: 1253; SortOrderID: 'MSSGRWIN'),
     (Name: 'Oracle SQL WE850';      SortOrder: 27;  CodePage: 850;  SortOrderID: 'ORAWE850'),
     (Name: 'Paradox ANSI HEBREW';   SortOrder: 76;  CodePage: 1255; SortOrderID: 'ANHEBREW'),
     (Name: 'Paradox ''ascii''';     SortOrder: 0;   CodePage: 437;  SortOrderID: 'ascii'),
     (Name: 'Paradox BUL 868';       SortOrder: 71;  CodePage: 868;  SortOrderID: 'BULGARIA'),
     (Name: 'Paradox China 936';     SortOrder: 3;   CodePage: 936;  SortOrderID: 'china'),
     (Name: 'Paradox Cyrr 866';      SortOrder: 192; CodePage: 866;  SortOrderID: 'cyrr'),
     (Name: 'Paradox Czech 852';     SortOrder: 13;  CodePage: 852;  SortOrderID: 'czech'),
     (Name: 'Paradox Czech 867';     SortOrder: 226; CodePage: 867;  SortOrderID: 'cskamen'),
     (Name: 'Paradox ESP 437';       SortOrder: 22;  CodePage: 437;  SortOrderID: 'SPANISH'),
     (Name: 'Paradox Greek GR437';   SortOrder: 74;  CodePage: 737;  SortOrderID: 'grcp437'),
     (Name: 'Paradox ''hebrew''';    SortOrder: 125; CodePage: 862;  SortOrderID: 'hebrew'),
     (Name: 'Paradox Hun 852 DC';    SortOrder: 177; CodePage: 852;  SortOrderID: 'hun852dc'),
     (Name: 'Paradox ''intl''';      SortOrder: 183; CodePage: 437;  SortOrderID: 'intl'),
     (Name: 'Paradox ''intl'' 850';  SortOrder: 84;  CodePage: 850;  SortOrderID: 'intl850'),
     (Name: 'Paradox ISL 861';       SortOrder: 208; CodePage: 861;  SortOrderID: 'iceland'),
     (Name: 'Paradox ''japan''';     SortOrder: 10;  CodePage: 932;  SortOrderID: 'japan'),
     (Name: 'Paradox Korea 949';     SortOrder: 18;  CodePage: 949;  SortOrderID: 'korea'),
     (Name: 'Paradox ''nordan''';    SortOrder: 130; CodePage: 865;  SortOrderID: 'nordan'),
     (Name: 'Paradox ''nordan40''';  SortOrder: 230; CodePage: 865;  SortOrderID: 'nordan40'),
     (Name: 'Paradox Polish 852';    SortOrder: 143; CodePage: 852;  SortOrderID: 'polish'),
     (Name: 'Paradox Slovene 852';   SortOrder: 252; CodePage: 852;  SortOrderID: 'slovene'),
     (Name: 'Paradox ''swedfin''';   SortOrder: 240; CodePage: 437;  SortOrderID: 'swedfin'),
     (Name: 'Paradox Taiwan 950';    SortOrder: 132; CodePage: 950;  SortOrderID: 'taiwan'),
     (Name: 'Paradox Thai 874';      SortOrder: 166; CodePage: 874;  SortOrderID: 'thai'),
     (Name: 'Paradox ''turk''';      SortOrder: 198; CodePage: 857;  SortOrderID: 'turk'),
     (Name: 'Pdox ANSI Bulgaria';    SortOrder: 230; CodePage: 1251; SortOrderID: 'BGPD1251'),
     (Name: 'Pdox ANSI Cyrillic';    SortOrder: 143; CodePage: 1251; SortOrderID: 'ancyrr'),
     (Name: 'Pdox ANSI Czech';       SortOrder: 220; CodePage: 1250; SortOrderID: 'anczech'),
     (Name: 'Pdox ANSI Greek';       SortOrder: 14;  CodePage: 1253; SortOrderID: 'angreek1'),
     (Name: 'Pdox ANSI Hun. DC';     SortOrder: 225; CodePage: 1250; SortOrderID: 'anhundc'),
     (Name: 'Pdox ANSI Intl';        SortOrder: 98;  CodePage: 1252; SortOrderID: 'ANSIINTL'),
     (Name: 'Pdox ANSI Intl850';     SortOrder: 17;  CodePage: 1252; SortOrderID: 'ANSII850'),
     (Name: 'Pdox ANSI Nordan4';     SortOrder: 78;  CodePage: 1252; SortOrderID: 'ANSINOR4'),
     (Name: 'Pdox ANSI Polish';      SortOrder: 94;  CodePage: 1250; SortOrderID: 'anpolish'),
     (Name: 'Pdox ANSI Slovene';     SortOrder: 111; CodePage: 1250; SortOrderID: 'ansislov'),
     (Name: 'Pdox ANSI Spanish';     SortOrder: 93;  CodePage: 1252; SortOrderID: 'ANSISPAN'),
     (Name: 'Pdox ANSI Swedfin';     SortOrder: 105; CodePage: 1252; SortOrderID: 'ANSISWFN'),
     (Name: 'Pdox ANSI Turkish';     SortOrder: 213; CodePage: 1254; SortOrderID: 'ANTURK'),
     (Name: 'Pdox ''ascii'' Japan';  SortOrder: 0;   CodePage: 437;  SortOrderID: 'ascii'),
     (Name: 'pdx ANSI Czech ''CH'''; SortOrder: 83;  CodePage: 1250; SortOrderID: 'anczechw'),
     (Name: 'pdx ANSI ISO L_2 CZ';   SortOrder: 42;  CodePage: 1250; SortOrderID: 'anil2czw'),
     (Name: 'pdx Czech 852 ''CH''';  SortOrder: 132; CodePage: 852;  SortOrderID: 'czechw'),
     (Name: 'pdx Czech 867 ''CH''';  SortOrder: 89;  CodePage: 867;  SortOrderID: 'cskamenw'),
     (Name: 'pdx ISO L_2 Czech';     SortOrder: 91;  CodePage: 592;  SortOrderID: 'il2czw'),
     (Name: '''Spanish'' ANSI';      SortOrder: 60;  CodePage: 1252; SortOrderID: 'DBWINES0'),
     (Name: 'SQL Link ROMAN8';       SortOrder: 20;  CodePage: 8;    SortOrderID: 'BLROM800'),
     (Name: 'Sybase SQL Dic437';     SortOrder: 209; CodePage: 437;  SortOrderID: 'SYDC437'),
     (Name: 'Sybase SQL Dic850';     SortOrder: 208; CodePage: 850;  SortOrderID: 'SYDC850'),
     (Name: '''WEurope'' ANSI';      SortOrder: 64;  CodePage: 1252; SortOrderID: 'DBWINWE0'));

type

  TEncodeEvent = function(Sender: TObject; Field: TField; s: string): string of object;

  { TPdx }

  TPdx = class(TDataSet)
  protected
  
//    procedure GetBookmarkData(Buffer: PChar; Data: Pointer); override; // virtual; abstract;
    function GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag; override;
//    procedure InternalGotoBookmark(ABookmark: Pointer); override;// virtual; abstract;
    procedure SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag); override;
//    procedure SetBookmarkData(Buffer: PChar; Data: Pointer); override;// virtual; abstract;
  
    procedure InternalHandleException; override;
    procedure InternalInitFieldDefs; override;
    procedure InternalOpen; override;
    function IsCursorOpen: Boolean; override;
    procedure InternalClose; override;

    function GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult; override;
    function AllocRecordBuffer: TRecordBuffer; override;
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
    procedure InternalInitRecord(Buffer: TRecordBuffer); override;

    procedure InternalFirst; override;
    procedure InternalLast; override;
    procedure InternalSetToRecord(Buffer: TRecordBuffer); override;

    function GetCanModify: Boolean; override;

    function GetRecordCount: Integer; override;

    procedure SetRecNo(Value: Integer); override;
    function GetRecNo: Integer; override;
    //Здесь номер записи считается от 1
  private
    fTableName: string;
    fStream: TFileStream;
    fBlobStream: TFileStream;
    fIsOpen: boolean;
    fCursor: integer;
    fPxHeader: TPxHeader;
    fPxDataHeader: TPxDataHeader;
    fPxFields: array of TFldInfoRec;
    fPxFldStart: array of longint;
    { Показывает зашифрован ли файл }
    fEncrypted: boolean;
    fSortOrderID: string;
    fLanguageID: integer;
    fCodepage: string;
    fEncodingMemo: boolean;
    fOnEncode: TEncodeEvent;
    function GetLanguage: string;
    procedure SetLanguage(const AValue: string);
    procedure SetTableName(const AValue: string);
    function NativeToFieldType(NativeType: byte): TFieldType;
    function ReadDataBlock(BlockNum: Word): TDataBlock;
    { Определяет язык открытой таблицы }
    function DetectLang: integer;
    function EncodingString(s: string): string;
    function EncodingField(s: string; Field: TField): string;
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;

    function GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;override;

    function CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream; override;
    property PxHeader: TPxHeader read fPxHeader;
    property PxDataHeader: TPxDataHeader read fPxDataHeader;
    property SortOrderID: string read fSortOrderID;
  published
    property TableName: string read fTableName write SetTableName;
    property Language: string read GetLanguage write SetLanguage;
    property Codepage: string read fCodepage write fCodepage;
    property EncodingMemo: boolean read fEncodingMemo write fEncodingMemo;
    
    property Active;
//    property FieldDefs stored FieldDefsStored;
    property Filter;
    property Filtered;
    property FilterOptions;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeRefresh;
    property AfterRefresh;
    property BeforeScroll;
    property AfterScroll;
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;
    
    property OnEncode: TEncodeEvent read fOnEncode write fOnEncode;
  end;
  
  EParadoxError = class(Exception);

implementation

{ TPdx }
{
procedure TPdx.GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
  //inherited GetBookmarkData(Buffer, Data);
end;}

function TPdx.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
begin
  result := PPxRecordHeader(Buffer)^.BookmarkFlag;
end;
{
procedure TPdx.InternalGotoBookmark(ABookmark: Pointer);
var
  Pos:integer;

begin
  if not assigned(FPerformFindBookmark) then exit;
  
  Pos := FPerformFindBookmark(string(Bookmark));
  if Pos > -1 then FCursor := Pos;
end;}

procedure TPdx.SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag);
begin
  PPxRecordHeader(Buffer)^.BookmarkFlag := Value;
end;
{
procedure TPdx.SetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
  //inherited SetBookmarkData(Buffer, Data);
end;
}
procedure TPdx.InternalHandleException;
begin
  Application.HandleException(Self);
end;

procedure TPdx.InternalInitFieldDefs;
var
  i: integer;
  p, start: longint;
  ch: byte;
  s: string;

begin
  if (fPxHeader.fileVersionID >= $05) then
    p := $78
  else
    p := $58;

  fStream.Seek(p, soFromBeginning);

  SetLength(fPxFields, fPxHeader.numFields);
  SetLength(fPxFldStart, fPxHeader.numFields);

  start := 0;
  FieldDefs.Clear;
  for i := 0 to fPxHeader.numFields - 1 do
  begin
    fPxFldStart[i] := start;
    fStream.Read(fPxFields[i], SizeOf(TFldInfoRec));
    start := start + fPxFields[i].fSize;
  end;

  p := p + fPxHeader.numFields*SizeOf(TFldInfoRec) + 4 + fPxHeader.numFields*4;
  // TableName size
  if (fPxHeader.fileVersionID >= $0C) then
    p := p + 261
  else
    p := p + 79;

  fStream.Seek(p, soFromBeginning);
  for i := 0 to fPxHeader.numFields - 1 do
  begin
    s := '';
    repeat
      {$IFDEF FPC}
        ch := fStream.ReadByte;
      {$ELSE}
        fStream.Read(ch, 1); //add by User32!!!
      {$ENDIF}
      if (ch <> 0) then s := s + chr(ch);
    until ch = 0;

    case fPxFields[i].fType of
      pxfAlpha, pxfMemoBLOb, pxfBLOb, pxfFmtMemoBLOb, pxfOLE, pxfGraphic :
        FieldDefs.Add(s, NativeToFieldType(fPxFields[i].fType), fPxFields[i].fSize, false);
    else
      FieldDefs.Add(s, NativeToFieldType(fPXFields[i].fType));
    end;
  end;

  if not fEncrypted then
  begin
    p := fPxHeader.numFields*2;
  end
  else
  begin
    // Здесь нужно рассчитать смещение для зашифрованного файла
  end;

  fStream.Seek(p, soFromCurrent);
  s := '';
  repeat
    {$IFDEF FPC}
      ch := fStream.ReadByte;
    {$ELSE}
      fStream.Read(ch, 1); //add by User32!!!
    {$ENDIF}
    if (ch <> 0) then s := s + chr(ch);
  until ch = 0;
  fSortOrderID := s;

  fLanguageID := DetectLang;
end;

procedure TPdx.InternalOpen;
begin
  if TableName = '' then raise EParadoxError.CreateFmt('TableName is not set', []);

  try
    fStream := TFileStream.Create(TableName, fmOpenRead );
  except
    on E:Exception do raise EParadoxError.CreateFmt('Unable to open database "%s" - %s', [fTableName, E.Message]);
  end;
  
  fStream.Read(fPxHeader, SizeOf(fPxHeader));

  if (fPxHeader.fileType <> 0) and (fPxHeader.fileType <> 2) then raise EParadoxError.CreateFmt('"%s" - is not .DB data file', [fTableName]);

  if (fPxHeader.fileVersionID >= $05) then
  begin
    fStream.Read(fPxDataHeader, SizeOf(fPxDataHeader));
    if fPxDataHeader.Encryption2 <> 0 then fEncrypted := true
                                      else fEncrypted := false;
  end
  else
  begin
    if fPxHeader.Encryption1 <> 0 then fEncrypted := true
                                  else fEncrypted := false;
  end;

  try
    if FileExists(ChangeFileExt(TableName,'.mb')) then
      fBlobStream := TFileStream.Create(ChangeFileExt(TableName,'.mb'), fmOpenRead );
  except
    fBlobStream := nil;
  end;

  InternalInitFieldDefs;
  if DefaultFields then CreateFields;
  BindFields(true); //Привязываем поля к БД
  fIsOpen := true;
  fCursor := 0;
end;

function TPdx.IsCursorOpen: Boolean;
begin
  Result := fIsOpen;
end;

procedure TPdx.InternalClose;
begin
  BindFields(False); //Отвязываем поля
  if DefaultFields then DestroyFields;
  fIsOpen := false;
  fBlobStream.Free;
  fStream.Free;
  
  fLanguageID := 0;
end;

function TPdx.GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean): TGetResult;
var
  i: word;
  n, nb: integer;
  DataBlock: TDataBlock;
  p: TRecordBuffer;
  Position : Integer;
begin
  result := grOK;
  case GetMode of
    gmPrior: if FCursor <= 1 then result := grBOF else Dec(FCursor);
    gmNext: if FCursor >= RecordCount then result := grEOF else Inc(FCursor);
    gmCurrent: if (FCursor < 1) or (FCursor > RecordCount) then Result := grError;
  end;
  if result = grOK then
  begin
    PPxRecordHeader(Buffer)^.RecordIndex := FCursor;
    PPxRecordHeader(Buffer)^.BookmarkFlag := bfCurrent; //  GJK
    // Находим позицию записи в файле
    i := fPxHeader.firstBlock;
    n := 0;
    nb := 0;
    while (n < FCursor) do
    begin
      DataBlock := ReadDataBlock(i);
      nb := n;
      n := n + (DataBlock.addDataSize div fPxHeader.recordSize) + 1;
      i := DataBlock.nextBlock;
    end;
    Position := DataBlock.blockNumber*fPxHeader.maxTableSize*1024 + fPxHeader.headerSize + (FCursor - nb - 1)*fPxHeader.recordSize + SizeOf(TDataBlock);
    fStream.Seek(Position, soFromBeginning);
    p := Buffer + SizeOf(TPxRecordHeader);
    fStream.Read(p^, fPxHeader.recordSize);
  end
  else
  begin
    // This prevents garbage in datagrid when the last record was deleted
    p := Buffer + SizeOf(TPxRecordHeader);          // GJK
    FillChar(p^, fPxHeader.recordSize, 0);          // GJK
    PPxRecordHeader(Buffer)^.BookmarkFlag := bfEOF; //  GJK
  end;
  if (result = grError) and DoCheck then DatabaseError('Error in GetRecord()');
end;

function TPdx.AllocRecordBuffer: TRecordBuffer;
begin
  Result := nil;
  GetMem(Result, SizeOf(TPxRecordHeader) + fPxHeader.recordSize);
end;

procedure TPdx.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
  FreeMem(Pointer(Buffer), SizeOf(TPxRecordHeader) + fPxHeader.recordSize);
end;

procedure TPdx.InternalInitRecord(Buffer: TRecordBuffer);
begin

end;

procedure TPdx.InternalFirst;
begin
  fCursor := 0;
end;

procedure TPdx.InternalLast;
begin
  fCursor :=  RecordCount + 1;
end;

procedure TPdx.InternalSetToRecord(Buffer: TRecordBuffer);
begin
  FCursor := PPxRecordHeader(Buffer)^.RecordIndex;
end;

function TPdx.GetCanModify: Boolean;
begin
  Result := false;
end;

function TPdx.GetRecordCount: Integer;
begin
  Result := fPxHeader.numRecords;
end;

procedure TPdx.SetRecNo(Value: Integer);
begin
  if (Value < 1) or (Value >= RecordCount + 1) then exit;
  FCursor := Value;
  Resync([]);
end;

function TPdx.GetRecNo: Integer;
begin
  Result:=PPxRecordHeader(ActiveBuffer)^.RecordIndex;
end;

procedure TPdx.SetTableName(const AValue: string);
begin
  if fTableName <> AValue then
  begin
    if Active then Close;
    fTableName := AValue;
  end;
end;

function TPdx.GetLanguage: string;
begin
  if (fLanguageID > 0) and (fLanguageID <= 118) then
    Result := PdxLangTable[fLanguageID].Name
  else
    Result := '';
end;

procedure TPdx.SetLanguage(const AValue: string);
var
  i: integer;

begin
  if Active then
  begin
    for i := 1 to 118 do
    begin
      if PdxLangTable[i].Name = AValue then
      begin
        fLanguageID := i;
        break;
      end;
    end;
  end
  else
  begin
    fLanguageID := 0;
  end;
end;

function TPdx.NativeToFieldType(NativeType: byte): TFieldType;
begin
  Result := ftUnknown;
  case NativeType of
    pxfAlpha : Result := ftString;
    pxfDate : Result := ftDate;
    pxfShort : Result := ftSmallInt;
    pxfLong : Result := ftInteger;
    pxfCurrency : Result := ftCurrency;
    pxfNumber : Result := ftFloat;
    pxfLogical : Result := ftBoolean;
    pxfMemoBLOb : Result := ftMemo;
    pxfBLOb : Result := ftBlob;
    pxfFmtMemoBLOb : Result := ftFmtMemo;
    pxfOLE : Result := ftParadoxOle;
    pxfGraphic : Result := ftGraphic;
    pxfTime : Result := ftTime;
    pxfTimestamp : Result := ftDateTime;
    pxfAutoInc : Result := ftAutoInc;
    pxfBCD : Result := ftBCD;
    pxfBytes : Result := ftBytes;
  end;
end;

function TPdx.ReadDataBlock(BlockNum: Word): TDataBlock;
begin
  if (BlockNum < 1) or (BlockNum > fPxHeader.fileBlocks) then
    raise EParadoxError.CreateFmt('Block %d read error', [BlockNum]);
  fStream.Seek((BlockNum - 1)*fPxHeader.maxTableSize*1024 + fPxHeader.headerSize, soFromBeginning);
  fStream.ReadBuffer(Result, SizeOf(TDataBlock));
end;

function TPdx.DetectLang: integer;
var
  i: integer;

begin
  Result := 0;
  for i := 1 to 118 do
  begin
    if (fPxHeader.fileVersionID >= $05) then
    begin
      if (PdxLangTable[i].SortOrder = fPxHeader.sortOrder) and (PdxLangTable[i].CodePage = fPxDataHeader.DosGlobalCodePage) and (PdxLangTable[i].SortOrderID = fSortOrderID) then
      begin
        Result := i;
        break;
      end;
    end
    else
    begin
      if (PdxLangTable[i].SortOrder = fPxHeader.sortOrder) then
      begin
        Result := i;
        break;
      end;
    end;
  end;
end;

function TPdx.EncodingField(s: string; Field: TField): string;
begin
  Result := s;

  if Assigned(fOnEncode) then
  begin
    Result := fOnEncode(Self, Field, s);
  end
  else
  begin
    if fLanguageID < 1 then exit;
    Result := EncodingString(s);
  end;  
end;

constructor TPdx.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCodepage := GetCodepage;
  fEncodingMemo := true;
end;

destructor TPdx.Destroy;
begin
  inherited Destroy;
end;

function TPdx.GetFieldData(Field: TField; var Buffer: TValueBuffer): Boolean;
var
  p: array of AnsiChar;
  i: integer;
  src: TRecordBuffer;
  IsNull: boolean;
  s: string;
  c : Cardinal;

begin
  if Buffer = nil then
  begin
    Result := false;
    exit;
  end;

  result := true;

  SetLength(p, fPxFields[Field.FieldNo - 1].fSize);

  src := Pointer(ActiveBuffer + SizeOf(TPxRecordHeader) + fPxFldStart[Field.FieldNo - 1]);

  IsNull := true;
  if fPxFields[Field.FieldNo - 1].fType in [2..6, $14..$16] then
  begin
    for i := 0 to fPxFields[Field.FieldNo - 1].fSize - 1 do
    begin
      p[i] := PAnsiChar(src + fPxFields[Field.FieldNo - 1].fSize - i - 1)^;
      if Ord(p[i]) <> 0 then IsNull := false;
    end;

//  GJK:Using a loop var outside the loop can cause (in Delphi) strange behavior
//    p[i] := Chr(Ord(p[i]) xor $80);
    p[fPxFields[Field.FieldNo - 1].fSize - 1] := AnsiChar(Ord(p[fPxFields[Field.FieldNo - 1].fSize - 1]) xor $80);

    if IsNull then begin result := false; exit; end;
  end;

  case fPxFields[Field.FieldNo - 1].fType of
    pxfAlpha :
      begin
        c := fPxFields[Field.FieldNo - 1].fSize;
        StrLCopy( PAnsiChar( Buffer ),PAnsiChar(src), c);
      end;
    pxfDate : PLongint(Buffer)^ := PLongint(p)^;
    pxfShort : PSmallInt(Buffer)^ := PSmallInt(p)^;
    pxfLong : PInteger(Buffer)^ := PInteger(p)^;
    pxfCurrency : PDouble(Buffer)^ := PDouble(p)^;
    pxfNumber: PDouble(Buffer)^ := PDouble(p)^;
    pxfLogical : PWordbool(Buffer)^ := (Ord(src^) = $80);
//    pxfMemoBLOb     = $0C;
//    pxfBLOb         = $0D;
//    pxfFmtMemoBLOb  = $0E;
//    pxfOLE          = $0F;
//    pxfGraphic      = $10;
    pxfTime : PDouble(Buffer)^ :=  PDouble(p)^;
    pxfTimestamp : PDouble(Buffer)^ :=  PDouble(p)^;
    pxfAutoInc : PInteger(Buffer)^ := PInteger(p)^;
//    pxfBCD          = $17;
//    pxfBytes        = $18;
  else
    result := false;
  end;
end;

function TPdx.CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
var
  bStream: TMemoryStream;
  src, header: TRecordBuffer;
  bl: TPxBlob;
  bi: TPxBlobIdx;
  s: string;
  idx: byte;
  loc: Integer;
  Buffer : PAnsiChar;

begin
  bStream := TMemoryStream.Create;
  Result := bStream;

  if (Mode = bmRead) then
  begin
    src := Pointer(ActiveBuffer + SizeOf(TPxRecordHeader) + fPxFldStart[Field.FieldNo - 1]);
    header := src + Field.Size - SizeOf(TPxBlob);
    move(header^, bl, SizeOf(bl));

    if bl.Length = 0 then exit;

    if bl.Length > Field.Size - SizeOf(TPxBlob) then
    begin
      if fBlobStream <> nil then
      begin
        idx := bl.FileLoc and $FF;
        loc := bl.FileLoc and $FFFFFF00;

        if idx = $FF then
        begin {Read from a Single Blob Block}
          fBlobStream.Seek(loc + 9, soFromBeginning);
          if Field.DataType = ftMemo then
          begin
            SetLength(s, bl.Length);
            fBlobStream.Read(s[1], bl.Length);

            if EncodingMemo then s := EncodingField(s, Field);

            bStream.Write(s[1], Length(s));
          end
          else
          begin
            bStream.CopyFrom(fBlobStream, bl.Length);
          end;
        end
        else
        begin
          fBlobStream.Seek(loc + 12 + 5*idx, soFromBeginning);
          fBlobStream.Read(bi, SizeOf(TPxBlobIdx));
          fBlobStream.Seek(loc + 16*bi.Offset, soFromBeginning);

          if Field.DataType = ftMemo then
          begin
            SetLength(s, bl.Length);
            fBlobStream.Read(s[1], bl.Length);

            if EncodingMemo then s := EncodingField(s, Field);

            bStream.Write(s[1], Length(s));
          end
          else
          begin
            bStream.CopyFrom(fBlobStream, bl.Length);
          end;
        end;
      end;
    end
    else
    begin
      if Field.DataType = ftMemo then
      begin

        StrLCopy( Buffer,PAnsiChar(src),  bl.Length);
        s := Buffer;
        bStream.Write(s[1], Length(s));
      end
      else
      begin
        bStream.Write(src, bl.Length);
      end;
    end;
    
    bStream.Position := 0;
  end;
end;

function TPdx.EncodingString(s: string): string;
begin
  Result := s;
  case PdxLangTable[fLanguageID].CodePage of
    1251:
      begin
        if Codepage = 'UTF-8' then Result := Encoding(CP1251, UTF8, s);
        if Codepage = 'KOI8R' then Result := Encoding(CP1251, KOI8R, s);
      end;
    866:
      begin
        if Codepage = 'UTF-8' then Result := Encoding(CP866, UTF8, s);
        if Codepage = 'KOI8R' then Result := Encoding(CP866, KOI8R, s);
        if Codepage = 'CP1251' then Result := Encoding(CP866, CP1251, s);
      end;
  end;
end;

end.

