include(CTest)
# Testing files
set(BASE_FUNCTORS
    "conversion.oz" "float.oz"
    # "int.oz" "record.oz"
    "type.oz" "exception.oz" "guards.oz" "byneed.oz" "future.oz" "misc.oz"
    "instruction.oz" "compiler.oz" "except.oz" "dictionary.oz" "ofs.oz"
    "pickles.oz" "thread.oz" "unix.oz"
    # "weakdictionary.oz" "weakdictionaryGC.oz"
    "finalize.oz" "gc.oz"
    # "state.oz"
)
# base folder
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/base")
foreach(FUNCTOR ${BASE_FUNCTORS})
  set(BASE_FUNCTORS_OZ ${BASE_FUNCTORS_OZ} "/base/${FUNCTOR}")
endforeach()
# bench folder
set(BENCH_FUNCTORS
    "bridge.oz" "compiler.oz" "diff.oz" "fd.oz" "knights.oz" "nrev.oz"
    "port.oz" "rec.oz" "tak.oz")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bench")
foreach(FUNCTOR ${BENCH_FUNCTORS})
  set(BENCH_FUNCTORS_OZ ${BENCH_FUNCTORS_OZ} "/bench/${FUNCTOR}")
endforeach()
# dp folder
set(DP_FUNCTORS
    #"basicfault.oz"
    "caching.oz" "cellAndLock.oz" "cell.oz" "credit_circle.oz"
    #"credit.oz"
    "equality.oz" "fault_state.oz" "huge.oz" "init_settings.oz"
    "maxi.oz" "mini.oz" "objectAndLock.oz" "object.oz" "object_proc_port.oz"
    "parallel-search.oz" "port.oz" "table.oz"
    #"template.oz"
    "TestMisc.oz" "url.oz" "variable2.oz" "variable.oz")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/dp")
foreach(FUNCTOR ${DP_FUNCTORS})
  set(DP_FUNCTORS_OZ ${DP_FUNCTORS_OZ} "/dp/${FUNCTOR}")
endforeach()
# dp-bench folder
set(DP_BENCH_FUNCTORS
    "Client.oz" "copy.oz" "Manager.oz" "run.oz" "speed.oz")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/dp-bench")
foreach(FUNCTOR ${DP_BENCH_FUNCTORS})
  set(DP_BENCH_FUNCTORS_OZ ${DP_BENCH_FUNCTORS_OZ} "/dp-bench/${FUNCTOR}")
endforeach()
# fd folder
set(FD_FUNCTORS
    "alpha.oz" "binpacking.oz" "boundsdistinct.oz" "bridge.oz" "bridge_noterm.oz"
    "buildhouse.oz" "cars.oz" "change.oz" "coins.oz" "college.oz"
    "color.oz" "conference.oz" "configuration.oz"
    # "constrdisj.oz" "diagnosis.oz"
    "distribute.oz" "divmod.oz" "donald.oz" "dsum.oz" "equations.oz"
    "family.oz" "filter.oz" "fraction.oz" "grocery.oz" "guards.oz" "houses.oz"
    "hubert.oz" "kalotan.oz" "knights.oz" "magicsequence.oz" "magicsquare.oz"
    "mapcoloring.oz" "misc1.oz" "misc2.oz" "money.oz" "multiply.oz"
    "pel.oz" "permutation.oz" "photo.oz" "pigeon.oz" "pythagoras.oz"
    "queens.oz" "safe.oz" "schur.oz" "srat.oz" "students.oz" "sumabs.oz"
    "tiling.oz" "train.oz" "warehouse.oz" "watlasm.oz" "zebra.oz")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/fd")
foreach(FUNCTOR ${FD_FUNCTORS})
  set(FD_FUNCTORS_OZ ${FD_FUNCTORS_OZ} "/fd/${FUNCTOR}")
endforeach()
# fs folder
set(FS_FUNCTORS
    "crew.oz" "denys.oz" "golf.oz" "golf-reified.oz" "hamming.oz" "knapsack.oz"
    #"manuel_constr.oz"
    "manuel.oz" "misc.oz" "steiner.oz")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/fs")
foreach(FUNCTOR ${FS_FUNCTORS})
  set(FS_FUNCTORS_OZ ${FS_FUNCTORS_OZ} "/fs/${FUNCTOR}")
endforeach()
# interactive folder
set(INTERACTIVE_FUNCTORS
    #"error-messages.oz" "explorer.oz" "errors.oz"
)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/interactive")
foreach(FUNCTOR ${INTERACTIVE_FUNCTORS})
  set(INTERACTIVE_FUNCTORS_OZ ${INTERACTIVE_FUNCTORS_OZ} "/interactive/${FUNCTOR}")
