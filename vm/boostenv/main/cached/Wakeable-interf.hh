class Wakeable {
public:
  Wakeable(RichNode self) : _self(self) {}
  Wakeable(UnstableNode& self) : _self(self) {}
  Wakeable(StableNode& self) : _self(self) {}

  void wakeUp(mozart::VM vm) {
    if (_self.is<ReifiedThread>()) {
      return _self.as<ReifiedThread>().wakeUp(vm);
    } else if (_self.is<Variable>()) {
      return _self.as<Variable>().wakeUp(vm);
    } else if (_self.is<ReadOnly>()) {
      return _self.as<ReadOnly>().wakeUp(vm);
    } else {
      return Interface<Wakeable>().wakeUp(_self, vm);
    }
  }

  bool shouldWakeUpUnderSpace(mozart::VM vm, mozart::Space * space) {
    if (_self.is<ReifiedThread>()) {
      return _self.as<ReifiedThread>().shouldWakeUpUnderSpace(vm, space);
    } else if (_self.is<Variable>()) {
      return _self.as<Variable>().shouldWakeUpUnderSpace(vm, space);
    } else if (_self.is<ReadOnly>()) {
      return _self.as<ReadOnly>().shouldWakeUpUnderSpace(vm, space);
    } else {
      return Interface<Wakeable>().shouldWakeUpUnderSpace(_self, vm, space);
    }
  }
protected:
  RichNode _self;
};

