class Abstraction;

template <>
class Storage<Abstraction> {
public:
  typedef ImplWithArray<Abstraction, mozart::StableNode> Type;
};
