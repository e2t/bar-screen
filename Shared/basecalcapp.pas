unit BaseCalcApp;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  L10n,
  SysUtils;

type
  {$interfaces CORBA}
  IBaseView = interface
    procedure PrintText(const AText: String);
    procedure SetTitle(const AText: String);
    procedure SetRunLabel(const AText: String);
    procedure SetUiMenuLabel(const AText: String);
    procedure SetOutMenuLabel(const AText: String);
    procedure AddUiSubMenu(AItems: TStrings);
    procedure SelectUiSubMenu(AIndex: Integer);
    function GetUiSubMenuSelected: Integer;
    procedure AddOutSubMenu(AItems: TStrings);
    procedure SelectOutSubMenu(AIndex: Integer);
    function GetOutSubMenuSelected: Integer;
  end;

  IBaseViewPresenter = interface
    procedure Free;
    procedure InitView;
    procedure TranslateUi;
    procedure TranslateOut;
    procedure Run;
  end;

  IBaseModelPresenter = interface
    procedure LogError(SpecMap: TTranslate; const Args: array of const);
    procedure AddOutput(SpecMap: TTranslate; const Args: array of const);
    procedure AddOutput(const AText: String);
  end;

  ICorePresenter = interface
    procedure DoInitView;
    procedure DoTranslateUi;
    procedure GetInputData;
    procedure Calculate;
    procedure PrintResults;
    procedure PrintErrors;
    procedure ClearQueues;
  end;

  {$interfaces COM}
  ICore = interface
    procedure PrintPlainResults;
    procedure PrintErrorsOnly;
    function UiLang: TLanguage;
    function OutLang: TLanguage;
    procedure ClearQueues;

    { delegate in IBaseViewPresenter }
    procedure InitView;
    procedure TranslateUi;
    procedure TranslateOut;
    procedure Run;

    { delegate in IBaseModelPresenter }
    procedure LogError(SpecMap: TTranslate; const Args: array of const);
    procedure AddOutput(SpecMap: TTranslate; const Args: array of const);
    procedure AddOutput(const AText: String);
  end;

  TSubMenuSelector = procedure(AIndex: Integer) of object;
  TLangArray = array of TLanguage;

procedure SelectLangMenuItem(ALang: TLanguage; const ALangs: TLangArray;
  AViewCall: TSubMenuSelector);

function NewCore(APresenter: ICorePresenter; AView: IBaseView;
  const AUiLangs, AOutLangs: TLangArray; AppName: TGetAppNameEvent;
  AppVendor: TGetVendorNameEvent; const AppVersion: String;
  ATitle: TTranslate): ICore;

implementation

uses
  Errors,
  UMsgQueue,
  USettings;

type
  TCore = class sealed(TInterfacedObject, ICore)
  private
    FPresenter: ICorePresenter;
    FView: IBaseView;
    FUiLangs, FOutLangs: array of TLanguage;
    FUiLang, FOutLang: TLanguage;
    FErrors, FResults: IMsgQueue;
    FSettings: ISettingManager;
    FTitle: TTranslate;
    FAppVersion, FAppName: String;

    procedure SetUiLang(ALang: TLanguage);
    procedure SetOutLang(ALang: TLanguage);
    procedure TranslateUiOnly;
    { ICore }
    procedure PrintPlainResults;
    procedure PrintErrorsOnly;
    function UiLang: TLanguage;
    function OutLang: TLanguage;
    procedure ClearQueues;
    { ICore: delegate in IBaseViewPresenter }
    procedure InitView;
    procedure TranslateUi;
    procedure TranslateOut;
    procedure Run;
    { ICore: delegate in IBaseModelPresenter }
    procedure LogError(SpecMap: TTranslate; const Args: array of const);
    procedure AddOutput(SpecMap: TTranslate; const Args: array of const);
    procedure AddOutput(const AText: String);
  public
    constructor Create(APresenter: ICorePresenter; AView: IBaseView;
      const AUiLangs, AOutLangs: TLangArray; AppName: TGetAppNameEvent;
      AppVendor: TGetVendorNameEvent; const AppVersion: String;
      ATitle: TTranslate);
  end;

procedure SelectLangMenuItem(ALang: TLanguage; const ALangs: TLangArray;
  AViewCall: TSubMenuSelector);
var
  I: Integer;
begin
  for I := Low(ALangs) to High(ALangs) do
    if ALangs[I] = ALang then
    begin
      AViewCall(I);
      break;
    end;
end;

