class PatMatOpenRecord;

template <>
class Storage<PatMatOpenRecord> {
public:
  typedef ImplWithArray<PatMatOpenRecord, class mozart::StableNode> Type;
};
