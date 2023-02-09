class BindableReadOnly {
public:
  BindableReadOnly(RichNode self) : _self(self) {}
  BindableReadOnly(UnstableNode& self) : _self(self) {}
  BindableReadOnly(StableNode& self) : _self(self) {}

  void bindReadOnly(mozart::VM vm, mozart::RichNode src) {
    if (_self.is<ReadOnlyVariable>()) {
      return _self.as<ReadOnlyVariable>().bindReadOnly(vm, src);
    } else if (_self.is<ReflectiveVariable>()) {
      return _self.as<ReflectiveVariable>().bindReadOnly(vm, src);
    } else {
      return Interface<BindableReadOnly>().bindReadOnly(_self, vm, src);
    }
  }
protected:
  RichNode _self;
};

