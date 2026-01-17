class PotentialFeature {
public:
  PotentialFeature(RichNode self) : _self(self) {}
  PotentialFeature(UnstableNode& self) : _self(self) {}
  PotentialFeature(StableNode& self) : _self(self) {}

  void makeFeature(mozart::VM vm) {
    if (_self.is<OptName>()) {
      return _self.as<OptName>().makeFeature(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<PotentialFeature>().makeFeature(_self, vm);
    }
  }
protected:
  RichNode _self;
};

