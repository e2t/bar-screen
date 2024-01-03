unit Optional;

{$mode ObjFPC}{$H+}

interface

type
  generic TOptional<T> = record
    Value: T;
    HasValue: Boolean;
  end;

implementation

end.
