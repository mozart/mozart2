#include "var_base.hh"
#include "susplist.hh"
#include "tagged.hh"

OZ_BI_define(BIsusplistLength,1,1)
{
  OZ_declareTerm(0,v);
  v = OZ_deref(v);
  int n = 0;
  if (OZ_isVariable(v)) {
    for (SuspList * s = tagged2Var(v)->getSuspList();
         s!=NULL;
         s=s->getNext())
      { n += 1; }
  }
  OZ_RETURN_INT(n);
}
OZ_BI_end

OZ_C_proc_interface * oz_init_module(void)
{
  static OZ_C_proc_interface table[] ={
    {"susplistLength",1,1,BIsusplistLength},
    {0,0,0,0}
  };
  return table;
}
