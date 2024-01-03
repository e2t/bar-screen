unit StringUtils;

{$mode ObjFPC}{$H+}

interface

function Heading(const AText: String): String;

implementation

function Heading(const AText: String): String;
const
  Indent = '======';
begin
  Result := Indent + ' ' + AText + ' ' + Indent;
end;

end.
