class AtomLike {
public:
  AtomLike(RichNode self) : _self(self) {}
  AtomLike(UnstableNode& self) : _self(self) {}
  AtomLike(StableNode& self) : _self(self) {}

  bool isAtom(mozart::VM vm) {
    if (_self.is<Atom>()) {
      return _self.as<Atom>().isAtom(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<AtomLike>().isAtom(_self, vm);
    }
  }
protected:
  RichNode _self;
};

