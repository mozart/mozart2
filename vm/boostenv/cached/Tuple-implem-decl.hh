class Tuple;

template <>
class Storage<Tuple> {
public:
  typedef ImplWithArray<Tuple, class mozart::StableNode> Type;
};
