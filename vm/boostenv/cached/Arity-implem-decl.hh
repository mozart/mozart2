class Arity;

template <>
class Storage<Arity> {
public:
  typedef ImplWithArray<Arity, class mozart::StableNode> Type;
};
