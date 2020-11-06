class DotAssignable {
public:
  DotAssignable(RichNode self) : _self(self) {}
  DotAssignable(UnstableNode& self) : _self(self) {}
  DotAssignable(StableNode& self) : _self(self) {}

  void dotAssign(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue) {
    if (_self.is<Array>()) {
      return _self.as<Array>().dotAssign(vm, feature, newValue);
    } else if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dotAssign(vm, feature, newValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DotAssignable::dotAssign", "dotAssign", feature, newValue))
          return;
      }
      return Interface<DotAssignable>().dotAssign(_self, vm, feature, newValue);
    }
  }

  mozart::UnstableNode dotExchange(mozart::VM vm, mozart::RichNode feature, mozart::RichNode newValue) {
    if (_self.is<Array>()) {
      return _self.as<Array>().dotExchange(vm, feature, newValue);
    } else if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dotExchange(vm, feature, newValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DotAssignable::dotExchange", "dotExchange", feature, newValue, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DotAssignable>().dotExchange(_self, vm, feature, newValue);
    }
  }
protected:
  RichNode _self;
};

