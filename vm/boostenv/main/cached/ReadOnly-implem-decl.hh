class ReadOnly;

template <>
class Storage<ReadOnly> {
public:
  typedef class mozart::StableNode * Type;
};
