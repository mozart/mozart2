class DataflowVariable {
public:
  DataflowVariable(RichNode self) : _self(self) {}
  DataflowVariable(UnstableNode& self) : _self(self) {}
  DataflowVariable(StableNode& self) : _self(self) {}

  void addToSuspendList(mozart::VM vm, mozart::RichNode variable) {
    if (_self.is<OptVar>()) {
      return _self.as<OptVar>().addToSuspendList(vm, variable);
    } else if (_self.is<Variable>()) {
      return _self.as<Variable>().addToSuspendList(vm, variable);
    } else if (_self.is<ReadOnly>()) {
      return _self.as<ReadOnly>().addToSuspendList(vm, variable);
    } else if (_self.is<ReadOnlyVariable>()) {
      return _self.as<ReadOnlyVariable>().addToSuspendList(vm, variable);
    } else if (_self.is<FailedValue>()) {
      return _self.as<FailedValue>().addToSuspendList(vm, variable);
    } else if (_self.is<ReflectiveVariable>()) {
      return _self.as<ReflectiveVariable>().addToSuspendList(vm, variable);
    } else {
      return Interface<DataflowVariable>().addToSuspendList(_self, vm, variable);
    }
  }

  bool isNeeded(mozart::VM vm) {
    if (_self.is<OptVar>()) {
      return _self.as<OptVar>().isNeeded(vm);
    } else if (_self.is<Variable>()) {
      return _self.as<Variable>().isNeeded(vm);
    } else if (_self.is<ReadOnly>()) {
      return _self.as<ReadOnly>().isNeeded(vm);
    } else if (_self.is<ReadOnlyVariable>()) {
      return _self.as<ReadOnlyVariable>().isNeeded(vm);
    } else if (_self.is<FailedValue>()) {
      return _self.as<FailedValue>().isNeeded(vm);
    } else if (_self.is<ReflectiveVariable>()) {
      return _self.as<ReflectiveVariable>().isNeeded(vm);
    } else {
      return Interface<DataflowVariable>().isNeeded(_self, vm);
    }
  }

  void markNeeded(mozart::VM vm) {
    if (_self.is<OptVar>()) {
      return _self.as<OptVar>().markNeeded(vm);
    } else if (_self.is<Variable>()) {
      return _self.as<Variable>().markNeeded(vm);
    } else if (_self.is<ReadOnly>()) {
      return _self.as<ReadOnly>().markNeeded(vm);
    } else if (_self.is<ReadOnlyVariable>()) {
      return _self.as<ReadOnlyVariable>().markNeeded(vm);
    } else if (_self.is<FailedValue>()) {
      return _self.as<FailedValue>().markNeeded(vm);
    } else if (_self.is<ReflectiveVariable>()) {
      return _self.as<ReflectiveVariable>().markNeeded(vm);
    } else {
      return Interface<DataflowVariable>().markNeeded(_self, vm);
    }
  }

  void bind(mozart::VM vm, mozart::RichNode src) {
    if (_self.is<OptVar>()) {
      return _self.as<OptVar>().bind(vm, src);
    } else if (_self.is<Variable>()) {
      return _self.as<Variable>().bind(vm, src);
    } else if (_self.is<ReadOnly>()) {
      return _self.as<ReadOnly>().bind(vm, src);
    } else if (_self.is<ReadOnlyVariable>()) {
      return _self.as<ReadOnlyVariable>().bind(vm, src);
    } else if (_self.is<FailedValue>()) {
      return _self.as<FailedValue>().bind(vm, src);
    } else if (_self.is<ReflectiveVariable>()) {
      return _self.as<ReflectiveVariable>().bind(vm, src);
    } else {
      return Interface<DataflowVariable>().bind(_self, vm, src);
    }
  }
protected:
  RichNode _self;
};

