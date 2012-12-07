
/*
 * winMain.c --
 *
 *      Main entry point for wish and other Tk-based applications.
 *
 * Copyright (c) 1995 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 */


#include <windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <io.h>
#include <string.h>
#include <ctype.h>

#include <tcl.h>
#include <tk.h>

#ifndef cdecl
#define cdecl __cdecl
#endif

static void cdecl WishPanic(const char *x,...);
static void cdecl WishInfo(char *x,...);

extern "C" int close(int);

#define xxDEBUG

#ifdef DEBUG
#define DebugCode(Code) Code
#else
#define DebugCode(Code)
#endif

DebugCode(FILE *dbgout = NULL; FILE *dbgin = NULL;)


/*
 * Global variables used by the main program:
 */

static Tcl_Interp *interp;      /* Interpreter for this application. */


void sendToEngine(char *s)
{
  Tcl_Channel out = Tcl_GetStdChannel(TCL_STDOUT);
  int ret = Tcl_Write(out, s, -1);
  Tcl_Flush(out);
  if (ret < 0) {
    WishPanic("send failed");
  }
}

int
PutsCmd(ClientData clientData, Tcl_Interp *inter, int argc, char **argv)
{
  int i = 1;
  int newline = 1;
  if ((argc >= 2) && (strcmp(argv[1], "-nonewline") == 0)) {
    newline = 0;
    i++;
  }

  if ((i < (argc-3)) || (i >= argc)) {
    Tcl_AppendResult(interp, "wrong # args: should be \"", argv[0],
                     " ?-nonewline? ?fileId? string\"", (char *) NULL);
    return TCL_ERROR;
  }

  if (i != (argc-1))
    i++;

  sendToEngine(argv[i]);
  if (newline) {
    char newlineStr[] = "\n";
    sendToEngine(newlineStr);
  }

  DebugCode(fprintf(dbgout,"********puts(%d):\n%s\n",inter,argv[i]); fflush(dbgout));
  return TCL_OK;
}



/* THE TWO FOLLOWING FUNCTIONS HAVE BEEN COPIED FROM EMULATOR */


DWORD __stdcall watchEmulatorThread(void *arg)
{
  HANDLE handle = (HANDLE) arg;
  DWORD ret = WaitForSingleObject(handle,INFINITE);
  if (ret != WAIT_OBJECT_0) {
    WishPanic("WaitForSingleObject(0x%x) failed: %d (error=%d)",
              handle,ret,GetLastError());
    ExitThread(0);
  }
  ExitProcess(0);
  return 1;
}

/* there are no process groups under Win32
 * so Emulator hands its pid via envvar OZPPID to emulator
 * it then creates a thread watching whether the Emulator is still living
 * and terminates otherwise
 */
void watchParent()
{
  char buf[100];

  if (GetEnvironmentVariable("OZPPID",buf,sizeof(buf)) == 0) {
    WishPanic("getenv(OZPPID) failed");
  }

  int pid = atoi(buf);
  HANDLE handle = OpenProcess(SYNCHRONIZE, 0, pid);
  if (!handle) {
    char buf[1024];
    LPVOID lpMsgBuf;
    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                  FORMAT_MESSAGE_FROM_SYSTEM |
                  FORMAT_MESSAGE_IGNORE_INSERTS,
                  NULL,
                  GetLastError(),
                  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                  (LPTSTR) &lpMsgBuf,
                  0,
                  NULL);
    sprintf(buf, "OpenProcess(%d) failed: %s",pid,lpMsgBuf);
    LocalFree(lpMsgBuf);
    WishPanic(buf,pid);
  }

  DWORD thrid;
  CreateThread(NULL,10000,watchEmulatorThread,handle,0,&thrid);
}

// 2000.08.14 dragan: lock the readHandler so that it cannot be
// executed concurrently. The reason why it was executed concurrently
// is that 'Tcl_GlobalEval' blocks on certain requests, e.g. showing a
// message dialog.
volatile static int tkLock = 0;

