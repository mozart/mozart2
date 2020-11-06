class PatMatOpenRecord;

template <>
class Storage<PatMatOpenRecord> {
public:
  typedef ImplWithArray<PatMatOpenRecord, mozart::StableNode> Type;
};
