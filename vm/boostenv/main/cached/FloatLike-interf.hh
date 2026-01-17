class FloatLike {
public:
  FloatLike(RichNode self) : _self(self) {}
  FloatLike(UnstableNode& self) : _self(self) {}
  FloatLike(StableNode& self) : _self(self) {}

  mozart::UnstableNode divide(mozart::VM vm, mozart::RichNode right) {
    if (_self.is<Float>()) {
      return _self.as<Float>().divide(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::divide", "divide", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().divide(_self, vm, right);
    }
  }

  mozart::UnstableNode pow(mozart::VM vm, mozart::RichNode right) {
    if (_self.is<Float>()) {
      return _self.as<Float>().pow(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::pow", "pow", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().pow(_self, vm, right);
    }
  }

  mozart::UnstableNode fmod(mozart::VM vm, mozart::RichNode right) {
    if (_self.is<Float>()) {
      return _self.as<Float>().fmod(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::fmod", "fmod", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().fmod(_self, vm, right);
    }
  }

  mozart::UnstableNode acos(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().acos(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::acos", "acos", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().acos(_self, vm);
    }
  }

  mozart::UnstableNode acosh(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().acosh(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::acosh", "acosh", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().acosh(_self, vm);
    }
  }

  mozart::UnstableNode asin(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().asin(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::asin", "asin", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().asin(_self, vm);
    }
  }

  mozart::UnstableNode asinh(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().asinh(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::asinh", "asinh", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().asinh(_self, vm);
    }
  }

  mozart::UnstableNode atan(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().atan(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::atan", "atan", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().atan(_self, vm);
    }
  }

  mozart::UnstableNode atanh(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().atanh(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::atanh", "atanh", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().atanh(_self, vm);
    }
  }

  mozart::UnstableNode atan2(mozart::VM vm, mozart::RichNode right) {
    if (_self.is<Float>()) {
      return _self.as<Float>().atan2(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::atan2", "atan2", right, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().atan2(_self, vm, right);
    }
  }

  mozart::UnstableNode ceil(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().ceil(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::ceil", "ceil", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().ceil(_self, vm);
    }
  }

  mozart::UnstableNode cos(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().cos(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::cos", "cos", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().cos(_self, vm);
    }
  }

  mozart::UnstableNode cosh(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().cosh(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::cosh", "cosh", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().cosh(_self, vm);
    }
  }

  mozart::UnstableNode exp(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().exp(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::exp", "exp", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().exp(_self, vm);
    }
  }

  mozart::UnstableNode floor(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().floor(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::floor", "floor", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().floor(_self, vm);
    }
  }

  mozart::UnstableNode log(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().log(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::log", "log", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().log(_self, vm);
    }
  }

  mozart::UnstableNode round(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().round(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::round", "round", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().round(_self, vm);
    }
  }

  mozart::UnstableNode sin(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().sin(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::sin", "sin", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().sin(_self, vm);
    }
  }

  mozart::UnstableNode sinh(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().sinh(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::sinh", "sinh", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().sinh(_self, vm);
    }
  }

  mozart::UnstableNode sqrt(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().sqrt(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::sqrt", "sqrt", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().sqrt(_self, vm);
    }
  }

  mozart::UnstableNode tan(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().tan(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::tan", "tan", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().tan(_self, vm);
    }
  }

  mozart::UnstableNode tanh(mozart::VM vm) {
    if (_self.is<Float>()) {
      return _self.as<Float>().tanh(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::FloatLike::tanh", "tanh", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<FloatLike>().tanh(_self, vm);
    }
  }
protected:
  RichNode _self;
};

