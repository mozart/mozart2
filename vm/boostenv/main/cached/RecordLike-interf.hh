class RecordLike {
public:
  RecordLike(RichNode self) : _self(self) {}
  RecordLike(UnstableNode& self) : _self(self) {}
  RecordLike(StableNode& self) : _self(self) {}

  bool isRecord(mozart::VM vm) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().isRecord(vm);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().isRecord(vm);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().isRecord(vm);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().isRecord(vm);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().isRecord(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().isRecord(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().isRecord(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().isRecord(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().isRecord(_self, vm);
    }
  }

  bool isTuple(mozart::VM vm) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().isTuple(vm);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().isTuple(vm);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().isTuple(vm);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().isTuple(vm);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().isTuple(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().isTuple(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().isTuple(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().isTuple(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().isTuple(_self, vm);
    }
  }

  mozart::UnstableNode label(mozart::VM vm) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().label(vm);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().label(vm);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().label(vm);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().label(vm);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().label(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().label(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().label(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().label(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().label(_self, vm);
    }
  }

  size_t width(mozart::VM vm) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().width(vm);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().width(vm);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().width(vm);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().width(vm);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().width(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().width(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().width(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().width(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().width(_self, vm);
    }
  }

  mozart::UnstableNode arityList(mozart::VM vm) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().arityList(vm);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().arityList(vm);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().arityList(vm);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().arityList(vm);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().arityList(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().arityList(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().arityList(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().arityList(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().arityList(_self, vm);
    }
  }

  mozart::UnstableNode clone(mozart::VM vm) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().clone(vm);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().clone(vm);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().clone(vm);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().clone(vm);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().clone(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().clone(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().clone(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().clone(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().clone(_self, vm);
    }
  }

  mozart::UnstableNode waitOr(mozart::VM vm) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().waitOr(vm);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().waitOr(vm);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().waitOr(vm);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().waitOr(vm);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().waitOr(vm);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().waitOr(vm);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().waitOr(vm);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().waitOr(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().waitOr(_self, vm);
    }
  }

  bool testRecord(mozart::VM vm, mozart::RichNode arity) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().testRecord(vm, arity);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().testRecord(vm, arity);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().testRecord(vm, arity);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().testRecord(vm, arity);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().testRecord(vm, arity);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().testRecord(vm, arity);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().testRecord(vm, arity);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().testRecord(vm, arity);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().testRecord(_self, vm, arity);
    }
  }

  bool testTuple(mozart::VM vm, mozart::RichNode label, size_t width) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().testTuple(vm, label, width);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().testTuple(vm, label, width);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().testTuple(vm, label, width);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().testTuple(vm, label, width);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().testTuple(vm, label, width);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().testTuple(vm, label, width);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().testTuple(vm, label, width);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().testTuple(vm, label, width);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().testTuple(_self, vm, label, width);
    }
  }

  bool testLabel(mozart::VM vm, mozart::RichNode label) {
    if (_self.is<Tuple>()) {
      return _self.as<Tuple>().testLabel(vm, label);
    } else if (_self.is<Record>()) {
      return _self.as<Record>().testLabel(vm, label);
    } else if (_self.is<Cons>()) {
      return _self.as<Cons>().testLabel(vm, label);
    } else if (_self.is<Atom>()) {
      return _self.as<Atom>().testLabel(vm, label);
    } else if (_self.is<OptName>()) {
      return _self.as<OptName>().testLabel(vm, label);
    } else if (_self.is<GlobalName>()) {
      return _self.as<GlobalName>().testLabel(vm, label);
    } else if (_self.is<Boolean>()) {
      return _self.as<Boolean>().testLabel(vm, label);
    } else if (_self.is<Unit>()) {
      return _self.as<Unit>().testLabel(vm, label);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<RecordLike>().testLabel(_self, vm, label);
    }
  }
protected:
  RichNode _self;
};

