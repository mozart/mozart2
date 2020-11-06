class ReifiedGNode;

template <>
class Storage<ReifiedGNode> {
public:
  typedef mozart::GlobalNode * Type;
};
