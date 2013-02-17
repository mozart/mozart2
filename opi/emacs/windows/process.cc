/*
 *  Authors:
 *    Ralf Scheidhauer <scheidhr@dfki.de>
 *    Leif Kornstaedt <kornstae@ps.uni-sb.de>
 * 
 *  Copyright:
 *    Ralf Scheidhauer, 1999
 *    Leif Kornstaedt, 1999-2001
 * 
 *  Last change:
 *    $Date$ by $Author$
 *    $Revision$
 * 
 *  This file is part of Mozart, an implementation of Oz 3:
 *    http://www.mozart-oz.org
 * 
 *  See the file "LICENSE" or
 *    http://www.mozart-oz.org/LICENSE.html
 *  for information on usage and redistribution
 *  of this file, and for a DISCLAIMER OF ALL
 *  WARRANTIES.
 */

#include <windows.h>
#include <string.h>

#include "startup.hh"

static DWORD WINAPI readerThread(void *arg)
{
  HANDLE hRead = (HANDLE) arg;
  DWORD ret;
  char buffer[1024];
  while (TRUE) {
    if (!ReadFile(hRead,buffer,sizeof(buffer)-1,&ret,0))
      break;
    buffer[ret] = '\0';
    MessageBox(NULL,buffer,"Mozart Output",
               MB_ICONINFORMATION | MB_SETFOREGROUND);
  }
  CloseHandle(hRead);
  return 0;
}

int createProcess(char *cmdline)
{
  // Create a handle as the child's standard input in that only receives EOF.
  HANDLE hChildStdIn;
  {
    HANDLE hDummyWrite;
    SECURITY_ATTRIBUTES sa;
    ZeroMemory(&sa,sizeof(sa));
    sa.nLength = sizeof(sa);
    sa.lpSecurityDescriptor = NULL;
    sa.bInheritHandle = TRUE;
    if (!CreatePipe(&hChildStdIn,&hDummyWrite,&sa,0)) {
      panic(true,"Could not create pipe (stdin).\n");
    }
    CloseHandle(hDummyWrite);
  }

  // Create the handle for the child's standard output.
  // We will read from this and forward output into message boxes.
  HANDLE hRead,hChildStdOut;
  {
    HANDLE hReadTmp;
    SECURITY_ATTRIBUTES sa;
    ZeroMemory(&sa,sizeof(sa));
    sa.nLength = sizeof(sa);
    sa.lpSecurityDescriptor = NULL;
    sa.bInheritHandle = TRUE;
    if (!CreatePipe(&hReadTmp,&hChildStdOut,&sa,0)) {
      panic(true,"Could not create pipe (stdout).\n");
    }

    // The child must only inherit one side of the pipe.
    if (!DuplicateHandle(GetCurrentProcess(),hReadTmp,
                         GetCurrentProcess(),&hRead,0,
                         FALSE,DUPLICATE_SAME_ACCESS)) {
      panic(true,"Could not duplicate handle (stdout).\n");
    }
    CloseHandle(hReadTmp);
  }

  // Create the handle for the child's standard error.
  // This is the same as the standard output.
  // We need to duplicate the handle in case the child closes
  // either its standard output or its standard error.
  HANDLE hChildStdErr;
  if (!DuplicateHandle(GetCurrentProcess(),hChildStdOut,
                       GetCurrentProcess(),&hChildStdErr,0,
                       TRUE,DUPLICATE_SAME_ACCESS)) {
    panic(true,"Could not duplicate handle (stderr).");
  }

  // Create a thread to read the child's standard output/error.
  HANDLE hReaderThread;
  {
    DWORD thrid;
    hReaderThread = CreateThread(0,10000,&readerThread,hRead,0,&thrid);
    if (!hReaderThread) {
      panic(true,"Could not create thread.");
    }
  }

  // Create the process and wait for it to terminate.
  STARTUPINFO si;
  ZeroMemory(&si,sizeof(si));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdInput  = hChildStdIn;
  si.hStdOutput = hChildStdOut;
  si.hStdError  = hChildStdErr;

  PROCESS_INFORMATION pi;
  if (!CreateProcess(NULL,cmdline,NULL,NULL,TRUE,DETACHED_PROCESS,
                     NULL,NULL,&si,&pi)) {
    panic(true,"Cannot run '%s'.\n",cmdline);
  }
  CloseHandle(hChildStdIn);
  CloseHandle(hChildStdOut);
  CloseHandle(hChildStdErr);
  CloseHandle(pi.hThread);
  if (WaitForSingleObject(pi.hProcess,INFINITE) == WAIT_FAILED) {
    panic(true,"Wait for subprocess failed.\n");
  }

  // Wait for the reader thread to have displayed all output.
  if (WaitForSingleObject(hReaderThread,INFINITE) == WAIT_FAILED) {
    panic(true,"Wait for reader thread failed.\n");
  }
  CloseHandle(hReaderThread);

  DWORD code;
  if (!GetExitCodeProcess(pi.hProcess,&code)) {
    panic(true,"Could not get process exit code.");
  }
  CloseHandle(pi.hProcess);
  return code;
}
