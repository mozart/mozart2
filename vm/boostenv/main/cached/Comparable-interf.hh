class Comparable {
public:
  Comparable(RichNode self) : _self(self) {}
  Comparable(UnstableNode& self) : _self(self) {}
  Comparable(StableNode& self) : _self(self) {}

  int compare(mozart::VM vm, mozart::RichNode right) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().compare(vm, right);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().compare(vm, right);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().compare(vm, right);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().compare(vm, right);
    } else if (_self.is<String>()) {
      return _self.as<String>().compare(vm, right);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().compare(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        int _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Comparable::compare", "compare", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Comparable>().compare(_self, vm, right);
    }
  }
protected:
  RichNode _self;
};

