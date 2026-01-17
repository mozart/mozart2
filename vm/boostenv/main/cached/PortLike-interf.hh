class PortLike {
public:
  PortLike(RichNode self) : _self(self) {}
  PortLike(UnstableNode& self) : _self(self) {}
  PortLike(StableNode& self) : _self(self) {}

  bool isPort(mozart::VM vm) {
    if (_self.is<Port>()) {
      return _self.as<Port>().isPort(vm);
    } else if (_self.is<VMPort>()) {
      return _self.as<VMPort>().isPort(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::PortLike::isPort", "isPort", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<PortLike>().isPort(_self, vm);
    }
  }

  void send(mozart::VM vm, mozart::RichNode value) {
    if (_self.is<Port>()) {
      return _self.as<Port>().send(vm, value);
    } else if (_self.is<VMPort>()) {
      return _self.as<VMPort>().send(vm, value);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::PortLike::send", "send", value))
          return;
      }
      return Interface<PortLike>().send(_self, vm, value);
    }
  }

  mozart::UnstableNode sendReceive(mozart::VM vm, mozart::RichNode value) {
    if (_self.is<Port>()) {
      return _self.as<Port>().sendReceive(vm, value);
    } else if (_self.is<VMPort>()) {
      return _self.as<VMPort>().sendReceive(vm, value);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::PortLike::sendReceive", "sendReceive", value, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<PortLike>().sendReceive(_self, vm, value);
    }
  }
protected:
  RichNode _self;
};

