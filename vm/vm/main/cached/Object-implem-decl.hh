class Object;

template <>
class Storage<Object> {
public:
  typedef ImplWithArray<Object, mozart::UnstableNode> Type;
};
