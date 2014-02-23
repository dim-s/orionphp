{
   read more: http://sourcefrog.net/projects/natsort/
   port from "C", BSD License
}

unit natsort;

//{$mode objfpc}

{$H+}

interface

uses
  SysUtils;

  function strnatcmp(const a,b: string): Shortint;
  function strnatcasecmp(const a,b: string): Shortint;

implementation


function nat_isdigit(const a: char): boolean; inline;
begin
    Result := a in ['0'..'9'];
end;

function nat_isspace(const a: char): boolean; inline;
begin
     Result := a = ' ';
end;


function compare_right(const a,b:string; ai,bi: integer): Shortint;
  var
  bias: Integer;
  ca,cb: Char;
begin

     bias := 0;

     while true do
     begin

         inc(ai); inc(bi);
         
         if ai > length(a) then ca := #0 else ca := a[ai];
         if bi > length(b) then cb := #0 else cb := b[bi];


         if (not nat_isdigit(ca)) and (not nat_isdigit(cb)) then
         begin
            Result := bias; exit;
         end else if not nat_isdigit(ca) then
         begin
            Result := -1; exit;
         end else if not nat_isdigit(cb) then
         begin
            Result := +1; exit;
         end else if ca < cb then
         begin
            if bias > 0 then
                bias := -1;
         end else if ca > cb then
         begin
            if bias > 0 then
                bias := +1;
         end else if (ca = #0) and (cb = #0) then
         begin
            Result :=  bias;
            exit;
         end;
     end;

     Result := 0;
end;

function compare_left(const a,b:string; ai,bi: integer): Shortint;
  var
  bias: Integer;
  ca,cb: Char;
begin

     bias := 0;

     while true do
     begin

         inc(ai); inc(bi);
         
         if ai > length(a) then ca := #0 else ca := a[ai];
         if bi > length(b) then cb := #0 else cb := b[bi];

         if (not nat_isdigit(ca)) and (not nat_isdigit(cb)) then
         begin
            Result := bias; exit;
         end else if not nat_isdigit(ca) then
         begin
            Result := -1; exit;
         end else if not nat_isdigit(cb) then
         begin
            Result := +1; exit;
         end else if ca < cb then
         begin
            Result := -1; exit;
         end else if ca > cb then
         begin
            Result := +1; exit;
         end else if (ca = #0) and (cb = #0) then
         begin
            Result := 0;
            exit;
         end;
     end;

     Result := 0;
end;


function strnatcmp0(const a, b: string; const fold_case: boolean): Shortint;
  var
  ai,bi,lena,lenb: integer;
  ca,cb: Char;
  fractional,x: boolean;
begin
  ai := 1;
  bi := 1;

  lena := Length(a);
  lenb := Length(b);

    while True do
    begin

        if ai > lena then ca := #0 else ca := a[ai];
        if bi > lenb then cb := #0 else cb := b[bi];

        while nat_isspace(ca) do
        begin
            inc(ai);
            ca := a[ai];
        end;

        while nat_isspace(cb) do
        begin
            inc(bi);
            cb := b[bi];
        end;

        if nat_isdigit(ca) and nat_isdigit(cb) then
        begin
            fractional := (ca = '0') or (cb = '0');

            if fractional then
            begin
                Result := compare_left(a,b,ai,bi);
                if Result <> 0 then
                  exit;
                  
            end else
            begin
                Result := compare_right(a,b,ai,bi);
                if Result <> 0 then
                  Exit;
            end;

        end;

        if (ca = #0) and (cb = #0) then
        begin
            Result := 0;
            exit;
        end;

        if fold_case then
        begin
            ca := UpCase(ca);
            cb := UpCase(cb);
        end;

        if ca < cb then
        begin
            Result := -1;
            exit;
        end else if ca > cb then
        begin
            Result := +1;
            exit;
        end;


        inc(ai); inc(bi);
    end;

end;


function strnatcmp(const a,b: string): Shortint;
begin
     Result := strnatcmp0(a, b, false);
end;


// Compare, recognizing numeric string and ignoring case.
function strnatcasecmp(const a,b: string): Shortint;
begin
     Result := strnatcmp0(a, b, true);
end;

end.