void readHandler(ClientData clientData, int mask)
{
  // 2000.08.14 dragan: no race conditions here, since we *assume*
  // that the I/O manager calls a readHandler exactly once for each
  // channel. That is, it cannot happen that two 'readHandlers' are
  // started simultaneously.
  if (tkLock == 1)
    return;
  else
    tkLock = 1;
  static int bufSize  = 1000;
  static char *buffer = NULL;
  if (buffer == NULL) {
    buffer = (char*) malloc(bufSize+1);
  }

  static int used = 0;

  if (used>=bufSize) {
    bufSize *= 2;
    buffer = (char *) realloc(buffer,bufSize+1);
    if (buffer==0)
      WishPanic("realloc of buffer failed");
  }


  Tcl_Channel in = (Tcl_Channel) clientData;
  int count = Tcl_Read(in,buffer+used,bufSize-used);

  if (count<0) {
    WishPanic("Connection to engine lost: %d, %d, %d",
              count, in, Tcl_GetErrno());
  }


  if (count==0) {
    if (Tcl_Eof(in)) {
      WishPanic("Eof on input stream");
    } else {
      tkLock = 0;
      return;
    }
  }

  used += count;
  buffer[used] = 0;

  DebugCode(fprintf(dbgin,"\n### read done: %d\n%s\n",count,buffer); fflush(dbgin));

  if ((buffer[used-1] != '\n') && (buffer[used-1] != ';') ||
      !Tcl_CommandComplete(buffer) ||
      used >=2 && buffer[used-2] == '\\') {
    tkLock = 0;
    return;
  }


  int code = Tcl_GlobalEval(interp, buffer);
  if (code != TCL_OK) {
    char buf[1000];
    DebugCode(fprintf(dbgin,"### Error(%d):  %s\n", code,interp->result);
              fflush(dbgin));
    sprintf(buf,"w --- %s---  %s\n---\n.\n", buffer,interp->result);
    sendToEngine(buf);
  }

  used = 0;
  // dragan: no race conditions here either:
  tkLock = 0;
}


int APIENTRY
WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpszCmdLine, int nCmdShow)
{
    DebugCode(dbgin  = fopen("y:\\mozart-1.2.1\\wishdbgin","w");
              dbgout = fopen("y:\\mozart-1.2.1\\wishdbgout","w");
              if (dbgin == NULL || dbgout == NULL)
                WishPanic("cannot open dbgin/dbgout"));
    DebugCode(fprintf(dbgin,"### Started\n"); fflush(dbgin));

    watchParent();

    Tcl_FindExecutable("");
    interp = Tcl_CreateInterp();

    int argc;
    const char **argv;
    int code = Tcl_SplitList(interp, lpszCmdLine, &argc, &argv);
    if (code!=TCL_OK)
      WishPanic("Tcl_SplitList(%s) failed", lpszCmdLine);


    Tcl_SetPanicProc(WishPanic);

    Tcl_SetVar2(interp, "env", "DISPLAY", "localhost:0", TCL_GLOBAL_ONLY);
    Tcl_SetVar(interp, "tcl_interactive", "0", TCL_GLOBAL_ONLY);

    /*
     * Invoke application-specific initialization.
     */
    if (Tcl_Init(interp) == TCL_ERROR ||
        Tk_Init(interp) == TCL_ERROR) {
      WishPanic("Tcl_Init failed: %s\n", interp->result);
    }

    Tcl_ResetResult(interp);

    Tcl_CreateCommand(interp, "puts", (Tcl_CmdProc*) PutsCmd,  (ClientData) NULL,
                      (Tcl_CmdDeleteProc *) NULL);

    if (argc!=1)
      WishPanic("Usage: tk.exe port\n", argc);

    close(0);
    close(1);
    close(2);

    int port = atoi(argv[0]);
    Tcl_Channel inout = Tcl_OpenTcpClient(interp,port,"localhost",0,0,0);
    if (inout==0)
      WishPanic("Tcl_OpenTcpClient(%d,%s) failed",port,"localhost");
    Tcl_CreateChannelHandler(inout,TCL_READABLE ,readHandler,(ClientData)inout);
    Tcl_RegisterChannel(interp, inout);
    Tcl_SetChannelOption(interp, inout, "-blocking", "off");
    Tcl_SetChannelOption(interp, inout, "-translation", "binary");
    Tcl_SetStdChannel(inout,TCL_STDIN);
    Tcl_SetStdChannel(inout,TCL_STDOUT);
    Tcl_SetStdChannel(inout,TCL_STDERR);

    /* mm: do not show the main window */
    code = Tcl_GlobalEval(interp, "wm withdraw . ");
    if (code != TCL_OK) {
      char buf[1000];
      sprintf(buf,"w %s\n.\n", interp->result);
      sendToEngine(buf);
    }

    Tk_MainLoop();

    ExitProcess(0);
    return 0;
}




/*
 *----------------------------------------------------------------------
 *
 * WishPanic --
 *
 *      Display a message and exit.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Exits the program.
 *
 *----------------------------------------------------------------------
 */


void cdecl
WishPanic TCL_VARARGS_DEF(const char *,arg1)
{
  va_list argList;
  const char *format = TCL_VARARGS_START(const char *,arg1,argList);
  char buf[1024];
  vsprintf(buf, format, argList);

  MessageBeep(MB_ICONEXCLAMATION);
  MessageBox(NULL, buf, "Fatal Error in Wish",
             MB_ICONSTOP | MB_OK | MB_TASKMODAL | MB_SETFOREGROUND);
  ExitProcess(1);
}

void cdecl
WishInfo TCL_VARARGS_DEF(char *,arg1)
{
  va_list argList;
  char *format = TCL_VARARGS_START(char *,arg1,argList);
  char buf[1024];
  vsprintf(buf, format, argList);

  MessageBox(NULL, buf, "Fatal Error in Wish",
             MB_ICONSTOP | MB_OK | MB_TASKMODAL | MB_SETFOREGROUND);
}
