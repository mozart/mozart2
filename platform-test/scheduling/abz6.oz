%%%
%%% Authors:
%%%   Joerg Wuertz, 1998
%%%
%%% Copyright:
%%%   Joerg Wuertz, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

import

   FD

   Schedule

   Search

   Space
   
export
   Return
define

   proc {Trace Msg}
      skip
   end

   Pabz6Opt = 
   abz6(taskSpec:
	   [% task # duration # preceding tasks # resources
	    pa # 0  # nil  # noResource
	    a1#62#[pa]#m7 a2#24#[a1]#m8 a3#25#[a2]#m5 a4#84#[a3]#m3
	    a5#47#[a4]#m4 a6#38#[a5]#m6 a7#82#[a6]#m2 a8#93#[a7]#m0
	    a9#24#[a8]#m9 a10#66#[a9]#m1
	    b1#47#[pa]#m5 b2#97#[b1]#m2 b3#92#[b2]#m8 b4#22#[b3]#m9
	    b5#93#[b4]#m1 b6#29#[b5]#m4 b7#56#[b6]#m7 b8#80#[b7]#m3
	    b9#78#[b8]#m0 b10#67#[b9]#m6
	    c1#45#[pa]#m1 c2#46#[c1]#m7 c3#22#[c2]#m6 c4#26#[c3]#m2
	    c5#38#[c4]#m9 c6#69#[c5]#m0 c7#40#[c6]#m4 c8#33#[c7]#m3
	    c9#75#[c8]#m8 c10#96#[c9]#m5
	    d1#85#[pa]#m4 d2#76#[d1]#m8 d3#68#[d2]#m5 d4#88#[d3]#m9
	    d5#36#[d4]#m3 d6#75#[d5]#m6 d7#56#[d6]#m2 d8#35#[d7]#m1
	    d9#77#[d8]#m0 d10#85#[d9]#m7
	    e1#60#[pa]#m8 e2#20#[e1]#m9 e3#25#[e2]#m7 e4#63#[e3]#m3
	    e5#81#[e4]#m4 e6#52#[e5]#m0 e7#30#[e6]#m1 e8#98#[e7]#m5
	    e9#54#[e8]#m6 e10#86#[e9]#m2
	    f1#87#[pa]#m3 f2#73#[f1]#m9 f3#51#[f2]#m5 f4#95#[f3]#m2
	    f5#65#[f4]#m4 f6#86#[f5]#m1 f7#22#[f6]#m6 f8#58#[f7]#m8
	    f9#80#[f8]#m0 f10#65#[f9]#m7
	    g1#81#[pa]#m5 g2#53#[g1]#m2 g3#57#[g2]#m7 g4#71#[g3]#m6
	    g5#81#[g4]#m9 g6#43#[g5]#m0 g7#26#[g6]#m4 g8#54#[g7]#m8
	    g9#58#[g8]#m3 g10#69#[g9]#m1
	    h1#20#[pa]#m4 h2#86#[h1]#m6 h3#21#[h2]#m5 h4#79#[h3]#m8
	    h5#62#[h4]#m9 h6#34#[h5]#m2 h7#27#[h6]#m0 h8#81#[h7]#m1
	    h9#30#[h8]#m7 h10#46#[h9]#m3
	    i1#68#[pa]#m9 i2#66#[i1]#m6 i3#98#[i2]#m5 i4#86#[i3]#m8
	    i5#66#[i4]#m7 i6#56#[i5]#m0 i7#82#[i6]#m3 i8#95#[i7]#m1
	    i9#47#[i8]#m4 i10#78#[i9]#m2
	    j1#30#[pa]#m0 j2#50#[j1]#m3 j3#34#[j2]#m7 j4#58#[j3]#m2
	    j5#77#[j4]#m1 j6#34#[j5]#m5 j7#84#[j6]#m8 j8#40#[j7]#m4
	    j9#46#[j8]#m9 j10#44#[j9]#m6
	    pe#0#[ j10 i10 h10 g10 f10 e10 d10 c10 b10 a10 ]#noResource ]
	constraints: proc{$ Start Dur}
			skip
		     end
	type: jobshop)
   
   Pabz6Proof = 
   abz6(taskSpec:
	   [% task # duration # preceding tasks # resources
	    pa # 0  # nil  # noResource
	    a1#62#[pa]#m7 a2#24#[a1]#m8 a3#25#[a2]#m5 a4#84#[a3]#m3
	    a5#47#[a4]#m4 a6#38#[a5]#m6 a7#82#[a6]#m2 a8#93#[a7]#m0
	    a9#24#[a8]#m9 a10#66#[a9]#m1
	    b1#47#[pa]#m5 b2#97#[b1]#m2 b3#92#[b2]#m8 b4#22#[b3]#m9
	    b5#93#[b4]#m1 b6#29#[b5]#m4 b7#56#[b6]#m7 b8#80#[b7]#m3
	    b9#78#[b8]#m0 b10#67#[b9]#m6
	    c1#45#[pa]#m1 c2#46#[c1]#m7 c3#22#[c2]#m6 c4#26#[c3]#m2
	    c5#38#[c4]#m9 c6#69#[c5]#m0 c7#40#[c6]#m4 c8#33#[c7]#m3
	    c9#75#[c8]#m8 c10#96#[c9]#m5
	    d1#85#[pa]#m4 d2#76#[d1]#m8 d3#68#[d2]#m5 d4#88#[d3]#m9
	    d5#36#[d4]#m3 d6#75#[d5]#m6 d7#56#[d6]#m2 d8#35#[d7]#m1
	    d9#77#[d8]#m0 d10#85#[d9]#m7
	    e1#60#[pa]#m8 e2#20#[e1]#m9 e3#25#[e2]#m7 e4#63#[e3]#m3
	    e5#81#[e4]#m4 e6#52#[e5]#m0 e7#30#[e6]#m1 e8#98#[e7]#m5
	    e9#54#[e8]#m6 e10#86#[e9]#m2
	    f1#87#[pa]#m3 f2#73#[f1]#m9 f3#51#[f2]#m5 f4#95#[f3]#m2
	    f5#65#[f4]#m4 f6#86#[f5]#m1 f7#22#[f6]#m6 f8#58#[f7]#m8
	    f9#80#[f8]#m0 f10#65#[f9]#m7
	    g1#81#[pa]#m5 g2#53#[g1]#m2 g3#57#[g2]#m7 g4#71#[g3]#m6
	    g5#81#[g4]#m9 g6#43#[g5]#m0 g7#26#[g6]#m4 g8#54#[g7]#m8
	    g9#58#[g8]#m3 g10#69#[g9]#m1
	    h1#20#[pa]#m4 h2#86#[h1]#m6 h3#21#[h2]#m5 h4#79#[h3]#m8
	    h5#62#[h4]#m9 h6#34#[h5]#m2 h7#27#[h6]#m0 h8#81#[h7]#m1
	    h9#30#[h8]#m7 h10#46#[h9]#m3
	    i1#68#[pa]#m9 i2#66#[i1]#m6 i3#98#[i2]#m5 i4#86#[i3]#m8
	    i5#66#[i4]#m7 i6#56#[i5]#m0 i7#82#[i6]#m3 i8#95#[i7]#m1
	    i9#47#[i8]#m4 i10#78#[i9]#m2
	    j1#30#[pa]#m0 j2#50#[j1]#m3 j3#34#[j2]#m7 j4#58#[j3]#m2
	    j5#77#[j4]#m1 j6#34#[j5]#m5 j7#84#[j6]#m8 j8#40#[j7]#m4
	    j9#46#[j8]#m9 j10#44#[j9]#m6
	    pe#0#[ j10 i10 h10 g10 f10 e10 d10 c10 b10 a10 ]#noResource ]
	constraints: proc{$ Start Dur}
			skip
			Start.pe =<: 943  %opt
		     end
	type: jobshop)

   \insert  'resourceConstraints'
   
   \insert  'compilers'
    
   \insert  'resourceEnumeration'

   \insert  'order'

   \insert  'enum'

   \insert  'search'

   \insert  'local.oz'

   proc {Dummy _}
      skip
   end
   
   Return=
   schedule(equal(fun {$}
		     Solution1
		     Solution2
		     _ = {New LocalSearchHeuristic
			  start(spec:                 Pabz6Opt
				compiler:             Compiler
				resourceDistribution: TaskIntervalsOptNew
				taskDistribution:     NoTE
				resourceConstraints:  ResourceConstraintEF
				label:                Dummy
				order:                CanonicOrder
				rcd:                  1
				lb:                   0
				solution:             Solution1)}
		     _ = {New SearchBAB
			  start(spec:                 Pabz6Proof
				compiler:             Compiler
				taskDistribution:     NoTE
				resourceDistribution: TaskIntervalsProofNew
				resourceConstraints:  ResourceConstraintEF
				ub:                   1000
				lb:                   0
				label:                Dummy
				order:                CanonicOrder
				rcd:                  1
				solution:             Solution2)}
		  in
		     
		     {Solution1.1}.start.pe == 943
		     andthen Solution2.start.pe == 943

		  end
		  true)
	    keys: [scheduling fd]
	    bench:1
	   )
end
