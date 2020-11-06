class NameLike {
public:
  NameLike(RichNode self) : _self(self) {}
  NameLike(UnstableNode& self) : _self(self) {}
  NameLike(StableNode& self) : _self(self) {}

  bool isName(mozart::VM vm) {
    if (_self.is<OptName>()) {
      return _self.as<OptName>().isName(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().isName(vm);
    } else if (_self.is<NamedName>()) {
      return _self.as<NamedName>().isName(vm);
    } else if (_self.is<UniqueName>()) {
      return _self.as<UniqueName>().isName(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().isName(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().isName(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<NameLike>().isName(_self, vm);
    }
  }
protected:
  RichNode _self;
};

