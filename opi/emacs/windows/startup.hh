/*
 *  Author:
 *    Leif Kornstaedt <kornstae@ps.uni-sb.de>
 * 
 *  Copyright:
 *    Leif Kornstaedt, 1999
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

extern bool console;

// panic.cc
void panic(bool isSystem, char *format, ...);

// getenv.cc
char *ozGetenv(const char *var);

// path.cc
void normalizePath(char *path, bool toUnix);

// initenv.cc
extern const char *ozplatform;
char *getOzHome(bool toUnix);
void initEnv(void);

// makecmd.cc
char *getCmdLine(void);
char *makeCmdLine(bool isWrapper);

// publishPid.cc
void publishPid(void);

// process.cc
int createProcess(char *cmdline);

// registry.cc
char *getRegistry(char *subKey, char *valueName);
char *getRegistry(char *valueName);
