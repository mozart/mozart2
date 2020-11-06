class Chunk;

template <>
class Storage<Chunk> {
public:
  typedef mozart::StableNode * Type;
};
