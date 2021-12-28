unit GuiMainForm;

{$MODE OBJFPC}
{$LONGSTRINGS ON}
{$ASSERTIONS ON}
{$RANGECHECKS ON}
{$BOOLEVAL OFF}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls;

type

  { TMainForm }

  TMainForm = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    ButtonRun: TButton;
    ComboBoxGap: TComboBox;
    ComboBoxScreenWs: TComboBox;
    ComboBoxScreenHs: TComboBox;
    ComboBoxGrateHs: TComboBox;
    EditChannelWidth: TEdit;
    EditChannelHeight: TEdit;
    EditMinDischargeHeight: TEdit;
    EditWaterFlow: TEdit;
    EditFinalLevel: TEdit;
    EditTiltAngle: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    ListViewFp: TListView;
    ListViewHydraulic: TListView;
    MemoOutput: TMemo;
    procedure ButtonRunClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

uses
  Controller, LCLType;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = Chr(VK_RETURN) then
    Run();
end;

procedure TMainForm.ButtonRunClick(Sender: TObject);
begin
  Run();
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainFormInit();
end;

end.