endforeach()
# lib folder
set(LIB_FUNCTORS
    # "compute-tests.oz" "engine.oz"
    "failed.oz" "help-bench.oz"
    "help-string.oz"
    # "make-bench.oz"
    "passed.oz")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib")
foreach(FUNCTOR ${LIB_FUNCTORS})
  set(LIB_FUNCTORS_OZ ${LIB_FUNCTORS_OZ} "/lib/${FUNCTOR}")
endforeach()
# scheduling folder
set(SCHEDULING_FUNCTORS
    "abz6.oz"
    #"compilers.oz" "enum.oz" "greedy.oz" "local.oz" "localUtils.oz" "order.oz"
    "product.oz"
    #"resourceConstraints.oz" "resourceEnumeration.oz" "search.oz" "shuffle.oz" "swaps.oz"
)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/scheduling")
foreach(FUNCTOR ${SCHEDULING_FUNCTORS})
  set(SCHEDULING_FUNCTORS_OZ ${SCHEDULING_FUNCTORS_OZ} "/scheduling/${FUNCTOR}")
endforeach()
# space folder
set(SPACE_FUNCTORS
    "basic.oz" "lp.oz" "queens.oz" "sit-check.oz")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/space")
foreach(FUNCTOR ${SPACE_FUNCTORS})
  set(SPACE_FUNCTORS_OZ ${SPACE_FUNCTORS_OZ} "/space/${FUNCTOR}")
endforeach()
# unify folder
set(UNIFY_FUNCTORS
    #"cast.oz"
)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/unify")
foreach(FUNCTOR ${UNIFY_FUNCTORS})
  set(UNIFY_FUNCTORS_OZ ${UNIFY_FUNCTORS_OZ} "/unify/${FUNCTOR}")
endforeach()
set(TEST_FUNCTORS ${BASE_FUNCTORS_OZ} ${BENCH_FUNCTORS_OZ}
    ${DP_FUNCTORS_OZ} ${DP_BENCH_FUNCTORS_OZ}
    ${FD_FUNCTORS_OZ} ${FS_FUNCTORS_OZ} ${INTERACTIVE_FUNCTORS_OZ}
    ${SCHEDULING_FUNCTORS_OZ} ${SPACE_FUNCTORS_OZ}
    ${UNIFY_FUNCTORS_OZ})
set(TEST_FUNCTORS_OZF "")
set(TEST_FUNCTORS_WITH_LIB ${TEST_FUNCTORS} ${LIB_FUNCTORS_OZ})
foreach(FUNCTOR ${TEST_FUNCTORS_WITH_LIB})
    set(FUNCTOR_OZ "${CMAKE_CURRENT_SOURCE_DIR}${FUNCTOR}")
    set(FUNCTOR_OZF "${CMAKE_CURRENT_BINARY_DIR}${FUNCTOR}f")
    set(TEST_FUNCTORS_OZF ${TEST_FUNCTORS_OZF} "${FUNCTOR_OZF}")
    add_custom_command(
        OUTPUT "${FUNCTOR_OZF}"
        COMMAND ozemulator
            --home "${MOZART_BUILD_DIR}"
            x-oz://system/Compile.ozf
            -c "${FUNCTOR_OZ}"
            -o "${FUNCTOR_OZF}"
        DEPENDS library "${FUNCTOR_OZ}"
        COMMENT "(compiling platform-test) ${FUNCTOR_OZF}"
        VERBATIM)
endforeach()
add_custom_target(
    platform-tests ALL
    DEPENDS ${TEST_FUNCTORS_OZF})
# Run the tests when "make test" is executed
if(BUILD_TESTING)
    set(OZEMULATOR "${CMAKE_CURRENT_BINARY_DIR}/../boosthost/emulator/ozemulator")
    # running vmtest (gtest)
    add_test("vmtest" "${CMAKE_CURRENT_BINARY_DIR}/../vm/vm/test/vmtest")
    foreach(FUNCTOR ${TEST_FUNCTORS})
        set(FUNCTOR_OZF "${CMAKE_CURRENT_BINARY_DIR}${FUNCTOR}f")
        set(TEST_FUNCTORS_OZF ${TEST_FUNCTORS_OZF} "${FUNCTOR_OZF}")
        add_test(${FUNCTOR} ${OZEMULATOR} --home "${MOZART_BUILD_DIR}" "${TEST_DRIVER_OZF} ${FUNCTOR_OZF}")
    endforeach()
endif(BUILD_TESTING)
