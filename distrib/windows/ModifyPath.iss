[Code]

// Version log:
// 03/31/2003: Initial release (thv(at)lr.dk)

const
  // Modification method
  pmAddToBeginning = $1;      // Add dir to beginning of Path
  pmAddToEnd = $2;            // Add dir to end of Path
  pmAddAllways = $4;          // Add also if specified dir is already included in existing path
  pmAddOnlyIfDirExists = $8;  // Add only if specified dir actually exists
  pmRemove = $10;             // Remove dir from path
  pmRemoveSubdirsAlso = $20;  // Remove dir and all subdirs from path

  // Scope
  psCurrentUser = 1;          // Modify path for current user
  psAllUsers = 2;             // Modify path for all users

  // Error results
  mpOK = 0;                   // No errors
  mpMissingRights = -1;       // User has insufficient rights
  mpAutoexecNoWriteacc = -2;  // Autoexec can not be written (may be readonly)
  mpBothAddAndRemove = -3;    // User has specified that dir should both be removed from and added to path


{ Helper function: Split a path environment variable into individual dirnames }
function SplitPath(Path: string): TStringList ;
var
  Pos: Integer;
  S: string;
begin
  Result := TStringList.Create;
  S := '';
  for Pos :=1 to Length(Path) do
  begin
    if Path[Pos] <> ';' then
      S := S + Path[Pos];
    if (Path[Pos] = ';') or (Pos = Length(Path)) then
    begin
      S := Trim(s);
      S := RemoveQuotes(s);
      S := Trim(s);
      if S <> '' then
        Result.Add(S);
      S := '';
    end;
  end;
end; // function SplitPath


{ Helper procedure: Concatenate individual dirnames into a path environment variable }
function ConcatPath(Dirs: TStringList; Quotes: Boolean): string;
var
  Index, MaxIndex: Integer;
  S: string;
begin
  MaxIndex := Dirs.Count-1;
  Result := '';
  for Index := 0 to MaxIndex do
  begin
    S := Dirs.Strings[Index];
    if Quotes and (pos(' ', S) > 0) then
      S := AddQuotes(S);
    Result := Result + S;
    if Index < MaxIndex then
      Result := Result + ';'
  end;
end; // function ConcatPath


{ Helper function: Modifies path environment string }
function ModifyPathString(OldPath: string; DirName: string; Method: Integer; Quotes: Boolean): string;
var
  Dirs: TStringList;
  DirNotInPath: Boolean;
  I: Integer;
begin
  // Remove quotes form DirName
  DirName := Trim(DirName);
  DirName := RemoveQuotes(DirName);
  DirName := Trim(DirName);

  // Split old path in individual directory names
  Dirs := SplitPath(OldPath);

  // Check if dir is already in path
  DirNotInPath := True;
  for I:=0 to Dirs.Count-1 do
  begin
    if AnsiUpperCase(Dirs.Strings[I]) = AnsiUpperCase(DirName) then
      DirNotInPath := False;
  end;

  // Should dir be removed from existing Path?
  if (Method and (pmRemove or pmRemoveSubdirsAlso)) > 0 then
  begin
    for I:=0 to Dirs.Count-1 do
    begin
      if (((Method and pmRemoveSubdirsAlso) > 0) and (pos(AnsiUpperCase(DirName) + '', AnsiUpperCase(Dirs.Strings[I])) = 1)) or
         (((Method and (pmRemove) or (pmRemoveSubdirsAlso)) > 0) and (AnsiUpperCase(DirName) = AnsiUpperCase(Dirs.Strings[I])))
      then
        Dirs.Delete(I);
    end;
  end;

  // Should dir be added to existing Path?
  if (Method and (pmAddToBeginning or pmAddToEnd)) > 0 then
  begin
    // Add dir to path
    if ((Method and pmAddAllways) > 0) or DirNotInPath then
    begin
      // Dir is not in path already or should be added anyway
      if ((Method and pmAddOnlyIfDirExists) = 0) or DirExists(DirName) then
      begin
        // Dir actually exists or should be added anyway
        if (Method and pmAddToBeginning) > 0 then
          Dirs.Insert(0, DirName)
        else
          Dirs.Append(DirName);
      end;
    end;
  end;

  // Concatenate directory names into one single path variable
  Result := ConcatPath(Dirs, Quotes);
  // Finally free Dirs object
  Dirs.Free;
end; // function ModifyPathString

{ Main function: Modify path }
function ModifyPath(Path: string; Method: Integer; Scope: Integer): Integer;
var
  RegRootKey: Integer;
  RegSubKeyName: string;
  RegValueName: string;
  OldPath, ResultPath: string;
  OK: Boolean;
begin
  // Check if both add and remove has been specified (= error!)
  if (Method and (pmAddToBeginning or pmAddToEnd) and (pmRemove or pmRemoveSubdirsAlso)) > 0 then
  begin
    Result := mpBothAddAndRemove;
    Exit;
  end;

  // Perform directory constant expansion
  Path := ExpandConstantEx(Path, ' ', ' ');

  // Initialize registry key and value names to reflect if changes should be global or local to current user only
  case Scope of
    psCurrentUser:
      begin
        RegRootKey := HKEY_CURRENT_USER;
        RegSubKeyName := 'Environment';
        RegValueName := 'Path';
      end;
    psAllUsers:
      begin
        RegRootKey := HKEY_LOCAL_MACHINE;
        RegSubKeyName := 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
        RegValueName := 'Path';
      end;
  end;

  // Read current path value from registry
  OK := RegQueryStringValue(RegRootKey, RegSubKeyName, RegValueName, OldPath);
  if not OK and (Scope = psAllUsers) then
  begin
    Result := mpMissingRights;
    Exit;
  end;

  // Modify path
  ResultPath := ModifyPathString(OldPath, Path, Method, False);

  // Write new path value to registry
  if not RegWriteStringValue(RegRootKey, RegSubKeyName, RegValueName, ResultPath) then
  begin
    Result := mpMissingRights;
    Exit;
  end;

  // Expect everything to be OK
  Result := mpOK;
end; // ModifyPath
