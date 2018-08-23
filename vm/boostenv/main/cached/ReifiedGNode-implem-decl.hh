class ReifiedGNode;

template <>
class Storage<ReifiedGNode> {
public:
  typedef class mozart::GlobalNode * Type;
};
