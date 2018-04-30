class Record;

template <>
class Storage<Record> {
public:
  typedef ImplWithArray<Record, class mozart::StableNode> Type;
};
