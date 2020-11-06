class BaseDottable {
public:
  BaseDottable(RichNode self) : _self(self) {}
  BaseDottable(UnstableNode& self) : _self(self) {}
  BaseDottable(StableNode& self) : _self(self) {}

  bool lookupFeature(mozart::VM vm, mozart::RichNode feature, nullable<mozart::UnstableNode &> value) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().lookupFeature(vm, feature, value);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().lookupFeature(vm, feature, value);
    } else if (_self.is<Object>()) {
      return _self.as<Object>().lookupFeature(vm, feature, value);
    } else if (_self.is<Chunk>()) {
      return _self.as<Chunk>().lookupFeature(vm, feature, value);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().lookupFeature(vm, feature, value);
    } else if (_self.is<Array>()) {
      return _self.as<Array>().lookupFeature(vm, feature, value);
    } else if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().lookupFeature(vm, feature, value);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().lookupFeature(vm, feature, value);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().lookupFeature(vm, feature, value);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().lookupFeature(vm, feature, value);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().lookupFeature(vm, feature, value);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().lookupFeature(vm, feature, value);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::BaseDottable::lookupFeature", "lookupFeature", feature, value, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<BaseDottable>().lookupFeature(_self, vm, feature, value);
    }
  }

  bool lookupFeature(mozart::VM vm, mozart::nativeint feature, nullable<mozart::UnstableNode &> value) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().lookupFeature(vm, feature, value);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().lookupFeature(vm, feature, value);
    } else if (_self.is<Object>()) {
      return _self.as<Object>().lookupFeature(vm, feature, value);
    } else if (_self.is<Chunk>()) {
      return _self.as<Chunk>().lookupFeature(vm, feature, value);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().lookupFeature(vm, feature, value);
    } else if (_self.is<Array>()) {
      return _self.as<Array>().lookupFeature(vm, feature, value);
    } else if (_self.is<Dictionary>()) {
      return _self.as<Dictionary>().lookupFeature(vm, feature, value);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().lookupFeature(vm, feature, value);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().lookupFeature(vm, feature, value);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().lookupFeature(vm, feature, value);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().lookupFeature(vm, feature, value);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().lookupFeature(vm, feature, value);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::BaseDottable::lookupFeature", "lookupFeature", feature, value, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<BaseDottable>().lookupFeature(_self, vm, feature, value);
    }
  }
protected:
  RichNode _self;
};

