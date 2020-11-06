class PatMatConjunction;

template <>
class Storage<PatMatConjunction> {
public:
  typedef ImplWithArray<PatMatConjunction, mozart::StableNode> Type;
};