function NewCore(APresenter: ICorePresenter; AView: IBaseView;
  const AUiLangs, AOutLangs: TLangArray; AppName: TGetAppNameEvent;
  AppVendor: TGetVendorNameEvent; const AppVersion: String;
  ATitle: TTranslate): ICore;
begin
  Result := TCore.Create(APresenter, AView, AUiLangs, AOutLangs, AppName,
    AppVendor, AppVersion, ATitle);
end;

{ TCore }

constructor TCore.Create(APresenter: ICorePresenter; AView: IBaseView;
  const AUiLangs, AOutLangs: TLangArray; AppName: TGetAppNameEvent;
  AppVendor: TGetVendorNameEvent; const AppVersion: String; ATitle: TTranslate);
begin
  FPresenter := APresenter;
  FView := AView;
  FUiLangs := AUiLangs;
  FOutLangs := AOutLangs;
  FErrors := NewMsgQueue(AUiLangs);
  FResults := NewMsgQueue(AOutLangs);
  FSettings := NewSettingManager(AppName, AppVendor);
  FTitle := ATitle;
  FAppVersion := AppVersion;
  FAppName := AppName();

  SetUiLang(StrToLanguage(FSettings.GetUiLangCode, AUiLangs[0]));
  SetOutLang(StrToLanguage(FSettings.GetOutLangCode, AOutLangs[0]));
end;

procedure TCore.InitView;
var
  Sl: TStringList;
  L: TLanguage;
begin
  FPresenter.DoInitView;

  Sl := TStringList.Create;
  for L in FUiLangs do
    Sl.Add(LangNames.KeyData[L]);
  FView.AddUiSubMenu(Sl);

  Sl.Clear;
  for L in FOutLangs do
    Sl.Add(LangNames.KeyData[L]);
  FView.AddOutSubMenu(Sl);

  SelectLangMenuItem(FUiLang, FUiLangs, @FView.SelectUiSubMenu);
  SelectLangMenuItem(FOutLang, FOutLangs, @FView.SelectOutSubMenu);
  TranslateUiOnly;

  FreeAndNil(Sl);
end;

procedure TCore.SetUiLang(ALang: TLanguage);
begin
  FUiLang := ALang;
  FSettings.SetUiLangCode(ALang);
end;

procedure TCore.SetOutLang(ALang: TLanguage);
begin
  FOutLang := ALang;
  FSettings.SetOutLangCode(ALang);
end;

procedure TCore.TranslateUiOnly;
begin
  FView.SetTitle(Format('%s - %s %s',
    [FTitle.KeyData[FUiLang], FAppName, FAppVersion]));
  FView.SetRunLabel(TextUiRun.KeyData[FUiLang]);
  FView.SetUiMenuLabel(TextUiMenu.KeyData[FUiLang]);
  FView.SetOutMenuLabel(TextOutMenu.KeyData[FUiLang]);
  FPresenter.DoTranslateUi;
end;

procedure TCore.TranslateUi;
begin
  SetUiLang(FUiLangs[FView.GetUiSubMenuSelected]);
  TranslateUiOnly;
  if not FErrors.IsEmpty then
    FPresenter.PrintErrors;
end;

procedure TCore.TranslateOut;
begin
  SetOutLang(FOutLangs[FView.GetOutSubMenuSelected]);
  if FErrors.IsEmpty then
    FPresenter.PrintResults;
end;

procedure TCore.ClearQueues;
begin
  FErrors.Clear;
  FResults.Clear;
end;

procedure TCore.Run;
begin
  FPresenter.ClearQueues;
  FPresenter.GetInputData;
  if FErrors.IsEmpty then
  begin
    try
      FPresenter.Calculate;
    except
      on ELoggedError do
      begin
        FPresenter.PrintErrors;
        exit;
      end;
    end;
    FPresenter.PrintResults;
  end
  else
    FPresenter.PrintErrors;
end;

procedure TCore.PrintErrorsOnly;
begin
  FView.PrintText(FErrors.Text(FUiLang));
end;

procedure TCore.PrintPlainResults;
begin
  FView.PrintText(FResults.Text(FOutLang));
end;

procedure TCore.LogError(SpecMap: TTranslate; const Args: array of const);
begin
  FErrors.Append(SpecMap, Args);
end;

procedure TCore.AddOutput(SpecMap: TTranslate; const Args: array of const);
begin
  FResults.Append(SpecMap, Args);
end;

procedure TCore.AddOutput(const AText: String);
begin
  FResults.Append(AText);
end;

function TCore.UiLang: TLanguage;
begin
  Result := FUiLang;
end;

function TCore.OutLang: TLanguage;
begin
  Result := FOutLang;
end;

end.
