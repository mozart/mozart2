class DictionaryLike {
public:
  DictionaryLike(RichNode self) : _self(self) {}
  DictionaryLike(UnstableNode& self) : _self(self) {}
  DictionaryLike(StableNode& self) : _self(self) {}

  bool isDictionary(VM vm) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().isDictionary(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::isDictionary", "isDictionary", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().isDictionary(_self, vm);
    }
  }

  bool dictIsEmpty(VM vm) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictIsEmpty(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictIsEmpty", "dictIsEmpty", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictIsEmpty(_self, vm);
    }
  }

  bool dictMember(VM vm, class mozart::RichNode feature) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictMember(vm, feature);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictMember", "dictMember", feature, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictMember(_self, vm, feature);
    }
  }

  class mozart::UnstableNode dictGet(VM vm, class mozart::RichNode feature) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictGet(vm, feature);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictGet", "dictGet", feature, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictGet(_self, vm, feature);
    }
  }

  class mozart::UnstableNode dictCondGet(VM vm, class mozart::RichNode feature, class mozart::RichNode defaultValue) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictCondGet(vm, feature, defaultValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictCondGet", "dictCondGet", feature, defaultValue, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictCondGet(_self, vm, feature, defaultValue);
    }
  }

  void dictPut(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictPut(vm, feature, newValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictPut", "dictPut", feature, newValue))
          return;
      }
      return Interface<DictionaryLike>().dictPut(_self, vm, feature, newValue);
    }
  }

  class mozart::UnstableNode dictExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode newValue) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictExchange(vm, feature, newValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictExchange", "dictExchange", feature, newValue, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictExchange(_self, vm, feature, newValue);
    }
  }

  class mozart::UnstableNode dictCondExchange(VM vm, class mozart::RichNode feature, class mozart::RichNode defaultValue, class mozart::RichNode newValue) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictCondExchange(vm, feature, defaultValue, newValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictCondExchange", "dictCondExchange", feature, defaultValue, newValue, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictCondExchange(_self, vm, feature, defaultValue, newValue);
    }
  }

  void dictRemove(VM vm, class mozart::RichNode feature) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictRemove(vm, feature);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictRemove", "dictRemove", feature))
          return;
      }
      return Interface<DictionaryLike>().dictRemove(_self, vm, feature);
    }
  }

  void dictRemoveAll(VM vm) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictRemoveAll(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictRemoveAll", "dictRemoveAll"))
          return;
      }
      return Interface<DictionaryLike>().dictRemoveAll(_self, vm);
    }
  }

  class mozart::UnstableNode dictKeys(VM vm) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictKeys(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictKeys", "dictKeys", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictKeys(_self, vm);
    }
  }

  class mozart::UnstableNode dictEntries(VM vm) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictEntries(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictEntries", "dictEntries", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictEntries(_self, vm);
    }
  }

  class mozart::UnstableNode dictItems(VM vm) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictItems(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictItems", "dictItems", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictItems(_self, vm);
    }
  }

  class mozart::UnstableNode dictClone(VM vm) {
    if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().dictClone(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::DictionaryLike::dictClone", "dictClone", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<DictionaryLike>().dictClone(_self, vm);
    }
  }
protected:
  RichNode _self;
};

