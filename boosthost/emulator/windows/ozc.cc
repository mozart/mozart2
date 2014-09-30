// Copyright © 2013, Université catholique de Louvain
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

#ifndef MOZART_WINDOWS
#  error "This program is Windows-specific, it must not be compiled on other platforms."
#endif

#include <iostream>
#include <windows.h>

inline
size_t nposToMinus1(size_t pos) {
  return pos == std::string::npos ? -1 : pos;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   LPSTR lpszCmdLine, int nCmdShow) {
  // Compute ozengine.exe path from my own path
  char buffer[2048];
  GetModuleFileName(nullptr, buffer, sizeof(buffer));

  std::string myPath(buffer);
  size_t backslashPos = nposToMinus1(myPath.rfind('\\'));
  std::string ozenginePath =
    myPath.substr(0, backslashPos+1) + "ozengine.exe";

  // Construct the command line
  std::string cmdline = std::string("\"") + ozenginePath +
    "\" x-oz://system/Compile.ozf " + lpszCmdLine;

  // Execute ozengine
  STARTUPINFOA si;
  memset(&si, 0, sizeof(si));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESTDHANDLES;

  SetHandleInformation(GetStdHandle(STD_INPUT_HANDLE),
                       HANDLE_FLAG_INHERIT,HANDLE_FLAG_INHERIT);
  SetHandleInformation(GetStdHandle(STD_OUTPUT_HANDLE),
                       HANDLE_FLAG_INHERIT,HANDLE_FLAG_INHERIT);
  SetHandleInformation(GetStdHandle(STD_ERROR_HANDLE),
                       HANDLE_FLAG_INHERIT,HANDLE_FLAG_INHERIT);
  si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
  si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
  si.hStdError = GetStdHandle(STD_ERROR_HANDLE);

  PROCESS_INFORMATION pinf;
  if (!CreateProcessA(const_cast<char*>(ozenginePath.c_str()),
                      const_cast<char*>(cmdline.c_str()),
                      nullptr, nullptr, true, 0,
                      nullptr, nullptr, &si, &pinf)) {
    std::cerr << "panic: cannot start ozengine" << std::endl;
    return 254;
  }

  // Wait for completion
  WaitForSingleObject(pinf.hProcess, INFINITE);

  // Get the exit code
  DWORD exitCode;
  if (!GetExitCodeProcess(pinf.hProcess, &exitCode))
    exitCode = 255;

  // Close the handles
  CloseHandle(pinf.hProcess);
  CloseHandle(pinf.hThread);

  return exitCode;
}
