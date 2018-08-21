class Numeric {
public:
  Numeric(RichNode self) : _self(self) {}
  Numeric(UnstableNode& self) : _self(self) {}
  Numeric(StableNode& self) : _self(self) {}

  bool isNumber(VM vm) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().isNumber(vm);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().isNumber(vm);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().isNumber(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::isNumber", "isNumber", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().isNumber(_self, vm);
    }
  }

  bool isInt(VM vm) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().isInt(vm);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().isInt(vm);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().isInt(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::isInt", "isInt", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().isInt(_self, vm);
    }
  }

  bool isFloat(VM vm) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().isFloat(vm);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().isFloat(vm);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().isFloat(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::isFloat", "isFloat", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().isFloat(_self, vm);
    }
  }

  class mozart::UnstableNode opposite(VM vm) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().opposite(vm);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().opposite(vm);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().opposite(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::opposite", "opposite", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().opposite(_self, vm);
    }
  }

  class mozart::UnstableNode add(VM vm, class mozart::RichNode right) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().add(vm, right);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().add(vm, right);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().add(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::add", "add", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().add(_self, vm, right);
    }
  }

  class mozart::UnstableNode add(VM vm, nativeint right) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().add(vm, right);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().add(vm, right);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().add(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::add", "add", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().add(_self, vm, right);
    }
  }

  class mozart::UnstableNode subtract(VM vm, class mozart::RichNode right) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().subtract(vm, right);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().subtract(vm, right);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().subtract(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::subtract", "subtract", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().subtract(_self, vm, right);
    }
  }

  class mozart::UnstableNode multiply(VM vm, class mozart::RichNode right) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().multiply(vm, right);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().multiply(vm, right);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().multiply(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::multiply", "multiply", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().multiply(_self, vm, right);
    }
  }

  class mozart::UnstableNode div(VM vm, class mozart::RichNode right) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().div(vm, right);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().div(vm, right);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().div(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::div", "div", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().div(_self, vm, right);
    }
  }

  class mozart::UnstableNode mod(VM vm, class mozart::RichNode right) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().mod(vm, right);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().mod(vm, right);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().mod(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::mod", "mod", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().mod(_self, vm, right);
    }
  }

  class mozart::UnstableNode abs(VM vm) {
    if (_self.is<SmallInt>()) {
      return _self.as<SmallInt>().abs(vm);
    } else if (_self.is<BigInt>()) {
      return _self.as<BigInt>().abs(vm);
    } else if (_self.is<Float>()) {
      return _self.as<Float>().abs(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        class mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::Numeric::abs", "abs", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<Numeric>().abs(_self, vm);
    }
  }
protected:
  RichNode _self;
};

