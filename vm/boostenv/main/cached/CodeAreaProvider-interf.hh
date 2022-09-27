class CodeAreaProvider {
public:
  CodeAreaProvider(RichNode self) : _self(self) {}
  CodeAreaProvider(UnstableNode& self) : _self(self) {}
  CodeAreaProvider(StableNode& self) : _self(self) {}

  bool isCodeAreaProvider(mozart::VM vm) {
    if (_self.is<CodeArea>()) {
      return _self.as<CodeArea>().isCodeAreaProvider(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<CodeAreaProvider>().isCodeAreaProvider(_self, vm);
    }
  }

  void getCodeAreaInfo(mozart::VM vm, size_t & arity, mozart::ProgramCounter & start, size_t & Xcount, StaticArray<mozart::StableNode> & Ks) {
    if (_self.is<CodeArea>()) {
      return _self.as<CodeArea>().getCodeAreaInfo(vm, arity, start, Xcount, Ks);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<CodeAreaProvider>().getCodeAreaInfo(_self, vm, arity, start, Xcount, Ks);
    }
  }

  void getCodeAreaDebugInfo(mozart::VM vm, mozart::atom_t & printName, mozart::UnstableNode & debugData) {
    if (_self.is<CodeArea>()) {
      return _self.as<CodeArea>().getCodeAreaDebugInfo(vm, printName, debugData);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<CodeAreaProvider>().getCodeAreaDebugInfo(_self, vm, printName, debugData);
    }
  }
protected:
  RichNode _self;
};

