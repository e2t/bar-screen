program BarScreen;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  UMainForm,
  UPresenter,
  BaseCalcApp,
  GuiUtils,
  Model,
  Texts,
  SysUtils;

  {$R *.res}

  {$IFDEF DEBUG}
const
  HeapFile = 'heap.trc';
  {$ENDIF}
begin
  {$IFDEF DEBUG}
  if FileExists(HeapFile) then
    DeleteFile(HeapFile);
  SetHeapTraceOutput(HeapFile);
  {$ENDIF}

  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
