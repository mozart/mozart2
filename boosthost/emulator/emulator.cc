// Copyright © 2012, Université catholique de Louvain
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// *  Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// *  Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <mozart.hh>
#include <boostenv.hh>

#include <iostream>
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <boost/program_options.hpp>

#ifdef MOZART_WINDOWS
#  include <windows.h>
#endif

// Path literal, using the system native encoding
#ifdef MOZART_WINDOWS
#  define PATH_LIT(s) boost::filesystem::path(L##s)
#else
#  define PATH_LIT(s) boost::filesystem::path(s)
#endif

namespace {

using namespace mozart;
namespace fs = boost::filesystem;
namespace po = boost::program_options;

/** Extra style parser that captures as positional argument any element
 *  starting from the first positional argument.
 *
 *  The structure was copied from po::detail::cmdline::parse_terminator.
 */
std::vector<po::option> all_positional_style_parser(
  std::vector<std::string>& args) {

  std::vector<po::option> result;
  const std::string& tok = args[0];
  if (!tok.empty() && (tok[0] != '-')) {
    for (unsigned i = 0; i < args.size(); ++i) {
      po::option opt;
      opt.value.push_back(args[i]);
      opt.original_tokens.push_back(args[i]);
      opt.position_key = INT_MAX;
      result.push_back(opt);
    }
    args.clear();
  }
  return result;
}

std::string envVarToOptionName(const std::string& varName) {
  if (varName == "OZ_HOME")
    return "home";
  else
    return "";
}

std::string envVarToOptionNameFallback(const std::string& varName) {
  if (varName == "OZHOME")
    return "home";
  else
    return "";
}

atom_t pathToAtom(VM vm, const fs::path& path) {
  return vm->getAtom(path.string());
}

#ifdef MOZART_WINDOWS

/* win32 does not support process groups,
 * so we set OZPPID such that a subprocess can check whether
 * its father still lives
 */

DWORD __stdcall watchParentThread(void* arg) {
  HANDLE handle = (HANDLE) arg;
  if (WaitForSingleObject(handle, INFINITE) == WAIT_FAILED) {
    std::cerr << "panic: wait for parent process failed" << std::endl;
    std::exit(1);
  }
  ExitProcess(0);
  return 0;
}

inline
void watchParentIfAny() {
  char buf[100];
  if (GetEnvironmentVariable("OZPPID", buf, sizeof(buf)) == 0)
    return;

  //--** this should really store an inherited handle instead of a pid
  int pid = atoi(buf);
  HANDLE handle = OpenProcess(SYNCHRONIZE, 0, pid);
  if (!handle) {
    std::cerr << "panic: could not access open parent process "
              << pid << std::endl;
    std::exit(1);
  }

  DWORD thrid;
  HANDLE hThread = CreateThread(0, 0, watchParentThread, handle, 0, &thrid);
  CloseHandle(hThread);
}

inline
void publishPid() {
  char auxbuf[100];
  int ppid = GetCurrentProcessId();
  sprintf(auxbuf, "%d", ppid);
  SetEnvironmentVariable("OZPPID", strdup(auxbuf));
}

void simulateProcessGroupIfNecessary() {
  /* First watch the parent, THEN publish my PID.
   * Otherwise publishPid would override the env var read by watchParentIfAny()
   */
  watchParentIfAny();
  publishPid();
}

#else // !MOZART_WINDOWS

inline
void simulateProcessGroupIfNecessary() {
}

#endif

} // anonymous namespace

