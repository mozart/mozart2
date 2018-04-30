class StringLike {
public:
  StringLike(RichNode self) : _self(self) {}
  StringLike(UnstableNode& self) : _self(self) {}
  StringLike(StableNode& self) : _self(self) {}

  bool isString(VM vm) {
    if (_self.is<String>()) {
      return _self.as<String>().isString(vm);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().isString(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().isString(_self, vm);
    }
  }

  bool isByteString(VM vm) {
    if (_self.is<String>()) {
      return _self.as<String>().isByteString(vm);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().isByteString(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().isByteString(_self, vm);
    }
  }

  LString<char> * stringGet(VM vm) {
    if (_self.is<String>()) {
      return _self.as<String>().stringGet(vm);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().stringGet(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().stringGet(_self, vm);
    }
  }

  LString<unsigned char> * byteStringGet(VM vm) {
    if (_self.is<String>()) {
      return _self.as<String>().byteStringGet(vm);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().byteStringGet(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().byteStringGet(_self, vm);
    }
  }

  nativeint stringCharAt(VM vm, class mozart::RichNode offset) {
    if (_self.is<String>()) {
      return _self.as<String>().stringCharAt(vm, offset);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().stringCharAt(vm, offset);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().stringCharAt(_self, vm, offset);
    }
  }

  class mozart::UnstableNode stringAppend(VM vm, class mozart::RichNode right) {
    if (_self.is<String>()) {
      return _self.as<String>().stringAppend(vm, right);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().stringAppend(vm, right);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().stringAppend(_self, vm, right);
    }
  }

  class mozart::UnstableNode stringSlice(VM vm, class mozart::RichNode from, class mozart::RichNode to) {
    if (_self.is<String>()) {
      return _self.as<String>().stringSlice(vm, from, to);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().stringSlice(vm, from, to);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().stringSlice(_self, vm, from, to);
    }
  }

  void stringSearch(VM vm, class mozart::RichNode from, class mozart::RichNode needle, class mozart::UnstableNode & begin, class mozart::UnstableNode & end) {
    if (_self.is<String>()) {
      return _self.as<String>().stringSearch(vm, from, needle, begin, end);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().stringSearch(vm, from, needle, begin, end);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().stringSearch(_self, vm, from, needle, begin, end);
    }
  }

  bool stringHasPrefix(VM vm, class mozart::RichNode prefix) {
    if (_self.is<String>()) {
      return _self.as<String>().stringHasPrefix(vm, prefix);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().stringHasPrefix(vm, prefix);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().stringHasPrefix(_self, vm, prefix);
    }
  }

  bool stringHasSuffix(VM vm, class mozart::RichNode suffix) {
    if (_self.is<String>()) {
      return _self.as<String>().stringHasSuffix(vm, suffix);
    } else if (_self.is<ByteString>()) {
      return _self.as<ByteString>().stringHasSuffix(vm, suffix);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      return Interface<StringLike>().stringHasSuffix(_self, vm, suffix);
    }
  }
protected:
  RichNode _self;
};

