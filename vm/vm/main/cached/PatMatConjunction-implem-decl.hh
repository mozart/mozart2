class PatMatConjunction;

template <>
class Storage<PatMatConjunction> {
public:
  typedef ImplWithArray<PatMatConjunction, class mozart::StableNode> Type;
};
