
unit USongQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, SyncObjs;

type
  TSongQueueItem = class
  public
    SongID: Integer;
    PlayerName: string;
    constructor Create(ASongID: Integer; APlayerName: string);
  end;

  TSongQueue = class
  private
    FQueue: TObjectList;
    FCriticalSection: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddSong(SongID: Integer; PlayerName: string);
    function GetNextSong: TSongQueueItem;
    function GetQueue: TObjectList; deprecated 'Use GetQueueCopy for thread-safe iteration';
    function GetQueueCopy: TObjectList;
    function IsEmpty: Boolean;
    procedure Clear;
    function Count: Integer;
  end;

implementation

{ TSongQueueItem }
constructor TSongQueueItem.Create(ASongID: Integer; APlayerName: string);
begin
  SongID := ASongID;
  PlayerName := APlayerName;
end;

{ TSongQueue }
constructor TSongQueue.Create;
begin
  inherited Create;
  FQueue := TObjectList.Create(True); // True to own objects
  FCriticalSection := TCriticalSection.Create;
end;

destructor TSongQueue.Destroy;
begin
  FCriticalSection.Enter;
  try
    FQueue.Free;
  finally
    FCriticalSection.Leave;
  end;
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TSongQueue.AddSong(SongID: Integer; PlayerName: string);
var
  Item: TSongQueueItem;
begin
  Item := TSongQueueItem.Create(SongID, PlayerName);
  FCriticalSection.Enter;
  try
    FQueue.Add(Item);
  finally
    FCriticalSection.Leave;
  end;
end;

function TSongQueue.GetNextSong: TSongQueueItem;
begin
  Result := nil;
  FCriticalSection.Enter;
  try
    if FQueue.Count > 0 then
    begin
      Result := TSongQueueItem(FQueue[0]);
      FQueue.Extract(FQueue[0]);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSongQueue.GetQueue: TObjectList;
begin
  // This is not thread-safe for direct iteration.
  // For thread-safe access, methods to copy the list should be added.
  Result := FQueue;
end;

function TSongQueue.GetQueueCopy: TObjectList;
var
  i: Integer;
begin
  Result := TObjectList.Create(False); // False: does not own objects
  FCriticalSection.Enter;
  try
    for i := 0 to FQueue.Count - 1 do
      Result.Add(FQueue[i]);
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSongQueue.Clear;
begin
  FCriticalSection.Enter;
  try
    FQueue.Clear;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSongQueue.Count: Integer;
begin
  FCriticalSection.Enter;
  try
    Result := FQueue.Count;
  finally
    FCriticalSection.Leave;
  end;
end;

function TSongQueue.IsEmpty: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FQueue.Count = 0;
  finally
    FCriticalSection.Leave;
  end;
end;


end.
