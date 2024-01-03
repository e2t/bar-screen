unit USettings;

{$mode ObjFPC}{$H+}

interface

uses
  L10n,
  SysUtils;

type
  ISettingManager = interface
    function GetUiLangCode: String;
    function GetOutLangCode: String;
    procedure SetUiLangCode(ALang: TLanguage);
    procedure SetOutLangCode(ALang: TLanguage);
  end;

function NewSettingManager(AppName: TGetAppNameEvent;
  AppVendor: TGetVendorNameEvent): ISettingManager;

implementation

uses
  IniFiles,
  LazUTF8;

type
  TSettingManager = class(TInterfacedObject, ISettingManager)
  private
    FDir: String;
    FIni: TIniFile;

    { ISettingManager }
    function GetUiLangCode: String;
    function GetOutLangCode: String;
    procedure SetUiLangCode(ALang: TLanguage);
    procedure SetOutLangCode(ALang: TLanguage);
  public
    constructor Create(AppName: TGetAppNameEvent;
      AppVendor: TGetVendorNameEvent);
    destructor Destroy; override;
  end;

const
  InterfaceSection = 'Interface';
  UiLangKey = 'UiLang';
  OutLangKey = 'OutLang';

function NewSettingManager(AppName: TGetAppNameEvent;
  AppVendor: TGetVendorNameEvent): ISettingManager;
begin
  Result := TSettingManager.Create(AppName, AppVendor);
end;

{ TSettingManager }

constructor TSettingManager.Create(AppName: TGetAppNameEvent;
  AppVendor: TGetVendorNameEvent);
begin
  OnGetVendorName := AppVendor;
  OnGetApplicationName := AppName;
  {$IFDEF WINDOWS}
  FDir := ConcatPaths([GetEnvironmentVariableUTF8('appdata'), VendorName,
    ApplicationName]);
  {$ELSE}
  FDir := GetAppConfigDir(False);
  {$ENDIF}
  if not DirectoryExists(FDir) then
    CreateDir(FDir);
  FIni := TIniFile.Create(ConcatPaths([FDir, 'settings.ini']));
end;

destructor TSettingManager.Destroy;
begin
  FreeAndNil(FIni);
  inherited Destroy;
end;

function TSettingManager.GetUiLangCode: String;
begin
  Result := FIni.ReadString(InterfaceSection, UiLangKey, '');
end;

function TSettingManager.GetOutLangCode: String;
begin
  Result := FIni.ReadString(InterfaceSection, OutLangKey, '');
end;

procedure TSettingManager.SetUiLangCode(ALang: TLanguage);
begin
  FIni.WriteString(InterfaceSection, UiLangKey, LangCodes.KeyData[ALang]);
end;

procedure TSettingManager.SetOutLangCode(ALang: TLanguage);
begin
  FIni.WriteString(InterfaceSection, OutLangKey, LangCodes.KeyData[ALang]);
end;

end.
