
namespace biref {
using namespace ::mozart;

class ModArray: public BuiltinModule {
public:
  ModArray(VM vm): BuiltinModule(vm, "Array") {
    instanceNew.setModuleName("Array");
    instanceIs.setModuleName("Array");
    instanceLow.setModuleName("Array");
    instanceHigh.setModuleName("Array");
    instanceGet.setModuleName("Array");
    instancePut.setModuleName("Array");
    instanceExchangeFun.setModuleName("Array");

    UnstableField fields[7];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    fields[2].feature = build(vm, "low");
    fields[2].value = build(vm, instanceLow);
    fields[3].feature = build(vm, "high");
    fields[3].value = build(vm, instanceHigh);
    fields[4].feature = build(vm, "get");
    fields[4].value = build(vm, instanceGet);
    fields[5].feature = build(vm, "put");
    fields[5].value = build(vm, instancePut);
    fields[6].feature = build(vm, "exchangeFun");
    fields[6].value = build(vm, instanceExchangeFun);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 7, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModArray::New instanceNew;
  mozart::builtins::ModArray::Is instanceIs;
  mozart::builtins::ModArray::Low instanceLow;
  mozart::builtins::ModArray::High instanceHigh;
  mozart::builtins::ModArray::Get instanceGet;
  mozart::builtins::ModArray::Put instancePut;
  mozart::builtins::ModArray::ExchangeFun instanceExchangeFun;
};
void registerBuiltinModArray(VM vm) {
  auto module = std::make_shared<ModArray>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModAtom: public BuiltinModule {
public:
  ModAtom(VM vm): BuiltinModule(vm, "Atom") {
    instanceIs.setModuleName("Atom");

    UnstableField fields[1];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 1, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModAtom::Is instanceIs;
};
void registerBuiltinModAtom(VM vm) {
  auto module = std::make_shared<ModAtom>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModVirtualString: public BuiltinModule {
public:
  ModVirtualString(VM vm): BuiltinModule(vm, "VirtualString") {
    instanceIs.setModuleName("VirtualString");
    instanceToCompactString.setModuleName("VirtualString");
    instanceToCharList.setModuleName("VirtualString");
    instanceToAtom.setModuleName("VirtualString");
    instanceLength.setModuleName("VirtualString");
    instanceToFloat.setModuleName("VirtualString");

    UnstableField fields[6];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    fields[1].feature = build(vm, "toCompactString");
    fields[1].value = build(vm, instanceToCompactString);
    fields[2].feature = build(vm, "toCharList");
    fields[2].value = build(vm, instanceToCharList);
    fields[3].feature = build(vm, "toAtom");
    fields[3].value = build(vm, instanceToAtom);
    fields[4].feature = build(vm, "length");
    fields[4].value = build(vm, instanceLength);
    fields[5].feature = build(vm, "toFloat");
    fields[5].value = build(vm, instanceToFloat);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 6, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModVirtualString::Is instanceIs;
  mozart::builtins::ModVirtualString::ToCompactString instanceToCompactString;
  mozart::builtins::ModVirtualString::ToCharList instanceToCharList;
  mozart::builtins::ModVirtualString::ToAtom instanceToAtom;
  mozart::builtins::ModVirtualString::Length instanceLength;
  mozart::builtins::ModVirtualString::ToFloat instanceToFloat;
};
void registerBuiltinModVirtualString(VM vm) {
  auto module = std::make_shared<ModVirtualString>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModBoot: public BuiltinModule {
public:
  ModBoot(VM vm): BuiltinModule(vm, "Boot") {
    instanceGetInternal.setModuleName("Boot");
    instanceGetNative.setModuleName("Boot");

    UnstableField fields[2];
    fields[0].feature = build(vm, "getInternal");
    fields[0].value = build(vm, instanceGetInternal);
    fields[1].feature = build(vm, "getNative");
    fields[1].value = build(vm, instanceGetNative);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 2, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModBoot::GetInternal instanceGetInternal;
  mozart::builtins::ModBoot::GetNative instanceGetNative;
};
void registerBuiltinModBoot(VM vm) {
  auto module = std::make_shared<ModBoot>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModBrowser: public BuiltinModule {
public:
  ModBrowser(VM vm): BuiltinModule(vm, "Browser") {
    instanceIsRecordCVar.setModuleName("Browser");
    instanceChunkWidth.setModuleName("Browser");
    instanceChunkArity.setModuleName("Browser");
    instanceShortName.setModuleName("Browser");
    instanceGetsBoundB.setModuleName("Browser");
    instanceVarSpace.setModuleName("Browser");
    instanceProcLoc.setModuleName("Browser");
    instanceAddr.setModuleName("Browser");

    UnstableField fields[8];
    fields[0].feature = build(vm, "isRecordCVar");
    fields[0].value = build(vm, instanceIsRecordCVar);
    fields[1].feature = build(vm, "chunkWidth");
    fields[1].value = build(vm, instanceChunkWidth);
    fields[2].feature = build(vm, "chunkArity");
    fields[2].value = build(vm, instanceChunkArity);
    fields[3].feature = build(vm, "shortName");
    fields[3].value = build(vm, instanceShortName);
    fields[4].feature = build(vm, "getsBoundB");
    fields[4].value = build(vm, instanceGetsBoundB);
    fields[5].feature = build(vm, "varSpace");
    fields[5].value = build(vm, instanceVarSpace);
    fields[6].feature = build(vm, "procLoc");
    fields[6].value = build(vm, instanceProcLoc);
    fields[7].feature = build(vm, "addr");
    fields[7].value = build(vm, instanceAddr);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 8, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModBrowser::IsRecordCVar instanceIsRecordCVar;
  mozart::builtins::ModBrowser::ChunkWidth instanceChunkWidth;
  mozart::builtins::ModBrowser::ChunkArity instanceChunkArity;
  mozart::builtins::ModBrowser::ShortName instanceShortName;
  mozart::builtins::ModBrowser::GetsBoundB instanceGetsBoundB;
  mozart::builtins::ModBrowser::VarSpace instanceVarSpace;
  mozart::builtins::ModBrowser::ProcLoc instanceProcLoc;
  mozart::builtins::ModBrowser::Addr instanceAddr;
};
void registerBuiltinModBrowser(VM vm) {
  auto module = std::make_shared<ModBrowser>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModCell: public BuiltinModule {
public:
  ModCell(VM vm): BuiltinModule(vm, "Cell") {
    instanceNew.setModuleName("Cell");
    instanceIs.setModuleName("Cell");
    instanceExchangeFun.setModuleName("Cell");
    instanceAccess.setModuleName("Cell");
    instanceAssign.setModuleName("Cell");

    UnstableField fields[5];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    fields[2].feature = build(vm, "exchangeFun");
    fields[2].value = build(vm, instanceExchangeFun);
    fields[3].feature = build(vm, "access");
    fields[3].value = build(vm, instanceAccess);
    fields[4].feature = build(vm, "assign");
    fields[4].value = build(vm, instanceAssign);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 5, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModCell::New instanceNew;
  mozart::builtins::ModCell::Is instanceIs;
  mozart::builtins::ModCell::ExchangeFun instanceExchangeFun;
  mozart::builtins::ModCell::Access instanceAccess;
  mozart::builtins::ModCell::Assign instanceAssign;
};
void registerBuiltinModCell(VM vm) {
  auto module = std::make_shared<ModCell>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModChunk: public BuiltinModule {
public:
  ModChunk(VM vm): BuiltinModule(vm, "Chunk") {
    instanceNew.setModuleName("Chunk");
    instanceIs.setModuleName("Chunk");

    UnstableField fields[2];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 2, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModChunk::New instanceNew;
  mozart::builtins::ModChunk::Is instanceIs;
};
void registerBuiltinModChunk(VM vm) {
  auto module = std::make_shared<ModChunk>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModCoders: public BuiltinModule {
public:
  ModCoders(VM vm): BuiltinModule(vm, "Coders") {
    instanceEncode.setModuleName("Coders");
    instanceDecode.setModuleName("Coders");

    UnstableField fields[2];
    fields[0].feature = build(vm, "encode");
    fields[0].value = build(vm, instanceEncode);
    fields[1].feature = build(vm, "decode");
    fields[1].value = build(vm, instanceDecode);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 2, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModCoders::Encode instanceEncode;
  mozart::builtins::ModCoders::Decode instanceDecode;
};
void registerBuiltinModCoders(VM vm) {
  auto module = std::make_shared<ModCoders>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModCompactString: public BuiltinModule {
public:
  ModCompactString(VM vm): BuiltinModule(vm, "CompactString") {
    instanceIsCompactString.setModuleName("CompactString");
    instanceIsCompactByteString.setModuleName("CompactString");
    instanceCharAt.setModuleName("CompactString");
    instanceAppend.setModuleName("CompactString");
    instanceSlice.setModuleName("CompactString");
    instanceSearch.setModuleName("CompactString");
    instanceHasPrefix.setModuleName("CompactString");
    instanceHasSuffix.setModuleName("CompactString");

    UnstableField fields[8];
    fields[0].feature = build(vm, "isCompactString");
    fields[0].value = build(vm, instanceIsCompactString);
    fields[1].feature = build(vm, "isCompactByteString");
    fields[1].value = build(vm, instanceIsCompactByteString);
    fields[2].feature = build(vm, "charAt");
    fields[2].value = build(vm, instanceCharAt);
    fields[3].feature = build(vm, "append");
    fields[3].value = build(vm, instanceAppend);
    fields[4].feature = build(vm, "slice");
    fields[4].value = build(vm, instanceSlice);
    fields[5].feature = build(vm, "search");
    fields[5].value = build(vm, instanceSearch);
    fields[6].feature = build(vm, "hasPrefix");
    fields[6].value = build(vm, instanceHasPrefix);
    fields[7].feature = build(vm, "hasSuffix");
    fields[7].value = build(vm, instanceHasSuffix);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 8, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModCompactString::IsCompactString instanceIsCompactString;
  mozart::builtins::ModCompactString::IsCompactByteString instanceIsCompactByteString;
  mozart::builtins::ModCompactString::CharAt instanceCharAt;
  mozart::builtins::ModCompactString::Append instanceAppend;
  mozart::builtins::ModCompactString::Slice instanceSlice;
  mozart::builtins::ModCompactString::Search instanceSearch;
  mozart::builtins::ModCompactString::HasPrefix instanceHasPrefix;
  mozart::builtins::ModCompactString::HasSuffix instanceHasSuffix;
};
void registerBuiltinModCompactString(VM vm) {
  auto module = std::make_shared<ModCompactString>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModCompilerSupport: public BuiltinModule {
public:
  ModCompilerSupport(VM vm): BuiltinModule(vm, "CompilerSupport") {
    instanceFeatureLess.setModuleName("CompilerSupport");
    instanceNewCodeArea.setModuleName("CompilerSupport");
    instanceNewAbstraction.setModuleName("CompilerSupport");
    instanceSetUUID.setModuleName("CompilerSupport");
    instanceIsArity.setModuleName("CompilerSupport");
    instanceMakeArityDynamic.setModuleName("CompilerSupport");
    instanceMakeRecordFromArity.setModuleName("CompilerSupport");
    instanceNewPatMatWildcard.setModuleName("CompilerSupport");
    instanceNewPatMatCapture.setModuleName("CompilerSupport");
    instanceNewPatMatConjunction.setModuleName("CompilerSupport");
    instanceNewPatMatOpenRecord.setModuleName("CompilerSupport");
    instanceIsBuiltin.setModuleName("CompilerSupport");
    instanceGetBuiltinInfo.setModuleName("CompilerSupport");
    instanceIsUniqueName.setModuleName("CompilerSupport");

    UnstableField fields[14];
    fields[0].feature = build(vm, "featureLess");
    fields[0].value = build(vm, instanceFeatureLess);
    fields[1].feature = build(vm, "newCodeArea");
    fields[1].value = build(vm, instanceNewCodeArea);
    fields[2].feature = build(vm, "newAbstraction");
    fields[2].value = build(vm, instanceNewAbstraction);
    fields[3].feature = build(vm, "setUUID");
    fields[3].value = build(vm, instanceSetUUID);
    fields[4].feature = build(vm, "isArity");
    fields[4].value = build(vm, instanceIsArity);
    fields[5].feature = build(vm, "makeArityDynamic");
    fields[5].value = build(vm, instanceMakeArityDynamic);
    fields[6].feature = build(vm, "makeRecordFromArity");
    fields[6].value = build(vm, instanceMakeRecordFromArity);
    fields[7].feature = build(vm, "newPatMatWildcard");
    fields[7].value = build(vm, instanceNewPatMatWildcard);
    fields[8].feature = build(vm, "newPatMatCapture");
    fields[8].value = build(vm, instanceNewPatMatCapture);
    fields[9].feature = build(vm, "newPatMatConjunction");
    fields[9].value = build(vm, instanceNewPatMatConjunction);
    fields[10].feature = build(vm, "newPatMatOpenRecord");
    fields[10].value = build(vm, instanceNewPatMatOpenRecord);
    fields[11].feature = build(vm, "isBuiltin");
    fields[11].value = build(vm, instanceIsBuiltin);
    fields[12].feature = build(vm, "getBuiltinInfo");
    fields[12].value = build(vm, instanceGetBuiltinInfo);
    fields[13].feature = build(vm, "isUniqueName");
    fields[13].value = build(vm, instanceIsUniqueName);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 14, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModCompilerSupport::FeatureLess instanceFeatureLess;
  mozart::builtins::ModCompilerSupport::NewCodeArea instanceNewCodeArea;
  mozart::builtins::ModCompilerSupport::NewAbstraction instanceNewAbstraction;
  mozart::builtins::ModCompilerSupport::SetUUID instanceSetUUID;
  mozart::builtins::ModCompilerSupport::IsArity instanceIsArity;
  mozart::builtins::ModCompilerSupport::MakeArityDynamic instanceMakeArityDynamic;
  mozart::builtins::ModCompilerSupport::MakeRecordFromArity instanceMakeRecordFromArity;
  mozart::builtins::ModCompilerSupport::NewPatMatWildcard instanceNewPatMatWildcard;
  mozart::builtins::ModCompilerSupport::NewPatMatCapture instanceNewPatMatCapture;
  mozart::builtins::ModCompilerSupport::NewPatMatConjunction instanceNewPatMatConjunction;
  mozart::builtins::ModCompilerSupport::NewPatMatOpenRecord instanceNewPatMatOpenRecord;
  mozart::builtins::ModCompilerSupport::IsBuiltin instanceIsBuiltin;
  mozart::builtins::ModCompilerSupport::GetBuiltinInfo instanceGetBuiltinInfo;
  mozart::builtins::ModCompilerSupport::IsUniqueName instanceIsUniqueName;
};
void registerBuiltinModCompilerSupport(VM vm) {
  auto module = std::make_shared<ModCompilerSupport>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModDebug: public BuiltinModule {
public:
  ModDebug(VM vm): BuiltinModule(vm, "Debug") {
    instanceGetRaiseOnBlock.setModuleName("Debug");
    instanceSetRaiseOnBlock.setModuleName("Debug");
    instanceSetId.setModuleName("Debug");
    instanceBreakpoint.setModuleName("Debug");

    UnstableField fields[4];
    fields[0].feature = build(vm, "getRaiseOnBlock");
    fields[0].value = build(vm, instanceGetRaiseOnBlock);
    fields[1].feature = build(vm, "setRaiseOnBlock");
    fields[1].value = build(vm, instanceSetRaiseOnBlock);
    fields[2].feature = build(vm, "setId");
    fields[2].value = build(vm, instanceSetId);
    fields[3].feature = build(vm, "breakpoint");
    fields[3].value = build(vm, instanceBreakpoint);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 4, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModDebug::GetRaiseOnBlock instanceGetRaiseOnBlock;
  mozart::builtins::ModDebug::SetRaiseOnBlock instanceSetRaiseOnBlock;
  mozart::builtins::ModDebug::SetId instanceSetId;
  mozart::builtins::ModDebug::Breakpoint instanceBreakpoint;
};
void registerBuiltinModDebug(VM vm) {
  auto module = std::make_shared<ModDebug>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModDictionary: public BuiltinModule {
public:
  ModDictionary(VM vm): BuiltinModule(vm, "Dictionary") {
    instanceNew.setModuleName("Dictionary");
    instanceIs.setModuleName("Dictionary");
    instanceIsEmpty.setModuleName("Dictionary");
    instanceMember.setModuleName("Dictionary");
    instanceGet.setModuleName("Dictionary");
    instanceCondGet.setModuleName("Dictionary");
    instancePut.setModuleName("Dictionary");
    instanceExchangeFun.setModuleName("Dictionary");
    instanceCondExchangeFun.setModuleName("Dictionary");
    instanceRemove.setModuleName("Dictionary");
    instanceRemoveAll.setModuleName("Dictionary");
    instanceKeys.setModuleName("Dictionary");
    instanceEntries.setModuleName("Dictionary");
    instanceItems.setModuleName("Dictionary");
    instanceClone.setModuleName("Dictionary");

    UnstableField fields[15];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    fields[2].feature = build(vm, "isEmpty");
    fields[2].value = build(vm, instanceIsEmpty);
    fields[3].feature = build(vm, "member");
    fields[3].value = build(vm, instanceMember);
    fields[4].feature = build(vm, "get");
    fields[4].value = build(vm, instanceGet);
    fields[5].feature = build(vm, "condGet");
    fields[5].value = build(vm, instanceCondGet);
    fields[6].feature = build(vm, "put");
    fields[6].value = build(vm, instancePut);
    fields[7].feature = build(vm, "exchangeFun");
    fields[7].value = build(vm, instanceExchangeFun);
    fields[8].feature = build(vm, "condExchangeFun");
    fields[8].value = build(vm, instanceCondExchangeFun);
    fields[9].feature = build(vm, "remove");
    fields[9].value = build(vm, instanceRemove);
    fields[10].feature = build(vm, "removeAll");
    fields[10].value = build(vm, instanceRemoveAll);
    fields[11].feature = build(vm, "keys");
    fields[11].value = build(vm, instanceKeys);
    fields[12].feature = build(vm, "entries");
    fields[12].value = build(vm, instanceEntries);
    fields[13].feature = build(vm, "items");
    fields[13].value = build(vm, instanceItems);
    fields[14].feature = build(vm, "clone");
    fields[14].value = build(vm, instanceClone);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 15, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModDictionary::New instanceNew;
  mozart::builtins::ModDictionary::Is instanceIs;
  mozart::builtins::ModDictionary::IsEmpty instanceIsEmpty;
  mozart::builtins::ModDictionary::Member instanceMember;
  mozart::builtins::ModDictionary::Get instanceGet;
  mozart::builtins::ModDictionary::CondGet instanceCondGet;
  mozart::builtins::ModDictionary::Put instancePut;
  mozart::builtins::ModDictionary::ExchangeFun instanceExchangeFun;
  mozart::builtins::ModDictionary::CondExchangeFun instanceCondExchangeFun;
  mozart::builtins::ModDictionary::Remove instanceRemove;
  mozart::builtins::ModDictionary::RemoveAll instanceRemoveAll;
  mozart::builtins::ModDictionary::Keys instanceKeys;
  mozart::builtins::ModDictionary::Entries instanceEntries;
  mozart::builtins::ModDictionary::Items instanceItems;
  mozart::builtins::ModDictionary::Clone instanceClone;
};
void registerBuiltinModDictionary(VM vm) {
  auto module = std::make_shared<ModDictionary>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModException: public BuiltinModule {
public:
  ModException(VM vm): BuiltinModule(vm, "Exception") {
    instanceRaise.setModuleName("Exception");
    instanceRaiseError.setModuleName("Exception");
    instanceFail.setModuleName("Exception");

    UnstableField fields[3];
    fields[0].feature = build(vm, "raise");
    fields[0].value = build(vm, instanceRaise);
    fields[1].feature = build(vm, "raiseError");
    fields[1].value = build(vm, instanceRaiseError);
    fields[2].feature = build(vm, "fail");
    fields[2].value = build(vm, instanceFail);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 3, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModException::Raise instanceRaise;
  mozart::builtins::ModException::RaiseError instanceRaiseError;
  mozart::builtins::ModException::Fail instanceFail;
};
void registerBuiltinModException(VM vm) {
  auto module = std::make_shared<ModException>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModInt: public BuiltinModule {
public:
  ModInt(VM vm): BuiltinModule(vm, "Int") {
    instanceIs.setModuleName("Int");
    instanceDiv.setModuleName("Int");
    instanceMod.setModuleName("Int");
    instancePlus1.setModuleName("Int");
    instanceMinus1.setModuleName("Int");

    UnstableField fields[5];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    fields[1].feature = build(vm, "div");
    fields[1].value = build(vm, instanceDiv);
    fields[2].feature = build(vm, "mod");
    fields[2].value = build(vm, instanceMod);
    fields[3].feature = build(vm, "+1");
    fields[3].value = build(vm, instancePlus1);
    fields[4].feature = build(vm, "-1");
    fields[4].value = build(vm, instanceMinus1);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 5, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModInt::Is instanceIs;
  mozart::builtins::ModInt::Div instanceDiv;
  mozart::builtins::ModInt::Mod instanceMod;
  mozart::builtins::ModInt::Plus1 instancePlus1;
  mozart::builtins::ModInt::Minus1 instanceMinus1;
};
void registerBuiltinModInt(VM vm) {
  auto module = std::make_shared<ModInt>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModFloat: public BuiltinModule {
public:
  ModFloat(VM vm): BuiltinModule(vm, "Float") {
    instanceIs.setModuleName("Float");
    instanceDivide.setModuleName("Float");
    instancePow.setModuleName("Float");
    instanceToInt.setModuleName("Float");
    instanceAcos.setModuleName("Float");
    instanceAcosh.setModuleName("Float");
    instanceAsin.setModuleName("Float");
    instanceAsinh.setModuleName("Float");
    instanceAtan.setModuleName("Float");
    instanceAtanh.setModuleName("Float");
    instanceAtan2.setModuleName("Float");
    instanceCeil.setModuleName("Float");
    instanceCos.setModuleName("Float");
    instanceCosh.setModuleName("Float");
    instanceExp.setModuleName("Float");
    instanceFloor.setModuleName("Float");
    instanceLog.setModuleName("Float");
    instanceFMod.setModuleName("Float");
    instanceRound.setModuleName("Float");
    instanceSin.setModuleName("Float");
    instanceSinh.setModuleName("Float");
    instanceSqrt.setModuleName("Float");
    instanceTan.setModuleName("Float");
    instanceTanh.setModuleName("Float");

    UnstableField fields[24];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    fields[1].feature = build(vm, "/");
    fields[1].value = build(vm, instanceDivide);
    fields[2].feature = build(vm, "pow");
    fields[2].value = build(vm, instancePow);
    fields[3].feature = build(vm, "toInt");
    fields[3].value = build(vm, instanceToInt);
    fields[4].feature = build(vm, "acos");
    fields[4].value = build(vm, instanceAcos);
    fields[5].feature = build(vm, "acosh");
    fields[5].value = build(vm, instanceAcosh);
    fields[6].feature = build(vm, "asin");
    fields[6].value = build(vm, instanceAsin);
    fields[7].feature = build(vm, "asinh");
    fields[7].value = build(vm, instanceAsinh);
    fields[8].feature = build(vm, "atan");
    fields[8].value = build(vm, instanceAtan);
    fields[9].feature = build(vm, "atanh");
    fields[9].value = build(vm, instanceAtanh);
    fields[10].feature = build(vm, "atan2");
    fields[10].value = build(vm, instanceAtan2);
    fields[11].feature = build(vm, "ceil");
    fields[11].value = build(vm, instanceCeil);
    fields[12].feature = build(vm, "cos");
    fields[12].value = build(vm, instanceCos);
    fields[13].feature = build(vm, "cosh");
    fields[13].value = build(vm, instanceCosh);
    fields[14].feature = build(vm, "exp");
    fields[14].value = build(vm, instanceExp);
    fields[15].feature = build(vm, "floor");
    fields[15].value = build(vm, instanceFloor);
    fields[16].feature = build(vm, "log");
    fields[16].value = build(vm, instanceLog);
    fields[17].feature = build(vm, "fMod");
    fields[17].value = build(vm, instanceFMod);
    fields[18].feature = build(vm, "round");
    fields[18].value = build(vm, instanceRound);
    fields[19].feature = build(vm, "sin");
    fields[19].value = build(vm, instanceSin);
    fields[20].feature = build(vm, "sinh");
    fields[20].value = build(vm, instanceSinh);
    fields[21].feature = build(vm, "sqrt");
    fields[21].value = build(vm, instanceSqrt);
    fields[22].feature = build(vm, "tan");
    fields[22].value = build(vm, instanceTan);
    fields[23].feature = build(vm, "tanh");
    fields[23].value = build(vm, instanceTanh);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 24, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModFloat::Is instanceIs;
  mozart::builtins::ModFloat::Divide instanceDivide;
  mozart::builtins::ModFloat::Pow instancePow;
  mozart::builtins::ModFloat::ToInt instanceToInt;
  mozart::builtins::ModFloat::Acos instanceAcos;
  mozart::builtins::ModFloat::Acosh instanceAcosh;
  mozart::builtins::ModFloat::Asin instanceAsin;
  mozart::builtins::ModFloat::Asinh instanceAsinh;
  mozart::builtins::ModFloat::Atan instanceAtan;
  mozart::builtins::ModFloat::Atanh instanceAtanh;
  mozart::builtins::ModFloat::Atan2 instanceAtan2;
  mozart::builtins::ModFloat::Ceil instanceCeil;
  mozart::builtins::ModFloat::Cos instanceCos;
  mozart::builtins::ModFloat::Cosh instanceCosh;
  mozart::builtins::ModFloat::Exp instanceExp;
  mozart::builtins::ModFloat::Floor instanceFloor;
  mozart::builtins::ModFloat::Log instanceLog;
  mozart::builtins::ModFloat::FMod instanceFMod;
  mozart::builtins::ModFloat::Round instanceRound;
  mozart::builtins::ModFloat::Sin instanceSin;
  mozart::builtins::ModFloat::Sinh instanceSinh;
  mozart::builtins::ModFloat::Sqrt instanceSqrt;
  mozart::builtins::ModFloat::Tan instanceTan;
  mozart::builtins::ModFloat::Tanh instanceTanh;
};
void registerBuiltinModFloat(VM vm) {
  auto module = std::make_shared<ModFloat>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModForeignPointer: public BuiltinModule {
public:
  ModForeignPointer(VM vm): BuiltinModule(vm, "ForeignPointer") {
    instanceIs.setModuleName("ForeignPointer");
    instanceToInt.setModuleName("ForeignPointer");

    UnstableField fields[2];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    fields[1].feature = build(vm, "toInt");
    fields[1].value = build(vm, instanceToInt);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 2, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModForeignPointer::Is instanceIs;
  mozart::builtins::ModForeignPointer::ToInt instanceToInt;
};
void registerBuiltinModForeignPointer(VM vm) {
  auto module = std::make_shared<ModForeignPointer>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModGNode: public BuiltinModule {
public:
  ModGNode(VM vm): BuiltinModule(vm, "GNode") {
    instanceGlobalize.setModuleName("GNode");
    instanceLoad.setModuleName("GNode");
    instanceGetValue.setModuleName("GNode");
    instanceGetProto.setModuleName("GNode");
    instanceGetUUID.setModuleName("GNode");

    UnstableField fields[5];
    fields[0].feature = build(vm, "globalize");
    fields[0].value = build(vm, instanceGlobalize);
    fields[1].feature = build(vm, "load");
    fields[1].value = build(vm, instanceLoad);
    fields[2].feature = build(vm, "getValue");
    fields[2].value = build(vm, instanceGetValue);
    fields[3].feature = build(vm, "getProto");
    fields[3].value = build(vm, instanceGetProto);
    fields[4].feature = build(vm, "getUUID");
    fields[4].value = build(vm, instanceGetUUID);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 5, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModGNode::Globalize instanceGlobalize;
  mozart::builtins::ModGNode::Load instanceLoad;
  mozart::builtins::ModGNode::GetValue instanceGetValue;
  mozart::builtins::ModGNode::GetProto instanceGetProto;
  mozart::builtins::ModGNode::GetUUID instanceGetUUID;
};
void registerBuiltinModGNode(VM vm) {
  auto module = std::make_shared<ModGNode>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModLiteral: public BuiltinModule {
public:
  ModLiteral(VM vm): BuiltinModule(vm, "Literal") {
    instanceIs.setModuleName("Literal");

    UnstableField fields[1];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 1, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModLiteral::Is instanceIs;
};
void registerBuiltinModLiteral(VM vm) {
  auto module = std::make_shared<ModLiteral>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModName: public BuiltinModule {
public:
  ModName(VM vm): BuiltinModule(vm, "Name") {
    instanceNew.setModuleName("Name");
    instanceNewWithUUID.setModuleName("Name");
    instanceNewUnique.setModuleName("Name");
    instanceNewNamed.setModuleName("Name");
    instanceNewNamedWithUUID.setModuleName("Name");
    instanceIs.setModuleName("Name");

    UnstableField fields[6];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "newWithUUID");
    fields[1].value = build(vm, instanceNewWithUUID);
    fields[2].feature = build(vm, "newUnique");
    fields[2].value = build(vm, instanceNewUnique);
    fields[3].feature = build(vm, "newNamed");
    fields[3].value = build(vm, instanceNewNamed);
    fields[4].feature = build(vm, "newNamedWithUUID");
    fields[4].value = build(vm, instanceNewNamedWithUUID);
    fields[5].feature = build(vm, "is");
    fields[5].value = build(vm, instanceIs);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 6, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModName::New instanceNew;
  mozart::builtins::ModName::NewWithUUID instanceNewWithUUID;
  mozart::builtins::ModName::NewUnique instanceNewUnique;
  mozart::builtins::ModName::NewNamed instanceNewNamed;
  mozart::builtins::ModName::NewNamedWithUUID instanceNewNamedWithUUID;
  mozart::builtins::ModName::Is instanceIs;
};
void registerBuiltinModName(VM vm) {
  auto module = std::make_shared<ModName>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModNumber: public BuiltinModule {
public:
  ModNumber(VM vm): BuiltinModule(vm, "Number") {
    instanceIs.setModuleName("Number");
    instanceOpposite.setModuleName("Number");
    instanceAdd.setModuleName("Number");
    instanceSubtract.setModuleName("Number");
    instanceMultiply.setModuleName("Number");
    instanceAbs.setModuleName("Number");

    UnstableField fields[6];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    fields[1].feature = build(vm, "~");
    fields[1].value = build(vm, instanceOpposite);
    fields[2].feature = build(vm, "+");
    fields[2].value = build(vm, instanceAdd);
    fields[3].feature = build(vm, "-");
    fields[3].value = build(vm, instanceSubtract);
    fields[4].feature = build(vm, "*");
    fields[4].value = build(vm, instanceMultiply);
    fields[5].feature = build(vm, "abs");
    fields[5].value = build(vm, instanceAbs);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 6, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModNumber::Is instanceIs;
  mozart::builtins::ModNumber::Opposite instanceOpposite;
  mozart::builtins::ModNumber::Add instanceAdd;
  mozart::builtins::ModNumber::Subtract instanceSubtract;
  mozart::builtins::ModNumber::Multiply instanceMultiply;
  mozart::builtins::ModNumber::Abs instanceAbs;
};
void registerBuiltinModNumber(VM vm) {
  auto module = std::make_shared<ModNumber>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModObject: public BuiltinModule {
public:
  ModObject(VM vm): BuiltinModule(vm, "Object") {
    instanceNew.setModuleName("Object");
    instanceIs.setModuleName("Object");
    instanceGetClass.setModuleName("Object");
    instanceAttrGet.setModuleName("Object");
    instanceAttrPut.setModuleName("Object");
    instanceAttrExchangeFun.setModuleName("Object");
    instanceCellOrAttrGet.setModuleName("Object");
    instanceCellOrAttrPut.setModuleName("Object");
    instanceCellOrAttrExchangeFun.setModuleName("Object");

    UnstableField fields[9];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    fields[2].feature = build(vm, "getClass");
    fields[2].value = build(vm, instanceGetClass);
    fields[3].feature = build(vm, "attrGet");
    fields[3].value = build(vm, instanceAttrGet);
    fields[4].feature = build(vm, "attrPut");
    fields[4].value = build(vm, instanceAttrPut);
    fields[5].feature = build(vm, "attrExchangeFun");
    fields[5].value = build(vm, instanceAttrExchangeFun);
    fields[6].feature = build(vm, "cellOrAttrGet");
    fields[6].value = build(vm, instanceCellOrAttrGet);
    fields[7].feature = build(vm, "cellOrAttrPut");
    fields[7].value = build(vm, instanceCellOrAttrPut);
    fields[8].feature = build(vm, "cellOrAttrExchangeFun");
    fields[8].value = build(vm, instanceCellOrAttrExchangeFun);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 9, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModObject::New instanceNew;
  mozart::builtins::ModObject::Is instanceIs;
  mozart::builtins::ModObject::GetClass instanceGetClass;
  mozart::builtins::ModObject::AttrGet instanceAttrGet;
  mozart::builtins::ModObject::AttrPut instanceAttrPut;
  mozart::builtins::ModObject::AttrExchangeFun instanceAttrExchangeFun;
  mozart::builtins::ModObject::CellOrAttrGet instanceCellOrAttrGet;
  mozart::builtins::ModObject::CellOrAttrPut instanceCellOrAttrPut;
  mozart::builtins::ModObject::CellOrAttrExchangeFun instanceCellOrAttrExchangeFun;
};
void registerBuiltinModObject(VM vm) {
  auto module = std::make_shared<ModObject>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModPickle: public BuiltinModule {
public:
  ModPickle(VM vm): BuiltinModule(vm, "Pickle") {
    instancePack.setModuleName("Pickle");
    instanceUnpack.setModuleName("Pickle");
    instanceSave.setModuleName("Pickle");
    instanceLoad.setModuleName("Pickle");

    UnstableField fields[4];
    fields[0].feature = build(vm, "pack");
    fields[0].value = build(vm, instancePack);
    fields[1].feature = build(vm, "unpack");
    fields[1].value = build(vm, instanceUnpack);
    fields[2].feature = build(vm, "save");
    fields[2].value = build(vm, instanceSave);
    fields[3].feature = build(vm, "load");
    fields[3].value = build(vm, instanceLoad);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 4, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModPickle::Pack instancePack;
  mozart::builtins::ModPickle::Unpack instanceUnpack;
  mozart::builtins::ModPickle::Save instanceSave;
  mozart::builtins::ModPickle::Load instanceLoad;
};
void registerBuiltinModPickle(VM vm) {
  auto module = std::make_shared<ModPickle>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModPort: public BuiltinModule {
public:
  ModPort(VM vm): BuiltinModule(vm, "Port") {
    instanceNew.setModuleName("Port");
    instanceIs.setModuleName("Port");
    instanceSend.setModuleName("Port");
    instanceSendReceive.setModuleName("Port");

    UnstableField fields[4];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    fields[2].feature = build(vm, "send");
    fields[2].value = build(vm, instanceSend);
    fields[3].feature = build(vm, "sendRecv");
    fields[3].value = build(vm, instanceSendReceive);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 4, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModPort::New instanceNew;
  mozart::builtins::ModPort::Is instanceIs;
  mozart::builtins::ModPort::Send instanceSend;
  mozart::builtins::ModPort::SendReceive instanceSendReceive;
};
void registerBuiltinModPort(VM vm) {
  auto module = std::make_shared<ModPort>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModProcedure: public BuiltinModule {
public:
  ModProcedure(VM vm): BuiltinModule(vm, "Procedure") {
    instanceIs.setModuleName("Procedure");
    instanceArity.setModuleName("Procedure");
    instanceApply.setModuleName("Procedure");

    UnstableField fields[3];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    fields[1].feature = build(vm, "arity");
    fields[1].value = build(vm, instanceArity);
    fields[2].feature = build(vm, "apply");
    fields[2].value = build(vm, instanceApply);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 3, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModProcedure::Is instanceIs;
  mozart::builtins::ModProcedure::Arity instanceArity;
  mozart::builtins::ModProcedure::Apply instanceApply;
};
void registerBuiltinModProcedure(VM vm) {
  auto module = std::make_shared<ModProcedure>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModProperty: public BuiltinModule {
public:
  ModProperty(VM vm): BuiltinModule(vm, "Property") {
    instanceRegisterValue.setModuleName("Property");
    instanceRegisterConstant.setModuleName("Property");
    instanceGet.setModuleName("Property");
    instancePut.setModuleName("Property");

    UnstableField fields[4];
    fields[0].feature = build(vm, "registerValue");
    fields[0].value = build(vm, instanceRegisterValue);
    fields[1].feature = build(vm, "registerConstant");
    fields[1].value = build(vm, instanceRegisterConstant);
    fields[2].feature = build(vm, "get");
    fields[2].value = build(vm, instanceGet);
    fields[3].feature = build(vm, "put");
    fields[3].value = build(vm, instancePut);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 4, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModProperty::RegisterValue instanceRegisterValue;
  mozart::builtins::ModProperty::RegisterConstant instanceRegisterConstant;
  mozart::builtins::ModProperty::Get instanceGet;
  mozart::builtins::ModProperty::Put instancePut;
};
void registerBuiltinModProperty(VM vm) {
  auto module = std::make_shared<ModProperty>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModRecord: public BuiltinModule {
public:
  ModRecord(VM vm): BuiltinModule(vm, "Record") {
    instanceIs.setModuleName("Record");
    instanceLabel.setModuleName("Record");
    instanceWidth.setModuleName("Record");
    instanceArity.setModuleName("Record");
    instanceClone.setModuleName("Record");
    instanceWaitOr.setModuleName("Record");
    instanceMakeDynamic.setModuleName("Record");
    instanceTest.setModuleName("Record");
    instanceTestLabel.setModuleName("Record");
    instanceTestFeature.setModuleName("Record");
    instanceAdjoinAtIfHasFeature.setModuleName("Record");

    UnstableField fields[11];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    fields[1].feature = build(vm, "label");
    fields[1].value = build(vm, instanceLabel);
    fields[2].feature = build(vm, "width");
    fields[2].value = build(vm, instanceWidth);
    fields[3].feature = build(vm, "arity");
    fields[3].value = build(vm, instanceArity);
    fields[4].feature = build(vm, "clone");
    fields[4].value = build(vm, instanceClone);
    fields[5].feature = build(vm, "waitOr");
    fields[5].value = build(vm, instanceWaitOr);
    fields[6].feature = build(vm, "makeDynamic");
    fields[6].value = build(vm, instanceMakeDynamic);
    fields[7].feature = build(vm, "test");
    fields[7].value = build(vm, instanceTest);
    fields[8].feature = build(vm, "testLabel");
    fields[8].value = build(vm, instanceTestLabel);
    fields[9].feature = build(vm, "testFeature");
    fields[9].value = build(vm, instanceTestFeature);
    fields[10].feature = build(vm, "adjoinAtIfHasFeature");
    fields[10].value = build(vm, instanceAdjoinAtIfHasFeature);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 11, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModRecord::Is instanceIs;
  mozart::builtins::ModRecord::Label instanceLabel;
  mozart::builtins::ModRecord::Width instanceWidth;
  mozart::builtins::ModRecord::Arity instanceArity;
  mozart::builtins::ModRecord::Clone instanceClone;
  mozart::builtins::ModRecord::WaitOr instanceWaitOr;
  mozart::builtins::ModRecord::MakeDynamic instanceMakeDynamic;
  mozart::builtins::ModRecord::Test instanceTest;
  mozart::builtins::ModRecord::TestLabel instanceTestLabel;
  mozart::builtins::ModRecord::TestFeature instanceTestFeature;
  mozart::builtins::ModRecord::AdjoinAtIfHasFeature instanceAdjoinAtIfHasFeature;
};
void registerBuiltinModRecord(VM vm) {
  auto module = std::make_shared<ModRecord>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModReflection: public BuiltinModule {
public:
  ModReflection(VM vm): BuiltinModule(vm, "Reflection") {
    instanceNewReflectiveEntity.setModuleName("Reflection");
    instanceNewReflectiveVariable.setModuleName("Reflection");
    instanceIsReflectiveVariable.setModuleName("Reflection");
    instanceBindReflectiveVariable.setModuleName("Reflection");
    instanceGetStructuralBehavior.setModuleName("Reflection");
    instanceBecome.setModuleName("Reflection");

    UnstableField fields[6];
    fields[0].feature = build(vm, "newReflectiveEntity");
    fields[0].value = build(vm, instanceNewReflectiveEntity);
    fields[1].feature = build(vm, "newReflectiveVariable");
    fields[1].value = build(vm, instanceNewReflectiveVariable);
    fields[2].feature = build(vm, "isReflectiveVariable");
    fields[2].value = build(vm, instanceIsReflectiveVariable);
    fields[3].feature = build(vm, "bindReflectiveVariable");
    fields[3].value = build(vm, instanceBindReflectiveVariable);
    fields[4].feature = build(vm, "getStructuralBehavior");
    fields[4].value = build(vm, instanceGetStructuralBehavior);
    fields[5].feature = build(vm, "become");
    fields[5].value = build(vm, instanceBecome);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 6, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModReflection::NewReflectiveEntity instanceNewReflectiveEntity;
  mozart::builtins::ModReflection::NewReflectiveVariable instanceNewReflectiveVariable;
  mozart::builtins::ModReflection::IsReflectiveVariable instanceIsReflectiveVariable;
  mozart::builtins::ModReflection::BindReflectiveVariable instanceBindReflectiveVariable;
  mozart::builtins::ModReflection::GetStructuralBehavior instanceGetStructuralBehavior;
  mozart::builtins::ModReflection::Become instanceBecome;
};
void registerBuiltinModReflection(VM vm) {
  auto module = std::make_shared<ModReflection>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModSerializer: public BuiltinModule {
public:
  ModSerializer(VM vm): BuiltinModule(vm, "Serializer") {
    instanceNew.setModuleName("Serializer");
    instanceSerialize.setModuleName("Serializer");
    instanceExtractByLabels.setModuleName("Serializer");

    UnstableField fields[3];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "serialize");
    fields[1].value = build(vm, instanceSerialize);
    fields[2].feature = build(vm, "extractByLabels");
    fields[2].value = build(vm, instanceExtractByLabels);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 3, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModSerializer::New instanceNew;
  mozart::builtins::ModSerializer::Serialize instanceSerialize;
  mozart::builtins::ModSerializer::ExtractByLabels instanceExtractByLabels;
};
void registerBuiltinModSerializer(VM vm) {
  auto module = std::make_shared<ModSerializer>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModSpace: public BuiltinModule {
public:
  ModSpace(VM vm): BuiltinModule(vm, "Space") {
    instanceNew.setModuleName("Space");
    instanceIs.setModuleName("Space");
    instanceAsk.setModuleName("Space");
    instanceAskVerbose.setModuleName("Space");
    instanceMerge.setModuleName("Space");
    instanceClone.setModuleName("Space");
    instanceCommit.setModuleName("Space");
    instanceKill.setModuleName("Space");
    instanceChoose.setModuleName("Space");

    UnstableField fields[9];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    fields[2].feature = build(vm, "ask");
    fields[2].value = build(vm, instanceAsk);
    fields[3].feature = build(vm, "askVerbose");
    fields[3].value = build(vm, instanceAskVerbose);
    fields[4].feature = build(vm, "merge");
    fields[4].value = build(vm, instanceMerge);
    fields[5].feature = build(vm, "clone");
    fields[5].value = build(vm, instanceClone);
    fields[6].feature = build(vm, "commit");
    fields[6].value = build(vm, instanceCommit);
    fields[7].feature = build(vm, "kill");
    fields[7].value = build(vm, instanceKill);
    fields[8].feature = build(vm, "choose");
    fields[8].value = build(vm, instanceChoose);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 9, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModSpace::New instanceNew;
  mozart::builtins::ModSpace::Is instanceIs;
  mozart::builtins::ModSpace::Ask instanceAsk;
  mozart::builtins::ModSpace::AskVerbose instanceAskVerbose;
  mozart::builtins::ModSpace::Merge instanceMerge;
  mozart::builtins::ModSpace::Clone instanceClone;
  mozart::builtins::ModSpace::Commit instanceCommit;
  mozart::builtins::ModSpace::Kill instanceKill;
  mozart::builtins::ModSpace::Choose instanceChoose;
};
void registerBuiltinModSpace(VM vm) {
  auto module = std::make_shared<ModSpace>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModSystem: public BuiltinModule {
public:
  ModSystem(VM vm): BuiltinModule(vm, "System") {
    instancePrintRepr.setModuleName("System");
    instanceGetRepr.setModuleName("System");
    instancePrintName.setModuleName("System");
    instancePrintVS.setModuleName("System");
    instanceGCDo.setModuleName("System");
    instanceEq.setModuleName("System");
    instanceOnTopLevel.setModuleName("System");
    instanceExit.setModuleName("System");

    UnstableField fields[8];
    fields[0].feature = build(vm, "printRepr");
    fields[0].value = build(vm, instancePrintRepr);
    fields[1].feature = build(vm, "getRepr");
    fields[1].value = build(vm, instanceGetRepr);
    fields[2].feature = build(vm, "printName");
    fields[2].value = build(vm, instancePrintName);
    fields[3].feature = build(vm, "printVS");
    fields[3].value = build(vm, instancePrintVS);
    fields[4].feature = build(vm, "gcDo");
    fields[4].value = build(vm, instanceGCDo);
    fields[5].feature = build(vm, "eq");
    fields[5].value = build(vm, instanceEq);
    fields[6].feature = build(vm, "onToplevel");
    fields[6].value = build(vm, instanceOnTopLevel);
    fields[7].feature = build(vm, "exit");
    fields[7].value = build(vm, instanceExit);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 8, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModSystem::PrintRepr instancePrintRepr;
  mozart::builtins::ModSystem::GetRepr instanceGetRepr;
  mozart::builtins::ModSystem::PrintName instancePrintName;
  mozart::builtins::ModSystem::PrintVS instancePrintVS;
  mozart::builtins::ModSystem::GCDo instanceGCDo;
  mozart::builtins::ModSystem::Eq instanceEq;
  mozart::builtins::ModSystem::OnTopLevel instanceOnTopLevel;
  mozart::builtins::ModSystem::Exit instanceExit;
};
void registerBuiltinModSystem(VM vm) {
  auto module = std::make_shared<ModSystem>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModThread: public BuiltinModule {
public:
  ModThread(VM vm): BuiltinModule(vm, "Thread") {
    instanceCreate.setModuleName("Thread");
    instanceIs.setModuleName("Thread");
    instanceThis.setModuleName("Thread");
    instanceGetPriority.setModuleName("Thread");
    instanceSetPriority.setModuleName("Thread");
    instanceInjectException.setModuleName("Thread");
    instanceState.setModuleName("Thread");
    instanceSuspend.setModuleName("Thread");
    instanceResume.setModuleName("Thread");
    instanceIsSuspended.setModuleName("Thread");
    instancePreempt.setModuleName("Thread");

    UnstableField fields[11];
    fields[0].feature = build(vm, "create");
    fields[0].value = build(vm, instanceCreate);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    fields[2].feature = build(vm, "this");
    fields[2].value = build(vm, instanceThis);
    fields[3].feature = build(vm, "getPriority");
    fields[3].value = build(vm, instanceGetPriority);
    fields[4].feature = build(vm, "setPriority");
    fields[4].value = build(vm, instanceSetPriority);
    fields[5].feature = build(vm, "injectException");
    fields[5].value = build(vm, instanceInjectException);
    fields[6].feature = build(vm, "state");
    fields[6].value = build(vm, instanceState);
    fields[7].feature = build(vm, "suspend");
    fields[7].value = build(vm, instanceSuspend);
    fields[8].feature = build(vm, "resume");
    fields[8].value = build(vm, instanceResume);
    fields[9].feature = build(vm, "isSuspended");
    fields[9].value = build(vm, instanceIsSuspended);
    fields[10].feature = build(vm, "preempt");
    fields[10].value = build(vm, instancePreempt);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 11, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModThread::Create instanceCreate;
  mozart::builtins::ModThread::Is instanceIs;
  mozart::builtins::ModThread::This instanceThis;
  mozart::builtins::ModThread::GetPriority instanceGetPriority;
  mozart::builtins::ModThread::SetPriority instanceSetPriority;
  mozart::builtins::ModThread::InjectException instanceInjectException;
  mozart::builtins::ModThread::State instanceState;
  mozart::builtins::ModThread::Suspend instanceSuspend;
  mozart::builtins::ModThread::Resume instanceResume;
  mozart::builtins::ModThread::IsSuspended instanceIsSuspended;
  mozart::builtins::ModThread::Preempt instancePreempt;
};
void registerBuiltinModThread(VM vm) {
  auto module = std::make_shared<ModThread>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModTime: public BuiltinModule {
public:
  ModTime(VM vm): BuiltinModule(vm, "Time") {
    instanceAlarm.setModuleName("Time");
    instanceGetReferenceTime.setModuleName("Time");
    instanceGetMonotonicTime.setModuleName("Time");

    UnstableField fields[3];
    fields[0].feature = build(vm, "alarm");
    fields[0].value = build(vm, instanceAlarm);
    fields[1].feature = build(vm, "getReferenceTime");
    fields[1].value = build(vm, instanceGetReferenceTime);
    fields[2].feature = build(vm, "getMonotonicTime");
    fields[2].value = build(vm, instanceGetMonotonicTime);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 3, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModTime::Alarm instanceAlarm;
  mozart::builtins::ModTime::GetReferenceTime instanceGetReferenceTime;
  mozart::builtins::ModTime::GetMonotonicTime instanceGetMonotonicTime;
};
void registerBuiltinModTime(VM vm) {
  auto module = std::make_shared<ModTime>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModTuple: public BuiltinModule {
public:
  ModTuple(VM vm): BuiltinModule(vm, "Tuple") {
    instanceMake.setModuleName("Tuple");
    instanceIs.setModuleName("Tuple");

    UnstableField fields[2];
    fields[0].feature = build(vm, "make");
    fields[0].value = build(vm, instanceMake);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 2, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModTuple::Make instanceMake;
  mozart::builtins::ModTuple::Is instanceIs;
};
void registerBuiltinModTuple(VM vm) {
  auto module = std::make_shared<ModTuple>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModValue: public BuiltinModule {
public:
  ModValue(VM vm): BuiltinModule(vm, "Value") {
    instanceDot.setModuleName("Value");
    instanceDotAssign.setModuleName("Value");
    instanceDotExchange.setModuleName("Value");
    instanceCatAccess.setModuleName("Value");
    instanceCatAssign.setModuleName("Value");
    instanceCatExchange.setModuleName("Value");
    instanceCatAccessOO.setModuleName("Value");
    instanceCatAssignOO.setModuleName("Value");
    instanceCatExchangeOO.setModuleName("Value");
    instanceEqEq.setModuleName("Value");
    instanceNotEqEq.setModuleName("Value");
    instanceWait.setModuleName("Value");
    instanceWaitQuiet.setModuleName("Value");
    instanceWaitNeeded.setModuleName("Value");
    instanceMakeNeeded.setModuleName("Value");
    instanceIsFree.setModuleName("Value");
    instanceIsKinded.setModuleName("Value");
    instanceIsFuture.setModuleName("Value");
    instanceIsFailed.setModuleName("Value");
    instanceIsDet.setModuleName("Value");
    instanceStatus.setModuleName("Value");
    instanceTypeOf.setModuleName("Value");
    instanceIsNeeded.setModuleName("Value");
    instanceLowerEqual.setModuleName("Value");
    instanceLowerThan.setModuleName("Value");
    instanceGreaterEqual.setModuleName("Value");
    instanceGreaterThan.setModuleName("Value");
    instanceHasFeature.setModuleName("Value");
    instanceCondSelect.setModuleName("Value");
    instanceMakeFailed.setModuleName("Value");
    instanceMakeReadOnly.setModuleName("Value");
    instanceNewReadOnly.setModuleName("Value");
    instanceBindReadOnly.setModuleName("Value");

    UnstableField fields[33];
    fields[0].feature = build(vm, ".");
    fields[0].value = build(vm, instanceDot);
    fields[1].feature = build(vm, "dotAssign");
    fields[1].value = build(vm, instanceDotAssign);
    fields[2].feature = build(vm, "dotExchange");
    fields[2].value = build(vm, instanceDotExchange);
    fields[3].feature = build(vm, "catAccess");
    fields[3].value = build(vm, instanceCatAccess);
    fields[4].feature = build(vm, "catAssign");
    fields[4].value = build(vm, instanceCatAssign);
    fields[5].feature = build(vm, "catExchange");
    fields[5].value = build(vm, instanceCatExchange);
    fields[6].feature = build(vm, "catAccessOO");
    fields[6].value = build(vm, instanceCatAccessOO);
    fields[7].feature = build(vm, "catAssignOO");
    fields[7].value = build(vm, instanceCatAssignOO);
    fields[8].feature = build(vm, "catExchangeOO");
    fields[8].value = build(vm, instanceCatExchangeOO);
    fields[9].feature = build(vm, "==");
    fields[9].value = build(vm, instanceEqEq);
    fields[10].feature = build(vm, "\\=");
    fields[10].value = build(vm, instanceNotEqEq);
    fields[11].feature = build(vm, "wait");
    fields[11].value = build(vm, instanceWait);
    fields[12].feature = build(vm, "waitQuiet");
    fields[12].value = build(vm, instanceWaitQuiet);
    fields[13].feature = build(vm, "waitNeeded");
    fields[13].value = build(vm, instanceWaitNeeded);
    fields[14].feature = build(vm, "makeNeeded");
    fields[14].value = build(vm, instanceMakeNeeded);
    fields[15].feature = build(vm, "isFree");
    fields[15].value = build(vm, instanceIsFree);
    fields[16].feature = build(vm, "isKinded");
    fields[16].value = build(vm, instanceIsKinded);
    fields[17].feature = build(vm, "isFuture");
    fields[17].value = build(vm, instanceIsFuture);
    fields[18].feature = build(vm, "isFailed");
    fields[18].value = build(vm, instanceIsFailed);
    fields[19].feature = build(vm, "isDet");
    fields[19].value = build(vm, instanceIsDet);
    fields[20].feature = build(vm, "status");
    fields[20].value = build(vm, instanceStatus);
    fields[21].feature = build(vm, "type");
    fields[21].value = build(vm, instanceTypeOf);
    fields[22].feature = build(vm, "isNeeded");
    fields[22].value = build(vm, instanceIsNeeded);
    fields[23].feature = build(vm, "=<");
    fields[23].value = build(vm, instanceLowerEqual);
    fields[24].feature = build(vm, "<");
    fields[24].value = build(vm, instanceLowerThan);
    fields[25].feature = build(vm, ">=");
    fields[25].value = build(vm, instanceGreaterEqual);
    fields[26].feature = build(vm, ">");
    fields[26].value = build(vm, instanceGreaterThan);
    fields[27].feature = build(vm, "hasFeature");
    fields[27].value = build(vm, instanceHasFeature);
    fields[28].feature = build(vm, "condSelect");
    fields[28].value = build(vm, instanceCondSelect);
    fields[29].feature = build(vm, "failedValue");
    fields[29].value = build(vm, instanceMakeFailed);
    fields[30].feature = build(vm, "readOnly");
    fields[30].value = build(vm, instanceMakeReadOnly);
    fields[31].feature = build(vm, "newReadOnly");
    fields[31].value = build(vm, instanceNewReadOnly);
    fields[32].feature = build(vm, "bindReadOnly");
    fields[32].value = build(vm, instanceBindReadOnly);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 33, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModValue::Dot instanceDot;
  mozart::builtins::ModValue::DotAssign instanceDotAssign;
  mozart::builtins::ModValue::DotExchange instanceDotExchange;
  mozart::builtins::ModValue::CatAccess instanceCatAccess;
  mozart::builtins::ModValue::CatAssign instanceCatAssign;
  mozart::builtins::ModValue::CatExchange instanceCatExchange;
  mozart::builtins::ModValue::CatAccessOO instanceCatAccessOO;
  mozart::builtins::ModValue::CatAssignOO instanceCatAssignOO;
  mozart::builtins::ModValue::CatExchangeOO instanceCatExchangeOO;
  mozart::builtins::ModValue::EqEq instanceEqEq;
  mozart::builtins::ModValue::NotEqEq instanceNotEqEq;
  mozart::builtins::ModValue::Wait instanceWait;
  mozart::builtins::ModValue::WaitQuiet instanceWaitQuiet;
  mozart::builtins::ModValue::WaitNeeded instanceWaitNeeded;
  mozart::builtins::ModValue::MakeNeeded instanceMakeNeeded;
  mozart::builtins::ModValue::IsFree instanceIsFree;
  mozart::builtins::ModValue::IsKinded instanceIsKinded;
  mozart::builtins::ModValue::IsFuture instanceIsFuture;
  mozart::builtins::ModValue::IsFailed instanceIsFailed;
  mozart::builtins::ModValue::IsDet instanceIsDet;
  mozart::builtins::ModValue::Status instanceStatus;
  mozart::builtins::ModValue::TypeOf instanceTypeOf;
  mozart::builtins::ModValue::IsNeeded instanceIsNeeded;
  mozart::builtins::ModValue::LowerEqual instanceLowerEqual;
  mozart::builtins::ModValue::LowerThan instanceLowerThan;
  mozart::builtins::ModValue::GreaterEqual instanceGreaterEqual;
  mozart::builtins::ModValue::GreaterThan instanceGreaterThan;
  mozart::builtins::ModValue::HasFeature instanceHasFeature;
  mozart::builtins::ModValue::CondSelect instanceCondSelect;
  mozart::builtins::ModValue::MakeFailed instanceMakeFailed;
  mozart::builtins::ModValue::MakeReadOnly instanceMakeReadOnly;
  mozart::builtins::ModValue::NewReadOnly instanceNewReadOnly;
  mozart::builtins::ModValue::BindReadOnly instanceBindReadOnly;
};
void registerBuiltinModValue(VM vm) {
  auto module = std::make_shared<ModValue>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModVirtualByteString: public BuiltinModule {
public:
  ModVirtualByteString(VM vm): BuiltinModule(vm, "VirtualByteString") {
    instanceIs.setModuleName("VirtualByteString");
    instanceToCompactByteString.setModuleName("VirtualByteString");
    instanceToByteList.setModuleName("VirtualByteString");
    instanceLength.setModuleName("VirtualByteString");

    UnstableField fields[4];
    fields[0].feature = build(vm, "is");
    fields[0].value = build(vm, instanceIs);
    fields[1].feature = build(vm, "toCompactByteString");
    fields[1].value = build(vm, instanceToCompactByteString);
    fields[2].feature = build(vm, "toByteList");
    fields[2].value = build(vm, instanceToByteList);
    fields[3].feature = build(vm, "length");
    fields[3].value = build(vm, instanceLength);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 4, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModVirtualByteString::Is instanceIs;
  mozart::builtins::ModVirtualByteString::ToCompactByteString instanceToCompactByteString;
  mozart::builtins::ModVirtualByteString::ToByteList instanceToByteList;
  mozart::builtins::ModVirtualByteString::Length instanceLength;
};
void registerBuiltinModVirtualByteString(VM vm) {
  auto module = std::make_shared<ModVirtualByteString>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModWeakReference: public BuiltinModule {
public:
  ModWeakReference(VM vm): BuiltinModule(vm, "WeakReference") {
    instanceNew.setModuleName("WeakReference");
    instanceIs.setModuleName("WeakReference");
    instanceGet.setModuleName("WeakReference");

    UnstableField fields[3];
    fields[0].feature = build(vm, "new");
    fields[0].value = build(vm, instanceNew);
    fields[1].feature = build(vm, "is");
    fields[1].value = build(vm, instanceIs);
    fields[2].feature = build(vm, "get");
    fields[2].value = build(vm, instanceGet);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 3, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::builtins::ModWeakReference::New instanceNew;
  mozart::builtins::ModWeakReference::Is instanceIs;
  mozart::builtins::ModWeakReference::Get instanceGet;
};
void registerBuiltinModWeakReference(VM vm) {
  auto module = std::make_shared<ModWeakReference>(vm);
  vm->registerBuiltinModule(module);
}

}
