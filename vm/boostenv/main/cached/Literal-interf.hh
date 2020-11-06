class Literal {
public:
  Literal(RichNode self) : _self(self) {}
  Literal(UnstableNode& self) : _self(self) {}
  Literal(StableNode& self) : _self(self) {}

  bool isLiteral(mozart::VM vm) {
    if (_self.is<Atom>()) {
      return _self.as<Atom>().isLiteral(vm);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().isLiteral(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().isLiteral(vm);
    } else if (_self.is<NamedName>()) {
      return _self.as<NamedName>().isLiteral(vm);
    } else if (_self.is<UniqueName>()) {
      return _self.as<UniqueName>().isLiteral(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().isLiteral(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().isLiteral(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<Literal>().isLiteral(_self, vm);
    }
  }
protected:
  RichNode _self;
};

