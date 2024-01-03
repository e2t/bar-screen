unit UMsgQueue;

{$mode ObjFPC}{$H+}

interface

uses
  L10n,
  SysUtils,
  Types;

type
  TLangArray = array of TLanguage;

  IAddOnlyQueue = interface
    procedure Append(SpecMap: TTranslate; const Args: array of const);
    procedure Append(const AText: String);
  end;

  IMsgQueue = interface(IAddOnlyQueue)
    procedure Clear;
    function Text(ALang: TLanguage): String;
    function IsEmpty: Boolean;
    function StringArray(ALang: TLanguage): TStringDynArray;
  end;

function NewMsgQueue(const ALangs: TLangArray): IMsgQueue;

implementation

uses
  Classes,
  Fgl;

type
  TMsgQueue = class sealed(TInterfacedObject, IMsgQueue)
  private
    FLangs: array of TLanguage;
    FQueue: specialize TFPGMap<TLanguage, TStringList>;

    { IMsgQueue }
    procedure Append(SpecMap: TTranslate; const Args: array of const);
    procedure Append(const AText: String);
    procedure Clear;
    function Text(ALang: TLanguage): String;
    function IsEmpty: Boolean;
    function StringArray(ALang: TLanguage): TStringDynArray;
  public
    constructor Create(const ALangs: TLangArray);
    destructor Destroy; override;
  end;

function NewMsgQueue(const ALangs: TLangArray): IMsgQueue;
begin
  Result := TMsgQueue.Create(ALangs);
end;

{ TMsgQueue }

constructor TMsgQueue.Create(const ALangs: TLangArray);
var
  L: TLanguage;
begin
  FLangs := ALangs;
  FQueue := specialize TFPGMap<TLanguage, TStringList>.Create;
  for L in FLangs do
    FQueue.Add(L, TStringList.Create);
end;

destructor TMsgQueue.Destroy;
var
  I: Integer;
begin
  for I := 0 to FQueue.Count - 1 do
    FQueue.Data[I].Free;
  FreeAndNil(FQueue);
  inherited Destroy;
end;

procedure TMsgQueue.Append(SpecMap: TTranslate; const Args: array of const);
var
  L: TLanguage;
begin
  for L in FLangs do
    FQueue.KeyData[L].Add(SpecMap.KeyData[L], Args);
end;

procedure TMsgQueue.Append(const AText: String);
var
  L: TLanguage;
begin
  for L in FLangs do
    FQueue.KeyData[L].Add(AText);
end;

procedure TMsgQueue.Clear;
var
  L: TLanguage;
begin
  for L in FLangs do
    FQueue.KeyData[L].Clear;
end;

function TMsgQueue.Text(ALang: TLanguage): String;
begin
  Result := FQueue.KeyData[ALang].Text;
end;

function TMsgQueue.IsEmpty: Boolean;
begin
  Result := FQueue.Data[0].Count = 0;
end;

function TMsgQueue.StringArray(ALang: TLanguage): TStringDynArray;
begin
  Result := FQueue.KeyData[ALang].ToStringArray;
end;

end.
