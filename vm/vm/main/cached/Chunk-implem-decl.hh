class Chunk;

template <>
class Storage<Chunk> {
public:
  typedef class mozart::StableNode * Type;
};
