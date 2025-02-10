class BuiltinCallable {
public:
  BuiltinCallable(RichNode self) : _self(self) {}
  BuiltinCallable(UnstableNode& self) : _self(self) {}
  BuiltinCallable(StableNode& self) : _self(self) {}

  bool isBuiltin(mozart::VM vm) {
    if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().isBuiltin(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<BuiltinCallable>().isBuiltin(_self, vm);
    }
  }

  void callBuiltin(mozart::VM vm, size_t argc, mozart::UnstableNode ** args) {
    if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().callBuiltin(vm, argc, args);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<BuiltinCallable>().callBuiltin(_self, vm, argc, args);
    }
  }

  template <class ... Args> 
  void callBuiltin(mozart::VM vm, Args &&... args) {
    if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().callBuiltin(vm, std::forward<Args>(args)...);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<BuiltinCallable>().callBuiltin(_self, vm, std::forward<Args>(args)...);
    }
  }

  builtins::BaseBuiltin * getBuiltin(mozart::VM vm) {
    if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().getBuiltin(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<BuiltinCallable>().getBuiltin(_self, vm);
    }
  }
protected:
  RichNode _self;
};

