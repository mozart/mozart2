include(CTest)
# Testing files
set(TEST_FUNCTORS
    "${CMAKE_CURRENT_SOURCE_DIR}/gc.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/thread.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/byneed.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/conversion.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/dictionary.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/except.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/exception.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/finalize.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/float.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/future.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/guards.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/instruction.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/misc.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/ofs.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/pickles.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/type.oz"
    "${CMAKE_CURRENT_SOURCE_DIR}/unix.oz")
set(TEST_FUNCTORS_OZF "")
foreach(FUNCTOR ${TEST_FUNCTORS})
    get_filename_component(FUNCTOR_BASENAME ${FUNCTOR} NAME_WE)
    set(FUNCTOR_OZF "${CMAKE_CURRENT_BINARY_DIR}/${FUNCTOR_BASENAME}.ozf")
    set(TEST_FUNCTORS_OZF ${TEST_FUNCTORS_OZF} "${FUNCTOR_OZF}")
    add_custom_command(
        OUTPUT "${FUNCTOR_OZF}"
        COMMAND ozemulator
            --home "${MOZART_BUILD_DIR}"
            x-oz://system/Compile.ozf
            -c "${FUNCTOR}"
            -o "${FUNCTOR_OZF}"
        DEPENDS library "${FUNCTOR}"
        COMMENT "(compiling) ${FUNCTOR_OZF}"
        VERBATIM)
endforeach()
add_custom_target(
    compiler_tests ALL
    DEPENDS ${TEST_FUNCTORS_OZF})
# Run the tests when "make test" is executed
if(BUILD_TESTING)
    set(TEST_FUNCTORS_OZF "")
    # running vmtest (gtest)
    add_test("vmtest" "${CMAKE_CURRENT_BINARY_DIR}/../vm/vm/test/vmtest")
    foreach(FUNCTOR ${TEST_FUNCTORS})
        get_filename_component(FUNCTOR_BASENAME ${FUNCTOR} NAME_WE)
        set(FUNCTOR_OZF "${CMAKE_CURRENT_BINARY_DIR}/${FUNCTOR_BASENAME}.ozf")
        set(TEST_FUNCTORS_OZF ${TEST_FUNCTORS_OZF} "${FUNCTOR_OZF}")
        add_test(${FUNCTOR_BASENAME} ozengine ${FUNCTOR_OZF})
    endforeach()
endif(BUILD_TESTING)
