#include "mozart.h"
#include <sys/types.h>
#ifdef __MINGW32__
extern "C" {
#include <winsock.h>
}
#else
#include <sys/socket.h>
#endif

OZ_BI_define(BI_smallbuf,2,0)
{
  OZ_declareInt(0,fd);
  OZ_declareInt(1,size);
  setsockopt(fd,SOL_SOCKET,SO_SNDBUF,(char*)&size,1);
  return PROCEED;
} OZ_BI_end

extern "C"
{
  OZ_C_proc_interface * oz_init_module(void)
  {
    static OZ_C_proc_interface i_table[] = {
      {"smallbuf",2,0,BI_smallbuf},
      {0,0,0,0}
    };
    return i_table;
  }
}
