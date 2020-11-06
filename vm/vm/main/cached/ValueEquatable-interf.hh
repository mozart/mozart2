class ValueEquatable {
public:
  ValueEquatable(RichNode self) : _self(self) {}
  ValueEquatable(UnstableNode& self) : _self(self) {}
  ValueEquatable(StableNode& self) : _self(self) {}

  bool equals(mozart::VM vm, mozart::RichNode right) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().equals(vm, right);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().equals(vm, right);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().equals(vm, right);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().equals(vm, right);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().equals(vm, right);
    } else if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().equals(vm, right);
    } else if (_self.is<ReifiedThread>()) {
      return _self.as<ReifiedThread>().equals(vm, right);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().equals(vm, right);
    } else if (_self.is<String>()) {
      return _self.as<String>().equals(vm, right);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().equals(vm, right);
    } else if (_self.is<UniqueName>()) {
      return _self.as<UniqueName>().equals(vm, right);
    } else if (_self.is<PatMatCapture>()) {
      return _self.as<PatMatCapture>().equals(vm, right);
    } else if (_self.is<VMPort>()) {
      return _self.as<VMPort>().equals(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<ValueEquatable>().equals(_self, vm, right);
    }
  }
protected:
  RichNode _self;
};

