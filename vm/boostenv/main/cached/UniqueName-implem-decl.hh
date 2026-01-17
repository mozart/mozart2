class UniqueName;

template <>
class Storage<UniqueName> {
public:
  typedef mozart::unique_name_t Type;
};
