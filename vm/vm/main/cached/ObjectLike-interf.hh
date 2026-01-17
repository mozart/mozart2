class ObjectLike {
public:
  ObjectLike(RichNode self) : _self(self) {}
  ObjectLike(UnstableNode& self) : _self(self) {}
  ObjectLike(StableNode& self) : _self(self) {}

  bool isObject(mozart::VM vm) {
    if (_self.is<Object>()) {
      return _self.as<Object>().isObject(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::ObjectLike::isObject", "isObject", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<ObjectLike>().isObject(_self, vm);
    }
  }

  mozart::UnstableNode getClass(mozart::VM vm) {
    if (_self.is<Object>()) {
      return _self.as<Object>().getClass(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::ObjectLike::getClass", "getClass", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<ObjectLike>().getClass(_self, vm);
    }
  }

  mozart::UnstableNode attrGet(mozart::VM vm, mozart::RichNode attribute) {
    if (_self.is<Object>()) {
      return _self.as<Object>().attrGet(vm, attribute);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::ObjectLike::attrGet", "attrGet", attribute, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<ObjectLike>().attrGet(_self, vm, attribute);
    }
  }

  void attrPut(mozart::VM vm, mozart::RichNode attribute, mozart::RichNode value) {
    if (_self.is<Object>()) {
      return _self.as<Object>().attrPut(vm, attribute, value);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::ObjectLike::attrPut", "attrPut", attribute, value))
          return;
      }
      return Interface<ObjectLike>().attrPut(_self, vm, attribute, value);
    }
  }

  mozart::UnstableNode attrExchange(mozart::VM vm, mozart::RichNode attribute, mozart::RichNode newValue) {
    if (_self.is<Object>()) {
      return _self.as<Object>().attrExchange(vm, attribute, newValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::ObjectLike::attrExchange", "attrExchange", attribute, newValue, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<ObjectLike>().attrExchange(_self, vm, attribute, newValue);
    }
  }
protected:
  RichNode _self;
};

