class Array;

template <>
class Storage<Array> {
public:
  typedef ImplWithArray<Array, class mozart::UnstableNode> Type;
};
