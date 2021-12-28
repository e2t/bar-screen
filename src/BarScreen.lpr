program BarScreen;

{$MODE OBJFPC}
{$LONGSTRINGS ON}
{$ASSERTIONS ON}
{$RANGECHECKS ON}
{$BOOLEVAL OFF}

uses
 {$IFDEF UNIX}
  cthreads,
 {$ENDIF}
 {$IFDEF HASAMIGA}
  athreads,
 {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  GuiMainForm,
  Controller,
  ScreenCalculation,
  Nullable,
  CheckNum,
  MathUtils,
  Measurements,
  GuiHelper,
  ProgramInfo,
  MassCalculation,
  MassLargeCalculation,
  MassSmallCalculation;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  {$IFDEF WINDOWS} {$WARNINGS OFF}
  Application.MainFormOnTaskBar := True;
  {$WARNINGS ON} {$ENDIF}
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
