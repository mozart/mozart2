class Object;

template <>
class Storage<Object> {
public:
  typedef ImplWithArray<Object, class mozart::UnstableNode> Type;
};