// TODO Fetch Unicode command line on Windows!!!
int main(int argc, char** argv) {
  simulateProcessGroupIfNecessary();

  // CONFIGURATION VARIABLES

  std::string ozHomeStr, initFunctorPathStr, baseFunctorPathStr;
  fs::path ozHome, initFunctorPath, baseFunctorPath;
  std::string ozSearchPath, ozSearchLoad, appURL;
  std::vector<std::string> appArgs;
  size_t maxMemoryMega = 768;
  bool appGUI;

  // DEFINE OPTIONS

  po::options_description generic("Generic options");
  generic.add_options()
    ("help", "produce help message");

  po::options_description config("Configuration");
  config.add_options()
    ("home", po::value<std::string>(&ozHomeStr),
      "path to the home of the installation")
    ("init", po::value<std::string>(&initFunctorPathStr),
      "path to the Init.ozf functor")
    ("search-path", po::value<std::string>(&ozSearchPath),
      "search path")
    ("search-load", po::value<std::string>(&ozSearchLoad),
      "search load")
    ("max-memory", po::value<size_t>(&maxMemoryMega),
      "maximum memory, i.e. heap size (in MB)")
    ("gui", "GUI mode");

  po::options_description hidden("Hidden options");
  hidden.add_options()
    ("base", po::value<std::string>(&baseFunctorPathStr),
      "path to the Base.ozf functor")
    ("app-url", po::value<std::string>(&appURL),
      "application URL")
    ("app-args", po::value<std::vector<std::string>>(&appArgs),
      "application arguments");

  po::options_description cmdline_options;
  cmdline_options.add(generic).add(config).add(hidden);

  po::options_description environment_options;
  environment_options.add(config);

  po::options_description visible_options("Allowed options");
  visible_options.add(generic).add(config);

  po::positional_options_description positional_options;
  positional_options.add("app-url", 1);
  positional_options.add("app-args", -1);

  // PARSE OPTIONS

  po::variables_map varMap;

  auto parsed_from_cmdline =
    po::command_line_parser(argc, argv)
      .options(cmdline_options)
      .positional(positional_options)
      .extra_style_parser(&all_positional_style_parser)
      .run();

  po::store(parsed_from_cmdline, varMap);
  po::store(po::parse_environment(environment_options,
                                  &envVarToOptionName), varMap);
  po::store(po::parse_environment(environment_options,
                                  &envVarToOptionNameFallback), varMap);
  po::notify(varMap);

  ozHome = ozHomeStr;
  initFunctorPath = initFunctorPathStr;
  baseFunctorPath = baseFunctorPathStr;

  // READ OPTIONS

  if (varMap.count("help") != 0) {
    std::cout << visible_options << "\n";
    return 0;
  }

  fs::path executablePath;
#ifdef MOZART_WINDOWS
  {
    char buffer[2048];
    GetModuleFileName(nullptr, buffer, sizeof(buffer));
    executablePath = buffer;
  }
#else
  executablePath = argv[0];
#endif

  // Hacky way to guess if we are in a build setting
  fs::path appPath = executablePath.parent_path();
  bool isBuildSetting = appPath.filename() == PATH_LIT("emulator");

  if (ozHome.empty()) {
    if (isBuildSetting)
      ozHome = appPath.parent_path().parent_path();
    else
      ozHome = appPath.parent_path();

    if (ozHome.empty())
      ozHome = PATH_LIT(".");
  }

  if (initFunctorPath.empty()) {
    if (isBuildSetting) {
      initFunctorPath =
        ozHome / PATH_LIT("lib") / PATH_LIT("Init.ozf");
    } else {
      initFunctorPath =
        ozHome / PATH_LIT("share") / PATH_LIT("mozart") / PATH_LIT("Init.ozf");
    }
  }

  bool useBaseFunctor = varMap.count("base") != 0;

  appGUI = varMap.count("gui") != 0;

  // SET UP THE VM AND RUN
  boostenv::BoostBasedVM boostBasedVM([=] (VM vm) {
    boostenv::BoostVM& boostVM = boostenv::BoostVM::forVM(vm);
    // Set some properties
    {
      auto& properties = vm->getPropertyRegistry();

      atom_t ozHomeAtom = pathToAtom(vm, ozHome);
      properties.registerValueProp(
        vm, "oz.home", ozHomeAtom);
      properties.registerValueProp(
        vm, "oz.emulator.home", ozHomeAtom);
      properties.registerValueProp(
        vm, "oz.configure.home", ozHomeAtom);

      if (varMap.count("search-path") != 0)
        properties.registerValueProp(
          vm, "oz.search.path", vm->getAtom(ozSearchPath));
      if (varMap.count("search-load") != 0)
        properties.registerValueProp(
          vm, "oz.search.load", vm->getAtom(ozSearchLoad));

      auto decodedURL = toUTF<char>(makeLString(appURL.c_str()));
      auto appURLAtom = vm->getAtom(decodedURL.length, decodedURL.string);
      properties.registerValueProp(
        vm, "application.url", appURLAtom);

      OzListBuilder argsBuilder(vm);
      for (auto& arg: appArgs) {
        auto decodedArg = toUTF<char>(makeLString(arg.c_str()));
        argsBuilder.push_back(vm, vm->getAtom(decodedArg.length, decodedArg.string));
      }
      properties.registerValueProp(
        vm, "application.args", argsBuilder.get(vm));

      properties.registerValueProp(
        vm, "application.gui", appGUI);
    }

    boostenv::BoostBasedVM& boostBasedVM = boostenv::BoostBasedVM::forVM(vm);

    // Some protected nodes
    ProtectedNode baseEnv, initFunctor;

    // Load the Base environment if required
    if (useBaseFunctor) {
      baseEnv = vm->protect(OptVar::build(vm));

      UnstableNode baseValue;
      auto& bootLoader = boostBasedVM.getBootLoader();

      if (!bootLoader(vm, baseFunctorPath.string(), baseValue)) {
        std::cerr << "panic: could not load Base functor at "
                  << baseFunctorPath << std::endl;
        return 1;
      }

      // Create the thread that loads the Base environment
      if (Callable(baseValue).isProcedure(vm)) {
        ozcalls::asyncOzCall(vm, baseValue, *baseEnv);
      } else {
        // Assume it is a functor that does not import anything
        UnstableNode applyAtom = build(vm, "apply");
        UnstableNode applyProc = Dottable(baseValue).dot(vm, applyAtom);
        UnstableNode importParam = build(vm, "import");
        ozcalls::asyncOzCall(vm, applyProc, importParam, *baseEnv);
      }

      boostVM.run();
    }

    // Load the Init functor
    {
      initFunctor = vm->protect(OptVar::build(vm));

      UnstableNode initValue;
      auto& bootLoader = boostBasedVM.getBootLoader();

      if (!bootLoader(vm, initFunctorPath.string(), initValue)) {
        std::cerr << "panic: could not load Init functor at "
                  << initFunctorPath << std::endl;
        return 1;
      }

      // Create the thread that loads the Init functor
      if (Callable(initValue).isProcedure(vm)) {
        if (!useBaseFunctor) {
          std::cerr << "panic: Init.ozf is a procedure, "
                    << "but I have no Base to give to it" << std::endl;
          return 1;
        }

        ozcalls::asyncOzCall(vm, initValue, *baseEnv, *initFunctor);
        boostVM.run();
      } else {
        // Assume it is already the Init functor
        DataflowVariable(*initFunctor).bind(vm, initValue);
      }
    }

    // Apply the Init functor
    {
      auto ApplyAtom = build(vm, "apply");
      auto ApplyProc = Dottable(*initFunctor).dot(vm, ApplyAtom);

      auto BootModule = vm->findBuiltinModule("Boot");
      auto ImportRecord = buildRecord(
        vm, buildArity(vm, "import", "Boot"),
        BootModule);

      ozcalls::asyncOzCall(vm, ApplyProc, ImportRecord, OptVar::build(vm));

      baseEnv.reset();
      initFunctor.reset();

      boostVM.run();
    }

    return 0;
  });

  boostBasedVM.addVM(maxMemoryMega * MegaBytes);
  boostBasedVM.runIO();
}
