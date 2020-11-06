class WithPrintName {
public:
  WithPrintName(RichNode self) : _self(self) {}
  WithPrintName(UnstableNode& self) : _self(self) {}
  WithPrintName(StableNode& self) : _self(self) {}

  mozart::atom_t getPrintName(mozart::VM vm) {
    if (_self.is<Abstraction>()) {
      return _self.as<Abstraction>().getPrintName(vm);
    } else if (_self.is<BuiltinProcedure>()) {
      return _self.as<BuiltinProcedure>().getPrintName(vm);
    } else if (_self.is<UniqueName>()) {
      return _self.as<UniqueName>().getPrintName(vm);
    } else if (_self.is<NamedName>()) {
      return _self.as<NamedName>().getPrintName(vm);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().getPrintName(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().getPrintName(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().getPrintName(vm);
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        mozart::atom_t _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::WithPrintName::getPrintName", "getPrintName", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<WithPrintName>().getPrintName(_self, vm);
    }
  }
protected:
  RichNode _self;
};

