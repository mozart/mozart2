class CellLike {
public:
  CellLike(RichNode self) : _self(self) {}
  CellLike(UnstableNode& self) : _self(self) {}
  CellLike(StableNode& self) : _self(self) {}

  bool isCell(mozart::VM vm) {
    if (_self.is<Cell>()) {
      return _self.as<Cell>().isCell(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::CellLike::isCell", "isCell", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<CellLike>().isCell(_self, vm);
    }
  }

  mozart::UnstableNode exchange(mozart::VM vm, mozart::RichNode newValue) {
    if (_self.is<Cell>()) {
      return _self.as<Cell>().exchange(vm, newValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::CellLike::exchange", "exchange", newValue, ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<CellLike>().exchange(_self, vm, newValue);
    }
  }

  mozart::UnstableNode access(mozart::VM vm) {
    if (_self.is<Cell>()) {
      return _self.as<Cell>().access(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::UnstableNode _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::CellLike::access", "access", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<CellLike>().access(_self, vm);
    }
  }

  void assign(mozart::VM vm, mozart::RichNode newValue) {
    if (_self.is<Cell>()) {
      return _self.as<Cell>().assign(vm, newValue);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::CellLike::assign", "assign", newValue))
          return;
      }
      return Interface<CellLike>().assign(_self, vm, newValue);
    }
  }
protected:
  RichNode _self;
};

