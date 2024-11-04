{*******************************************************}
{                                                       }
{            RadStudio Debugger Visualizer Sample       }
{ Copyright(c) 2009-2014 Embarcadero Technologies, Inc. }
{                                                       }
{*******************************************************}

unit DataSetVisualizer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolsAPI, Vcl.Grids, Vcl.ExtCtrls, Vcl.StdCtrls;

type
  TAvailableState = (asAvailable, asProcRunning, asOutOfScope, asNotAvailable);

  TDataSetViewerFrame = class(TFrame, IOTADebuggerVisualizerExternalViewerUpdater,
    IOTAThreadNotifier, IOTAThreadNotifier160)
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    Panel2: TPanel;
    Panel3: TPanel;
    SG: TStringGrid;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    procedure DataSetViewData(Sender: TObject; Item: TListItem);
    procedure Panel1Resize(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    FOwningForm: TCustomForm;
    FClosedProc: TOTAVisualizerClosedProcedure;
    FExpression: string;
    FNotifierIndex: Integer;
    FCompleted: Boolean;
    FDeferredResult: string;
    FDeferredError: Boolean;
    FAvailableState: TAvailableState;
    function Evaluate(Expression: string): string;
  protected
    procedure SetParent(AParent: TWinControl); override;
  public
    procedure CloseVisualizer;
    procedure MarkUnavailable(Reason: TOTAVisualizerUnavailableReason);
    procedure RefreshVisualizer(const Expression, TypeName, EvalResult: string);
    procedure SetClosedCallback(ClosedProc: TOTAVisualizerClosedProcedure);
    procedure SetForm(AForm: TCustomForm);
    procedure AddDataSetItems(const Expression, TypeName, EvalResult: string);

    { IOTAThreadNotifier }
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    procedure ThreadNotify(Reason: TOTANotifyReason);
    procedure EvaluateComplete(const ExprStr, ResultStr: string; CanModify: Boolean;
      ResultAddress, ResultSize: LongWord; ReturnCode: Integer); overload;
    procedure ModifyComplete(const ExprStr, ResultStr: string; ReturnCode: Integer);
    { IOTAThreadNotifier160 }
    procedure EvaluateComplete(const ExprStr, ResultStr: string; CanModify: Boolean;
      ResultAddress: TOTAAddress; ResultSize: LongWord; ReturnCode: Integer); overload;
  end;

procedure Register;

implementation

uses
  DesignIntf, Actnlist, ImgList, Menus, IniFiles, System.Math;

{$R *.dfm}

resourcestring
  sDataSetVisualizerName = 'TDataSet Visualizer for Delphi';
  sDataSetVisualizerDescription = 'Displays a list of the actual fields held in a TDataSet instance';
  sMenuText = 'Show Fields';
  sFormCaption = 'TDataSet Visualizer for %s';
  sProcessNotAccessible = 'process not accessible';
  sValueNotAccessible = 'value not accessible';
  sOutOfScope = 'out of scope';

type
  IFrameFormHelper = interface
    ['{6CBAF0B8-5C11-45C6-8D03-F902239B38AE}']
    function GetForm: TCustomForm;
    function GetFrame: TCustomFrame;
    procedure SetForm(Form: TCustomForm);
    procedure SetFrame(Form: TCustomFrame);
  end;

  TDataSetVisualizerForm = class(TInterfacedObject, INTACustomDockableForm, IFrameFormHelper)
  private
    FMyFrame: TDataSetViewerFrame;
    FMyForm: TCustomForm;
    FExpression: string;
  public
    constructor Create(const Expression: string);
    { INTACustomDockableForm }
    function GetCaption: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    function GetIdentifier: string;
    function GetMenuActionList: TCustomActionList;
    function GetMenuImageList: TCustomImageList;
    procedure CustomizePopupMenu(PopupMenu: TPopupMenu);
    function GetToolbarActionList: TCustomActionList;
    function GetToolbarImageList: TCustomImageList;
    procedure CustomizeToolBar(ToolBar: TToolBar);
    procedure LoadWindowState(Desktop: TCustomIniFile; const Section: string);
    procedure SaveWindowState(Desktop: TCustomIniFile; const Section: string; IsProject: Boolean);
    function GetEditState: TEditState;
    function EditAction(Action: TEditAction): Boolean;
    { IFrameFormHelper }
    function GetForm: TCustomForm;
    function GetFrame: TCustomFrame;
    procedure SetForm(Form: TCustomForm);
    procedure SetFrame(Frame: TCustomFrame);
  end;

  TDebuggerDataSetVisualizer = class(TInterfacedObject, IOTADebuggerVisualizer,
    IOTADebuggerVisualizerExternalViewer)
  public
    function GetSupportedTypeCount: Integer;
    procedure GetSupportedType(Index: Integer; var TypeName: string;
      var AllDescendants: Boolean);
    function GetVisualizerIdentifier: string;
    function GetVisualizerName: string;
    function GetVisualizerDescription: string;
    function GetMenuText: string;
    function Show(const Expression, TypeName, EvalResult: string; Suggestedleft, SuggestedTop: Integer): IOTADebuggerVisualizerExternalViewerUpdater;
  end;

{ TDebuggerDateTimeVisualizer }

function TDebuggerDataSetVisualizer.GetMenuText: string;
begin
  Result := sMenuText;
end;

procedure TDebuggerDataSetVisualizer.GetSupportedType(Index: Integer;
  var TypeName: string; var AllDescendants: Boolean);
begin
  TypeName := 'TDataSet';
  AllDescendants := True;
end;

function TDebuggerDataSetVisualizer.GetSupportedTypeCount: Integer;
begin
  Result := 1;
end;

function TDebuggerDataSetVisualizer.GetVisualizerDescription: string;
begin
  Result := sDataSetVisualizerDescription;
end;

function TDebuggerDataSetVisualizer.GetVisualizerIdentifier: string;
begin
  Result := ClassName;
end;

function TDebuggerDataSetVisualizer.GetVisualizerName: string;
begin
  Result := sDataSetVisualizerName;
end;

function TDebuggerDataSetVisualizer.Show(const Expression, TypeName, EvalResult: string; SuggestedLeft, SuggestedTop: Integer): IOTADebuggerVisualizerExternalViewerUpdater;
var
  AForm: TCustomForm;
  AFrame: TDataSetViewerFrame;
  VisDockForm: INTACustomDockableForm;
begin
  VisDockForm := TDataSetVisualizerForm.Create(Expression) as INTACustomDockableForm;
  AForm := (BorlandIDEServices as INTAServices).CreateDockableForm(VisDockForm);
  AForm.Left := SuggestedLeft;
  AForm.Top := SuggestedTop;
  (VisDockForm as IFrameFormHelper).SetForm(AForm);
  AFrame := (VisDockForm as IFrameFormHelper).GetFrame as TDataSetViewerFrame;
  AFrame.AddDataSetItems(Expression, TypeName, EvalResult);
  Result := AFrame as IOTADebuggerVisualizerExternalViewerUpdater;
end;


{ TDataSetViewerFrame }

procedure TDataSetViewerFrame.AddDataSetItems(const Expression, TypeName,
  EvalResult: string);
var
  n,i : Integer;
  Res : string;
begin
  FAvailableState := asAvailable;
  FExpression := Expression;

  res:=Evaluate(FExpression+'.RecNo')+'/'+Evaluate(FExpression+'.RecordCount');
  StatusBar1.Panels[0].Text:=StringReplace(Res,'-1','-',[rfReplaceAll]);

  Res:=Evaluate(FExpression+'.FieldCount');
  StatusBar1.Panels[1].Text:='FieldCount='+Res;
  n:=StrToIntDef(Res,0);

  SG.RowCount:=max(n+1,2);
  SG.Cells[0,0]:='¹';
  SG.Cells[1,0]:='FieldName';
  SG.Cells[2,0]:='Value';
  SG.Cells[0,1]:='';
  SG.Cells[1,1]:='';
  SG.Cells[2,1]:='';
  for i:=0 to n-1 do begin
    SG.Cells[0,i+1]:=Format('%3.3d',[i+1]);
    SG.Cells[1,i+1]:=Evaluate(FExpression+'.Fields['+IntToStr(i)+'].FieldName').DeQuotedString;
    SG.Cells[2,i+1]:=Evaluate(FExpression+'.Fields['+IntToStr(i)+'].AsString').DeQuotedString;
  end;
end;

procedure TDataSetViewerFrame.AfterSave;
begin
end;

procedure TDataSetViewerFrame.BeforeSave;
begin
end;

procedure TDataSetViewerFrame.Button1Click(Sender: TObject);
begin
  Evaluate(FExpression+'.Prev');
  AddDataSetItems(FExpression,'','');
end;

procedure TDataSetViewerFrame.Button2Click(Sender: TObject);
begin
  Evaluate(FExpression+'.Next');
  AddDataSetItems(FExpression,'','');
end;

procedure TDataSetViewerFrame.Button3Click(Sender: TObject);
begin
  Evaluate(FExpression+'.First');
  AddDataSetItems(FExpression,'','');
end;

procedure TDataSetViewerFrame.Button4Click(Sender: TObject);
begin
  Evaluate(FExpression+'.Last');
  AddDataSetItems(FExpression,'','');
end;

procedure TDataSetViewerFrame.CloseVisualizer;
begin
  if FOwningForm <> nil then
    FOwningForm.Close;
end;

procedure TDataSetViewerFrame.Destroyed;
begin

end;

function TDataSetViewerFrame.Evaluate(Expression: string): string;
var
  CurProcess: IOTAProcess;
  CurThread: IOTAThread;
  ResultStr: array[0..4095] of Char;
  CanModify: Boolean;
  Done: Boolean;
  ResultAddr, ResultSize, ResultVal: LongWord;
  EvalRes: TOTAEvaluateResult;
  DebugSvcs: IOTADebuggerServices;
begin
  begin
    Result := '';
    if Supports(BorlandIDEServices, IOTADebuggerServices, DebugSvcs) then
      CurProcess := DebugSvcs.CurrentProcess;
    if CurProcess <> nil then
    begin
      CurThread := CurProcess.CurrentThread;
      if CurThread <> nil then
      begin
        repeat
        begin
          Done := True;
          EvalRes := CurThread.Evaluate(Expression, @ResultStr, Length(ResultStr),
            CanModify, eseAll, '', ResultAddr, ResultSize, ResultVal, '', 0);
          case EvalRes of
            erOK: Result := ResultStr;
            erDeferred:
              begin
                FCompleted := False;
                FDeferredResult := '';
                FDeferredError := False;
                FNotifierIndex := CurThread.AddNotifier(Self);
                while not FCompleted do
                  DebugSvcs.ProcessDebugEvents;
                CurThread.RemoveNotifier(FNotifierIndex);
                FNotifierIndex := -1;
                if not FDeferredError then
                begin
                  if FDeferredResult <> '' then
                    Result := FDeferredResult
                  else
                    Result := ResultStr;
                end;
              end;
            erBusy:
              begin
                DebugSvcs.ProcessDebugEvents;
                Done := False;
              end;
          end;
        end
        until Done = True;
      end;
    end;
  end;
end;

procedure TDataSetViewerFrame.EvaluateComplete(const ExprStr, ResultStr: string; CanModify: Boolean;
      ResultAddress, ResultSize: LongWord; ReturnCode: Integer);
begin
  EvaluateComplete(ExprStr, ResultStr, CanModify, TOTAAddress(ResultAddress), ResultSize, ReturnCode);
end;

procedure TDataSetViewerFrame.EvaluateComplete(const ExprStr, ResultStr: string; CanModify: Boolean;
      ResultAddress: TOTAAddress; ResultSize: LongWord; ReturnCode: Integer);
begin
  FCompleted := True;
  FDeferredResult := ResultStr;
  FDeferredError := ReturnCode <> 0;
end;

procedure TDataSetViewerFrame.MarkUnavailable(
  Reason: TOTAVisualizerUnavailableReason);
begin
  if Reason = ovurProcessRunning then
  begin
    FAvailableState := asProcRunning;
  end else if Reason = ovurOutOfScope then
    FAvailableState := asOutOfScope;
  SG.RowCount:=2;
  SG.Cells[0,0]:='';
  SG.Cells[1,0]:='';
  SG.Cells[2,0]:='';
  SG.Invalidate;
end;

procedure TDataSetViewerFrame.Modified;
begin

end;

procedure TDataSetViewerFrame.ModifyComplete(const ExprStr,
  ResultStr: string; ReturnCode: Integer);
begin

end;

procedure TDataSetViewerFrame.Panel1Resize(Sender: TObject);
begin
  SG.ColWidths[2]:=SG.ClientWidth-SG.ColWidths[0]-SG.ColWidths[1]-5;
end;

procedure TDataSetViewerFrame.RefreshVisualizer(const Expression, TypeName,
  EvalResult: string);
begin
  FAvailableState := asAvailable;
  AddDataSetItems(Expression, TypeName, EvalResult);
end;

procedure TDataSetViewerFrame.SetClosedCallback(
  ClosedProc: TOTAVisualizerClosedProcedure);
begin
  FClosedProc := ClosedProc;
end;

procedure TDataSetViewerFrame.SetForm(AForm: TCustomForm);
begin
  FOwningForm := AForm;
end;

procedure TDataSetViewerFrame.SetParent(AParent: TWinControl);
begin
  if AParent = nil then
  begin
    if Assigned(FClosedProc) then
      FClosedProc;
  end;
  inherited;
end;

procedure TDataSetViewerFrame.DataSetViewData(Sender: TObject;
  Item: TListItem);
var
  ItemCaption: string;
  ItemText: string;
begin
  case FAvailableState of
    asAvailable:
      begin
        ItemCaption := SG.Cells[0,SG.Row];
        ItemText := SG.Cells[1,SG.Row];
      end;
    asProcRunning:
      begin
        ItemCaption := sProcessNotAccessible;
        ItemText := sProcessNotAccessible;
      end;
    asOutOfScope:
      begin
        ItemCaption := sOutOfScope;
        ItemText := sOutOfScope;
      end;
    asNotAvailable:
      begin
        ItemCaption := sValueNotAccessible;
        ItemText := sValueNotAccessible;
      end;
  end;
  Item.Caption := ItemCaption;
  if Item.SubItems.Count = 0 then
    Item.SubItems.Add(ItemText)
  else
    Item.SubItems[0] := ItemText;
end;

procedure TDataSetViewerFrame.ThreadNotify(Reason: TOTANotifyReason);
begin

end;

{ TDataSetVisualizerForm }

constructor TDataSetVisualizerForm.Create(const Expression: string);
begin
  inherited Create;
  FExpression := Expression;
end;

procedure TDataSetVisualizerForm.CustomizePopupMenu(PopupMenu: TPopupMenu);
begin
  // no toolbar
end;

procedure TDataSetVisualizerForm.CustomizeToolBar(ToolBar: TToolBar);
begin
 // no toolbar
end;

function TDataSetVisualizerForm.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

procedure TDataSetVisualizerForm.FrameCreated(AFrame: TCustomFrame);
begin
  FMyFrame :=  TDataSetViewerFrame(AFrame);
end;

function TDataSetVisualizerForm.GetCaption: string;
begin
  Result := Format(sFormCaption, [FExpression]);
end;

function TDataSetVisualizerForm.GetEditState: TEditState;
begin
  Result := [];
end;

function TDataSetVisualizerForm.GetForm: TCustomForm;
begin
  Result := FMyForm;
end;

function TDataSetVisualizerForm.GetFrame: TCustomFrame;
begin
  Result := FMyFrame;
end;

function TDataSetVisualizerForm.GetFrameClass: TCustomFrameClass;
begin
  Result := TDataSetViewerFrame;
end;

function TDataSetVisualizerForm.GetIdentifier: string;
begin
  Result := 'DataSetDebugVisualizer';
end;

function TDataSetVisualizerForm.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TDataSetVisualizerForm.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

function TDataSetVisualizerForm.GetToolbarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TDataSetVisualizerForm.GetToolbarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TDataSetVisualizerForm.LoadWindowState(Desktop: TCustomIniFile;
  const Section: string);
begin
  //no desktop saving
end;

procedure TDataSetVisualizerForm.SaveWindowState(Desktop: TCustomIniFile;
  const Section: string; IsProject: Boolean);
begin
  //no desktop saving
end;

procedure TDataSetVisualizerForm.SetForm(Form: TCustomForm);
begin
  FMyForm := Form;
  if Assigned(FMyFrame) then
    FMyFrame.SetForm(FMyForm);
end;

procedure TDataSetVisualizerForm.SetFrame(Frame: TCustomFrame);
begin
   FMyFrame := TDataSetViewerFrame(Frame);
end;

var
  DataSetVis: IOTADebuggerVisualizer;

procedure Register;
begin
  DataSetVis := TDebuggerDataSetVisualizer.Create;
  (BorlandIDEServices as IOTADebuggerServices).RegisterDebugVisualizer(DataSetVis);
end;

procedure RemoveVisualizer;
var
  DebuggerServices: IOTADebuggerServices;
begin
  if Supports(BorlandIDEServices, IOTADebuggerServices, DebuggerServices) then
  begin
    DebuggerServices.UnregisterDebugVisualizer(DataSetVis);
    DataSetVis := nil;
  end;
end;

initialization
finalization
  RemoveVisualizer;
end.

