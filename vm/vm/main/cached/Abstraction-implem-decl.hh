class Abstraction;

template <>
class Storage<Abstraction> {
public:
  typedef ImplWithArray<Abstraction, class mozart::StableNode> Type;
};
