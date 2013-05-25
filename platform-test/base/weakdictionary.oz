%%%
%%% Authors:
%%%   Peter Van Roy <pvr@info.ucl.ac.be>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Peter Van Roy, 1997
%%%   Christian Schulte, 1997, 1998
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

local

   Ts = [put(0) put(1) put(2) put(3) put(4) put(5) put(6) put(7) put(8) 
	 put(9) put(10) put(11) put(12) put(13) put(14) put(15) put(16) 
         put(17) put(18) put(19) put(20) put(21) put(22) put(23) 
         put(24) put(25) put(26) put(27) put(28) put(29) put(30) 
         put(31) put(32) put(33) put(34) put(35) put(36) put(37) 
         put(38) put(39) put(40) put(41) put(42) put(43) put(44) 
         put(45) put(46) put(47) put(48) put(49) put(50) put(51) 
         put(52) put(53) put(54) put(55) put(56) put(57) put(58) 
         put(59) put(60) put(61) put(62) put(63) put(64) put(65) 
         put(66) put(67) put(68) put(69) put(70) put(71) put(72) 
         put(73) put(74) put(75) put(76) put(77) put(78) put(79) 
         put(80) put(81) put(82) put(83) put(84) put(85) put(86) 
         put(87) put(88) put(89) put(90) put(91) put(92) put(93) 
         put(94) put(95) put(96) put(97) put(98) put(99) put(100) 
         put(101) put(102) put(103) put(104) put(105) put(106) put(107) 
         put(108) put(109) put(110) put(111) put(112) put(113) put(114) 
         put(115) put(116) put(117) put(118) put(119) put(120) put(121) 
         put(122) put(123) put(124) put(125) put(126) put(127) put(128) 
         put(129) put(130) put(131) put(132) put(133) put(134) put(135) 
         put(136) put(137) put(138) remove(134) remove(135) remove(136) 
         remove(137) remove(138) put(139) put(140) put(141) put(142) 
         put(143) remove(139) remove(140) remove(141) remove(142) 
         remove(143) put(144) put(145) put(146) put(147) put(148) 
         put(149) put(150) put(151) put(152) put(153) put(154) put(155) 
         put(156) put(157) put(158) remove(149) remove(150) remove(151) 
         remove(152) remove(153) remove(154) remove(155) remove(156) 
         remove(157) remove(158) remove(144) remove(145) remove(146) 
         remove(147) remove(148) put(159) put(160) put(161) put(162) 
         put(163) remove(159) remove(160) remove(161) remove(162) 
         remove(163) put(164) put(165) put(166) put(167) put(168) 
         put(169) put(170) put(171) put(172) put(173) put(174) put(175) 
         put(176) put(177) put(178) remove(169) remove(170) remove(171) 
         remove(172) remove(173) remove(174) remove(175) remove(176) 
         remove(177) remove(178) remove(164) remove(165) remove(166) 
         remove(167) remove(168) put(179) put(180) put(181) put(182) 
         put(183) remove(179) remove(180) remove(181) remove(182) 
         remove(183) put(184) put(185) put(186) put(187) put(188) 
         put(189) put(190) put(191) put(192) put(193) put(194) put(195) 
         put(196) put(197) put(198) remove(189) remove(190) remove(191) 
         remove(192) remove(193) remove(194) remove(195) remove(196) 
         remove(197) remove(198) remove(184) remove(185) remove(186) 
         remove(187) remove(188) put(199) put(200) put(201) put(202) 
         put(203) remove(199) remove(200) remove(201) remove(202) 
         remove(203) put(204) put(205) put(206) put(207) put(208) 
         put(209) put(210) put(211) put(212) put(213) put(214) put(215) 
         put(216) put(217) put(218) remove(209) remove(210) remove(211) 
         remove(212) remove(213) remove(214) remove(215) remove(216) 
         remove(217) remove(218) remove(204) remove(205) remove(206) 
         remove(207) remove(208) put(219) put(220) put(221) put(222) 
         put(223) remove(219) remove(220) remove(221) remove(222) 
         remove(223) put(224) put(225) put(226) put(227) put(228) 
         put(229) put(230) put(231) put(232) put(233) put(234) put(235) 
         put(236) put(237) put(238) remove(229) remove(230) remove(231) 
         remove(232) remove(233) remove(234) remove(235) remove(236) 
         remove(237) remove(238) remove(224) remove(225) remove(226) 
         remove(227) remove(228) put(239) put(240) put(241) put(242) 
         put(243) remove(239) remove(240) remove(241) remove(242) 
         remove(243) put(244) put(245) put(246) put(247) put(248) 
         put(249) put(250) put(251) put(252) put(253) put(254) put(255) 
         put(256) put(257) put(258) remove(249) remove(250) remove(251) 
         remove(252) remove(253) remove(254) remove(255) remove(256) 
         remove(257) remove(258) remove(244) remove(245) remove(246) 
         remove(247) remove(248) put(259) put(260) put(261) put(262) 
         put(263) remove(259) remove(260) remove(261) remove(262) 
         remove(263) put(264) put(265) put(266) put(267) put(268) 
         put(269) put(270) put(271) put(272) put(273) put(274) put(275) 
         put(276) put(277) put(278)]

in

   functor

   export
      Return

   define
      Return=
      weakdictionary([dynamics(
         fun {$}
	    S
	    D = {WeakDictionary.new S}
	    C = {Cell.new S}

	    fun {Remove Is J}
	       case Is of nil then nil
	       [] I|Ir then
		  if I==J then Ir
		  else I|{Remove Ir J}
		  end
	       end
	    end

	    fun {RestoreEntries L}
	       if {Value.isDet L} then
		  case L of nil then
		     raise
			'closed weak dictionary\' finalization stream??!'
		     end
		     nil
		  [] K#V|Lr then
		     {WeakDictionary.put D K V}
		     {RestoreEntries Lr}
		  else
		     raise
			'invalid weak dictionary finalization stream??!'
		     end
		     nil
		  end
	       else L
	       end
	    end

	    fun {TestEntries Is D}
	       case Is of nil then true
	       [] I|Ir then
		  if {WeakDictionary.condGet D I false} then
		     {TestEntries Ir D}
		  else H T in 
		     {Cell.exchange C H T}
		     if {Value.isDet H} then
			%% something in the stream - have to check it;
			T = {RestoreEntries H}
			{TestEntries Is D}	% fine unless too frequent GC
		     else
			%% guaranteed a trouble
			H = T
			false
		     end
		  end
	       end
	    end

	    fun {Check Ts Is}
	       if {TestEntries Is D} then
		  case Ts
		  of nil then true
		  [] T|Tr then
		     case T
		     of put(I) then
			{WeakDictionary.put D I true}
			{Check Tr I|Is}
		     [] remove(I) then
			{WeakDictionary.remove D I}
			{Check Tr {Remove Is I}}
		     end
		  end
	       else false
	       end
	    end
	 in
	    {Check Ts nil}
	 end
			   keys: [dictionary])])
   end
end
