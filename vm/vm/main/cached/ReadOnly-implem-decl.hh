class ReadOnly;

template <>
class Storage<ReadOnly> {
public:
  typedef mozart::StableNode * Type;
};
