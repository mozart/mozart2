class CodeArea;

template <>
class Storage<CodeArea> {
public:
  typedef ImplWithArray<CodeArea, mozart::StableNode> Type;
};
