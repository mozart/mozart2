class BuiltinProcedure;

template <>
class Storage<BuiltinProcedure> {
public:
  typedef builtins::BaseBuiltin * Type;
};
