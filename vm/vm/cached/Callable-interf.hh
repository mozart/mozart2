class Callable {
public:
  Callable(RichNode self) : _self(self) {}
  Callable(UnstableNode& self) : _self(self) {}
  Callable(StableNode& self) : _self(self) {}

  bool isCallable(VM vm) {
    if (_self.is<Abstraction>()) {
      return _self.as<Abstraction>().isCallable(vm);
    } else if (_self.is<Object>()) {
      return _self.as<Object>().isCallable(vm);
    } else if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().isCallable(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<Callable>().isCallable(_self, vm);
    }
  }

  bool isProcedure(VM vm) {
    if (_self.is<Abstraction>()) {
      return _self.as<Abstraction>().isProcedure(vm);
    } else if (_self.is<Object>()) {
      return _self.as<Object>().isProcedure(vm);
    } else if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().isProcedure(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<Callable>().isProcedure(_self, vm);
    }
  }

  size_t procedureArity(VM vm) {
    if (_self.is<Abstraction>()) {
      return _self.as<Abstraction>().procedureArity(vm);
    } else if (_self.is<Object>()) {
      return _self.as<Object>().procedureArity(vm);
    } else if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().procedureArity(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<Callable>().procedureArity(_self, vm);
    }
  }

  void getCallInfo(VM vm, size_t & arity, ProgramCounter & start, size_t & Xcount, StaticArray<class mozart::StableNode> & Gs, StaticArray<class mozart::StableNode> & Ks) {
    if (_self.is<Abstraction>()) {
      return _self.as<Abstraction>().getCallInfo(vm, arity, start, Xcount, Gs, Ks);
    } else if (_self.is<Object>()) {
      return _self.as<Object>().getCallInfo(vm, arity, start, Xcount, Gs, Ks);
    } else if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().getCallInfo(vm, arity, start, Xcount, Gs, Ks);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<Callable>().getCallInfo(_self, vm, arity, start, Xcount, Gs, Ks);
    }
  }

  void getDebugInfo(VM vm, atom_t & printName, class mozart::UnstableNode & debugData) {
    if (_self.is<Abstraction>()) {
      return _self.as<Abstraction>().getDebugInfo(vm, printName, debugData);
    } else if (_self.is<Object>()) {
      return _self.as<Object>().getDebugInfo(vm, printName, debugData);
    } else if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().getDebugInfo(vm, printName, debugData);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<Callable>().getDebugInfo(_self, vm, printName, debugData);
    }
  }
protected:
  RichNode _self;
};

