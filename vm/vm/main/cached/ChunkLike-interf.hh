class ChunkLike {
public:
  ChunkLike(RichNode self) : _self(self) {}
  ChunkLike(UnstableNode& self) : _self(self) {}
  ChunkLike(StableNode& self) : _self(self) {}

  bool isChunk(mozart::VM vm) {
    if (_self.is<Chunk>()) {
      return _self.as<Chunk>().isChunk(vm);
    } else if (_self.is<Object>()) {
      return _self.as<Object>().isChunk(vm);
    } else if (_self.isTransient()) {
      waitFor(vm, _self);
      throw std::exception(); // not reachable
    } else {
      if (_self.is< ::mozart::ReflectiveEntity>()) {
        bool _result;
        if (_self.as< ::mozart::ReflectiveEntity>().reflectiveCall(vm, "$intf$::ChunkLike::isChunk", "isChunk", ::mozart::ozcalls::out(_result)))
          return _result;
      }
      return Interface<ChunkLike>().isChunk(_self, vm);
    }
  }
protected:
  RichNode _self;
};

