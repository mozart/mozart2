class ThreadLike {
public:
  ThreadLike(RichNode self) : _self(self) {}
  ThreadLike(UnstableNode& self) : _self(self) {}
  ThreadLike(StableNode& self) : _self(self) {}

  bool isThread(VM vm) {
    if (_self.is<ReifiedThread>()) {
      return _self.as<ReifiedThread>().isThread(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<ThreadLike>().isThread(_self, vm);
    }
  }

  enum mozart::ThreadPriority getThreadPriority(VM vm) {
    if (_self.is<ReifiedThread>()) {
      return _self.as<ReifiedThread>().getThreadPriority(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<ThreadLike>().getThreadPriority(_self, vm);
    }
  }

  void setThreadPriority(VM vm, enum mozart::ThreadPriority priority) {
    if (_self.is<ReifiedThread>()) {
      return _self.as<ReifiedThread>().setThreadPriority(vm, priority);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<ThreadLike>().setThreadPriority(_self, vm, priority);
    }
  }

  void injectException(VM vm, class mozart::RichNode exception) {
    if (_self.is<ReifiedThread>()) {
      return _self.as<ReifiedThread>().injectException(vm, exception);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<ThreadLike>().injectException(_self, vm, exception);
    }
  }
protected:
  RichNode _self;
};

