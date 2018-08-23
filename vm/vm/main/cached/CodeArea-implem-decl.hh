class CodeArea;

template <>
class Storage<CodeArea> {
public:
  typedef ImplWithArray<CodeArea, class mozart::StableNode> Type;
};
