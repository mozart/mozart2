# Configure paths
set(MOZART_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../..")
set(MOZART_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/../..")

# Configure compiler
set(CMAKE_CXX_FLAGS "-Wall -std=c++0x ${CMAKE_CXX_FLAGS}")

if(WIN32)
  # Boost requires this
  add_definitions(-D_WIN32_WINNT=0x0501)
endif()

# Boost library

set(MOZART_BOOST_USE_STATIC_LIBS ON
    CACHE BOOL "Use the static libraries of Boost")

if(${MOZART_BOOST_USE_STATIC_LIBS})
  set(Boost_USE_STATIC_LIBS ON)
endif()

find_package(Boost COMPONENTS
  program_options random system thread filesystem chrono REQUIRED)

link_directories(${Boost_LIBRARY_DIRS})
include_directories(${Boost_INCLUDE_DIRS})

if(MINGW)
  # Work around a bug in MinGW
  string(REGEX REPLACE "(^| )-std=c\\+\\+0x($| )" " -std=gnu++0x "
         CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif()

# Mozart VM library

include_directories("${MOZART_DIR}/vm/vm/main" "${MOZART_BUILD_DIR}/vm/vm/main")

# Mozart VM Boost environment library

include_directories("${MOZART_DIR}/vm/boostenv/main"
    "${MOZART_BUILD_DIR}/vm/boostenv/main")


# Compile the executable
if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  include_directories(/usr/lib/c++/v1)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif()

add_executable(ozemulator emulator.cc)
target_link_libraries(ozemulator mozartvmboost mozartvm ${Boost_LIBRARIES})

# Here it starts to differ wildly on Windows
if(NOT WIN32)
  target_link_libraries(ozemulator pthread)

  # Install
  install(TARGETS ozemulator DESTINATION bin)
  install(PROGRAMS ozengine ozc DESTINATION bin)
else() # WIN32
  # ozemulator is ozengine.exe on Windows
  set_target_properties(ozemulator PROPERTIES OUTPUT_NAME "ozengine")

  # ozc
  add_executable(ozc "windows/ozc.cc")

  # Install
  install(TARGETS ozemulator ozc DESTINATION bin)
endif()
