class StructuralEquatable {
public:
  StructuralEquatable(RichNode self) : _self(self) {}
  StructuralEquatable(UnstableNode& self) : _self(self) {}
  StructuralEquatable(StableNode& self) : _self(self) {}

  bool equals(mozart::VM vm, mozart::RichNode right, mozart::WalkStack & stack) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().equals(vm, right, stack);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().equals(vm, right, stack);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().equals(vm, right, stack);
    } else if (_self.is<Arity>()) {
      return _self.as<Arity>().equals(vm, right, stack);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StructuralEquatable>().equals(_self, vm, right, stack);
    }
  }
protected:
  RichNode _self;
};

