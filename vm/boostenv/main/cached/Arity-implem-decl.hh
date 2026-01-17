class Arity;

template <>
class Storage<Arity> {
public:
  typedef ImplWithArray<Arity, mozart::StableNode> Type;
};
