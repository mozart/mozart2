%%% These tests check the resolving of relative uris.
%%% They are transcribed from those published by Roy Fielding
%%% <fielding@ics.uci.edu> at http://www.ics.uci.edu/~fielding/url/

declare
proc {TestFielding URI}
   OKALL
   proc {Run Test}
      {System.printInfo Test.title#' ['#Test.base#']\n'}
      Base={URI.make Test.base} OK
   in
      {ForAll Test.alist
       proc {$ Relative#Wanted}
          Resolved = {URI.toString
                      {URI.resolve Base {URI.make Relative}}}
       in
          {System.printInfo '\t'#Relative#'\t-> '#Wanted#
           case Resolved==Wanted then '\n' else
              OKALL=OK=false
              {Browse bad(base:Test.base rel:Relative wanted:Wanted
                          resolved:Resolved)}
              ' [FAILED]\n'
           end}
       end}
      {System.printInfo '===> '#
       case {IsDet OK} then 'FAILED\n' else 'SUCCEEDED\n' end}
   end
   Tests =
   [
    test(title:"Fielding's test 1"
         base :"http://a/b/c/d;p?q"
         alist:
            [
             "gg:h"     #"gg:h"
             "g"        #"http://a/b/c/g"
             "./g"      #"http://a/b/c/g"
             "g/"       #"http://a/b/c/g/"
             "/g"       #"http://a/g"
             "//g"      #"http://g"
             "?y"       #"http://a/b/c/?y"
             "g?y"      #"http://a/b/c/g?y"
             %%"#s"     #"(current document)#s"
             "g#s"      #"http://a/b/c/g#s"
             "g?y#s"    #"http://a/b/c/g?y#s"
             ";x"       #"http://a/b/c/;x"
             "g;x"      #"http://a/b/c/g;x"
             "g;x?y#s"  #"http://a/b/c/g;x?y#s"
             "."        #"http://a/b/c/"
             "./"       #"http://a/b/c/"
             ".."       #"http://a/b/"
             "../"      #"http://a/b/"
             "../g"     #"http://a/b/g"
             "../.."    #"http://a/"
             "../../"   #"http://a/"
             "../../g"  #"http://a/g"
            ]
        )
    test(title:"Fielding's test 1 -- Abnormal Examples --"
         base :"http://a/b/c/d;p?q"
         alist:
            [
             "../../../g"       #"http://a/../g"
             "../../../../g"    #"http://a/../../g"
             %%"/./g"           #"http://a/./g"
             "/../g"            #"http://a/../g"
             "g."               #"http://a/b/c/g."
             ".g"               #"http://a/b/c/.g"
             "g.."              #"http://a/b/c/g.."
             "..g"              #"http://a/b/c/..g"
             "./../g"           #"http://a/b/g"
             "./g/."            #"http://a/b/c/g/"
             "g/./h"            #"http://a/b/c/g/h"
             "g/../h"           #"http://a/b/c/h"
             "g;x=1/./y"        #"http://a/b/c/g;x=1/y"
             "g;x=1/../y"       #"http://a/b/c/y"
             "g?y/./x"          #"http://a/b/c/g?y/./x"
             "g?y/../x"         #"http://a/b/c/g?y/../x"
             "g#s/./x"          #"http://a/b/c/g#s/./x"
             "g#s/../x"         #"http://a/b/c/g#s/../x"
             "http:g"           #"http:g"
             "http:"            #"http:"
            ]
        )
    test(title:"Fielding's test 2"
         base :"http://a/b/c/d;p?q=1/2"
         alist:
            [
             "g"        #"http://a/b/c/g"
             "./g"      #"http://a/b/c/g"
             "g/"       #"http://a/b/c/g/"
             "/g"       #"http://a/g"
             "//g"      #"http://g"
             "?y"       #"http://a/b/c/?y"
             "g?y"      #"http://a/b/c/g?y"
             "g?y/./x"  #"http://a/b/c/g?y/./x"
             "g?y/../x" #"http://a/b/c/g?y/../x"
             "g#s"      #"http://a/b/c/g#s"
             "g#s/./x"  #"http://a/b/c/g#s/./x"
             "g#s/../x" #"http://a/b/c/g#s/../x"
             "./"       #"http://a/b/c/"
             "../"      #"http://a/b/"
             "../g"     #"http://a/b/g"
             "../../"   #"http://a/"
             "../../g"  #"http://a/g"
            ]
        )
    test(title:"Fielding's test 3"
         base :"http://a/b/c/d;p=1/2?q"
         alist:
            [
             "g"                #"http://a/b/c/d;p=1/g"
             "./g"              #"http://a/b/c/d;p=1/g"
             "g/"               #"http://a/b/c/d;p=1/g/"
             "g?y"              #"http://a/b/c/d;p=1/g?y"
             ";x"               #"http://a/b/c/d;p=1/;x"
             "g;x"              #"http://a/b/c/d;p=1/g;x"
             "g;x=1/./y"        #"http://a/b/c/d;p=1/g;x=1/y"
             "g;x=1/../y"       #"http://a/b/c/d;p=1/y"
             "./"               #"http://a/b/c/d;p=1/"
             "../"              #"http://a/b/c/"
             "../g"             #"http://a/b/c/g"
             "../../"           #"http://a/b/"
             "../../g"          #"http://a/b/g"
            ]
        )
    test(title:"Fielding's test 4"
         base :"fred:///s//a/b/c"
         alist:
            [
             "gg:h"             #"gg:h"
             "g"                #"fred:///s//a/b/g"
             "./g"              #"fred:///s//a/b/g"
             "g/"               #"fred:///s//a/b/g/"
             "/g"               #"fred:///g"
             "//g"              #"fred://g"
             "//g/x"            #"fred://g/x"
             "///g"             #"fred:///g"
             "./"               #"fred:///s//a/b/"
             "../"              #"fred:///s//a/"
             "../g"             #"fred:///s//a/g"
             "../../"           #"fred:///s//"
             "../../g"          #"fred:///s//g"
             "../../../g"       #"fred:///s/g"
             "../../../../g"    #"fred:///g"
            ]
        )
    test(title:"Fielding's test 5"
         base :"http:///s//a/b/c"
         alist:
            [
             "gg:h"             #"gg:h"
             "g"                #"http:///s//a/b/g"
             "./g"              #"http:///s//a/b/g"
             "g/"               #"http:///s//a/b/g/"
             "/g"               #"http:///g"
             "//g"              #"http://g"
             "//g/x"            #"http://g/x"
             "///g"             #"http:///g"
             "./"               #"http:///s//a/b/"
             "../"              #"http:///s//a/"
             "../g"             #"http:///s//a/g"
             "../../"           #"http:///s//"
             "../../g"          #"http:///s//g"
             "../../../g"       #"http:///s/g"
             "../../../../g"    #"http:///g"
            ]
        )
   ]
in
   {System.printInfo "Running Fielding's Tests\n"}
   {ForAll Tests Run}
   {System.printInfo ">>>>>>> "#
    case {IsDet OKALL} then 'FAILED!!!\n' else 'SUCCEEDED\n' end}
end

%{TestFielding URI}
