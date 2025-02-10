class Array;

template <>
class Storage<Array> {
public:
  typedef ImplWithArray<Array, mozart::UnstableNode> Type;
};
