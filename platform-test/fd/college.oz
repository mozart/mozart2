functor

import

   FD

   Search

export
   Return
define

Monday          = 1#36
Tuesday         = 37#72
Wednesday       = 73#108
Thursday        = 109#144
Friday          = 145#180

QuartersPerDay  = 36
QuartersPerHour = 4

HourLimit           = 180
LecturesStartForDay = 8
MaximumRooms        = 7
Teacher1Off         = 3
   
Week = [Monday Tuesday Wednesday Thursday Friday] 
   
MorningQuarters = 18
   
[MondayM TuesdayM WednesdayM ThursdayM FridayM]
= {Map Week fun {$ S#_} S#(S + MorningQuarters - 1) end}

Afternoon 
[MondayA TuesdayA WednesdayA ThursdayA FridayA]
= Afternoon
= {Map Week fun {$ S#E} (S + MorningQuarters)#E end}


fun {DayTimeToQuarters Day FH FQ TH TQ}
   Left Right Offset in
   Offset = (36 * (Day.1 div QuartersPerDay) + 1) 
   Left  = Offset + (FH - LecturesStartForDay) * QuartersPerHour + FQ - 1
   Right = Offset + (TH-LecturesStartForDay) * QuartersPerHour + TQ - 1
   Left#Right
end

AstaTime = {DayTimeToQuarters Tuesday 12 3 13 3}


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Lecture and Professor Manipulation :-} Functions
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

local
   
   DayMap= map(monday:    Monday
	       tuesday:   Tuesday
	       wednesday: Wednesday
	       thursday:  Thursday
	       friday:    Friday)
   
   %% Translate the constraint description
   %% into a domain that can stand after /* :: and \:: */
   fun {MakeC Desc}
      case Desc
      of inDays(L) then {Map L fun {$ D} DayMap.D end}
      [] weekInterval(SH#SM#EH#EM) then
	 {Map Week
	  fun {$ Day}
	     {DayTimeToQuarters Day SH SM div 15 EH EM div 15}
	  end}
      [] dayInterval(Day#SH#SM#EH#EM) then
	 [{DayTimeToQuarters DayMap.Day SH (SM div 15) EH (EM div 15)}]
      [] fix(Day#H#M) then
	 [{DayTimeToQuarters DayMap.Day H (M div 15) H (M div 15)}]
      else {Record.foldR Desc
	    fun {$ D In} {Append {MakeC D} In} end nil}
      end
   end

   %% compute the constraint procedure
   %% for a lecturer from his/her constraint description
   proc {ApplyConstraint Desc X}
      case {Label Desc}
      of noT  then  X :: compl({MakeC Desc.1})
      [] nil	 then  skip
      else          X :: {MakeC Desc}
      end
   end

   %% compute the lectures of a prof
   %% from the lecture list
   fun {ProfToLectures PName Ls}
      {Filter Ls fun {$ L} L.professor==PName end}
   end

in
      
   fun {MakeLectures LecturesDescs Semester Ordering}
      {Map {Record.toList LecturesDescs.Semester}
       fun {$ Ls}
	  {Map Ls
	   fun {$ L}
	      Start = {FD.int 1#(HourLimit-L.dur)}
	   in
	      if {HasFeature L constraints}
	      then {ApplyConstraint L.constraints Start}
	      else skip
	      end
	      {Adjoin L l(start:    Start
			  ordering: Ordering
			  semester: Semester)}
	   end}
       end}
   end
      
   %% translate the prof record into a
   %% list of records, containing constraint procedures
   fun {MakeProfessors ProfDesc Ls}
      {Record.foldRInd ProfDesc
       fun {$ I X In}
	  PLs={ProfToLectures I Ls}
       in
	  {ForAll PLs proc {$ PL} {ApplyConstraint X PL.start} end}
	  professor(lectures:PLs name:I) | In
       end
       nil}
   end
end

%% get Lectures with size out of a given list of Specifiers
fun {FilterSize Specifiers Lectures}
   {Filter Lectures fun {$ X} {Member X.size Specifiers} end}
end

%% make record for all lectures for easy access
fun {MakeLectureRecord Flats}
   {List.toRecord lectures {Map Flats fun {$ L} L.name#L end}}
end
   
%% search for professor in list of profs
fun {SearchProf Profs Name}
   {List.dropWhile Profs fun {$ P} P.name \= Name end}.1
end
   
%% %%%%%%%%%%%
%% Enumeration
%% %%%%%%%%%%%

local
   fun {SkipWait Xs}
      case Xs
      of X|Xr then case {FD.reflect.size X.start}
		   of 1 then {SkipWait Xr}
		   else Xs
		   end
      [] nil then nil
      end
   end
      
   proc {Choose Xs HoleTail HoleHead MinYet SizeYet ?Min ?Ys}
      case Xs
      of X|Xr then 
	 SizeX = {FD.reflect.size X.start} in
	 case SizeX of 1 then 
	    {Choose Xr HoleTail HoleHead MinYet SizeYet Min Ys}
	 elseif SizeX < SizeYet then
	    NewHole in
	    HoleTail = MinYet | HoleHead
	    {Choose Xr Ys NewHole X SizeX Min NewHole}
	 else
	    Ys=X | {Choose Xr HoleTail HoleHead MinYet SizeYet Min}
	 end
      [] nil then Min = MinYet Ys = nil HoleTail = HoleHead
      end
   end
   fun {Cost I Ls C}
      case Ls of nil then
	 {Exception.raiseError college(Cost [I Ls C] 'tragic error')}
	 _
      [] A#B|Lr then
	 if A =< I andthen I =< B
	 then C
	 else {Cost I Lr C+1}
	 end
      end
   end

   fun {GetFirst Domain Min MinVal Ordering}
      case Domain of nil then Min
      [] D|Dr
      then TMinVal = {Cost D Ordering 1} in
	 if TMinVal<MinVal then {GetFirst Dr D TMinVal Ordering}
	 else {GetFirst Dr Min MinVal Ordering}
	 end
      end
   end
in
   proc {Enum Xs}
      choice
	 case {SkipWait Xs}
	 of nil then skip
	 [] X|Xr then
	    Y Yr Hole Val YDom YVar in
	    {Choose Xr Yr Hole X {FD.reflect.size X.start} Y Hole}
	    {Wait Y}
	    YVar = Y.start
	    YDom = {FD.reflect.domList YVar}
	    Val = {GetFirst YDom.2 YDom.1 {Cost YDom.1 Y.ordering 1}
		   Y.ordering}
	    choice
	       YVar=Val {Enum Yr}
	    []
	       YVar\=:Val {Enum Y|Yr}
	    end
	 end
      end
   end
end

%% %%%%%%%%%%%%%%%%%%%%%
%% Branch and Bound Cost Function
%% %%%%%%%%%%%%%%%%%%%%%
local 
   fun {SumUp Lectures Time}
      case Lectures of nil then nil
      [] L|Lr
      then case {Atom.toString L.name}.1
	   of &M then 0|{SumUp Lr Time}
	   [] &F then 0|{SumUp Lr Time}
	   else (L.start::Time)|{SumUp Lr Time}
	   end
      end
   end
in
   fun {Cost Lectures}
      Costs = {FD.decl} in
      {FD.sum {SumUp Lectures [MondayA TuesdayA WednesdayA ThursdayA FridayA]} '=:' Costs}
      Costs
   end
end
   

%% %%%%%%%%%%%%%%%%%%%%%
%% Constraint Procedures
%% %%%%%%%%%%%%%%%%%%%%%

proc {OnSpecialDayOnly Lectures Day}
   {ForAll Lectures proc {$ Lec} Lec.start :: Day end}
end
proc {OnSpecialTimeOnly Lectures Time}
   {ForAll Lectures proc {$ Lec} Lec.start :: Time end}
end
proc {ForbidAsta Lectures}
   {ForAll Lectures
    proc {$ Lec} Lec.start :: compl((AstaTime.1-Lec.dur+1)#AstaTime.2) end}
end
proc {DayBreak Break Lectures}
   {ForAll Lectures
    proc {$ Lec}
       {ForAll Break proc{$ B}
			Left = (B.1-Lec.dur)
		     in
			if Left < 0 then
			   Lec.start :: compl(0#B.2)
			else
			   Lec.start :: compl(Left#B.2)
			end
		     end}
    end}
end
   
proc {NotParallel Offset Teacher1 Teacher15}
   {ForAll Teacher1.lectures
    proc {$ FL}
       {ForAll Teacher15.lectures
	proc{$ LFL}
	   {FD.disjoint FL.start FL.dur+Offset LFL.start LFL.dur+Offset}
	end}
    end}
end

%% The lectures of a semester must not overlap
   
proc {NoOverlapSemester Lectures}
   case Lectures of nil then skip
   [] L|Lr
   then {NoOverlap1 Lr L} {NoOverlapSemester Lr}
   end
end
proc {NoOverlap1 Lecs Lec1}
   case Lecs of nil then skip
   [] L|Lr
   then {NoOverlap2 Lec1 L} {NoOverlap1 Lr Lec1}
   end
end
proc {NoOverlap2 L1 L2}
   {ForAll L1
    proc{$ L}
       {ForAll L2
	proc {$ LP}
	   %% After one hour must be a quarter
	   %% and after two hours two quarters
	   %% recreation time
	   LDur LPDur in
	   LDur= if L.dur<4
		 then L.dur+1
		 else L.dur+2
		 end
	   LPDur= if LP.dur<4
		  then LP.dur+1
		  else LP.dur+2
		  end
	   {FD.disjoint L.start LDur LP.start LPDur}
	end}
    end}
end

%% The lectures of a professor must not overlap
proc {NoOverlapLectures Lectures}
   case Lectures of nil then skip
   [] L|Lr
   then {NoOverlapLecs1 L Lr} {NoOverlapLectures Lr}
   end
end

proc {NoOverlapLecs1 Lec Lec1}
   case Lec1 of nil then skip
   [] L|Lr
   then {NoOverlapLecs2 Lec L} {NoOverlapLecs1 Lec Lr}
   end
end
   
proc {NoOverlapLecs2 L1 L2}
   %% After one hour must be a quarter
   %% and after two hours two quarters
   %% recreation time
   L1Dur L2Dur in
   L1Dur= if L1.dur < 4 then L1.dur + 1 else L1.dur + 2 end
   L2Dur= if L2.dur < 4 then L2.dur + 1 else L2.dur + 2
	  end
   {FD.disjoint L1.start L1Dur L2.start L2Dur}
end

%% Constraint AtMostLectures for rooms
   
local 
   fun {SumUpLectures Lectures Hour}
      case Lectures
      of L|Lr
      then
	 %% Rooms are empty for a quarter after each lecture
	 Left = Hour-(L.dur+1)+1
      in 
	 if Left < 0 then (L.start :: 0#Hour)|{SumUpLectures Lr Hour}
	 else             (L.start :: Left#Hour)|{SumUpLectures Lr Hour}
	 end
      [] nil then nil
      end
   end
in
   proc {AtMostLectures Lectures Limit}
      {For 1 HourLimit 1
       proc{$ Hour}
	  {FD.sum {SumUpLectures Lectures Hour} '=<:' Limit}
       end}
   end
end

%% Constraint ThreeDaysOnly and OnDifferentDays

local
   fun {SumUp Lectures Day}
      case Lectures of nil then nil
      [] L|Lr
      then (L.start :: Day)|{SumUp Lr Day}
      end
   end
   proc {SumUpDays Lectures BDay Day}
      S= {SumUp Lectures Day}
   in
      BDay = ({FoldL S FD.plus 0} >=: 1)
   end
in
   proc {ThreeDaysOnly Lectures DayLimit}
      [BMo BTu BWe BTh BFr]={FD.dom 0#1}
   in
      BMo+BTu+BWe+BTh+BFr =<: DayLimit
      {SumUpDays Lectures BMo Monday}
      {SumUpDays Lectures BTu Tuesday}
      {SumUpDays Lectures BWe Wednesday}
      {SumUpDays Lectures BTh Thursday}
      {SumUpDays Lectures BFr Friday}
   end
   proc {OnDifferentDays Lectures}
      [BMo BTu BWe BTh BFr]={FD.dom 0#1}
   in
      BMo+BTu+BWe+BTh+BFr =: {Length Lectures}
      {SumUpDays Lectures BMo Monday}
      {SumUpDays Lectures BTu Tuesday}
      {SumUpDays Lectures BWe Wednesday}
      {SumUpDays Lectures BTh Thursday}
      {SumUpDays Lectures BFr Friday}
   end
   proc {OnSameDay Lectures}
      [BMo BTu BWe BTh BFr]={FD.dom 0#1}
   in
      BMo+BTu+BWe+BTh+BFr =: 1
      {SumUpDays Lectures BMo Monday}
      {SumUpDays Lectures BTu Tuesday}
      {SumUpDays Lectures BWe Wednesday}
      {SumUpDays Lectures BTh Thursday}
      {SumUpDays Lectures BFr Friday}
   end	 
end
local
   fun {SumUpOverlaps L1 Lectures}
      case Lectures of nil then nil
      [] L2|Lr then B={FD.int 0#1} L1Dur L2Dur in
	 if L1.name==L2.name then 0|{SumUpOverlaps L1 Lr}
	 else L1S L2S in
	    L1Dur= if L1.dur < 4 then L1.dur + 1 else L1.dur + 2 end
	    L2Dur= if L2.dur < 4 then L2.dur + 1 else L2.dur + 2 end
	    L1S = L1.start
	    L2S = L2.start

	    /* That is the (operational) semantics of FD.tasksOverlap.
	    FD.tasksOverlap implements constructive disjunction.
	    condis
	    B=:1
	    L1S + L1Dur >: L2S
	    L2S + L2Dur >: L1S
	 []
	    B=:0
	    L1S + L1Dur =<: L2S
	 []
	    B=:0
	    L2S + L2Dur =<: L1S
	 end
	 */
	 {FD.tasksOverlap L1S L1Dur L2S L2Dur B}
	 B|{SumUpOverlaps L1 Lr}
      end
   end
end 
in
proc {AtmostOneOverlap Lecture Lectures}
   {FD.sum {SumUpOverlaps Lecture Lectures} '=<:' 1}
end
end

 
%% %%%%%%%%%%%
%% The Problem
%% %%%%%%%%%%%

%% MakeProblem makes the problem procedure
%% using the problem description as global variable
   
fun {MakeProblem ProblemDescription}

   proc {$ FlatAllLectures}
	 
      %% %%%%%%%%
      %% Lectures
      %% %%%%%%%%
	 
      LecturesDescription = ProblemDescription.lectures

      %% Second Semester
      %% %%%%%%%%%%%%%%%
	 
      LecturesSecond = {MakeLectures
			LecturesDescription
			second
			%% other priorities

			[MondayM MondayA
			 TuesdayA TuesdayM
			 WednesdayM WednesdayA
			 FridayM  FridayA
			 ThursdayM ThursdayA
			]
		       }
      %% Fourth Semester
      %% %%%%%%%%%%%%%%%

      LecturesFourth = {MakeLectures
			LecturesDescription
			fourth
			%% other priorities

			[
			 WednesdayM WednesdayA
			 TuesdayM TuesdayA
			 MondayM MondayA
			 ThursdayM ThursdayA
			 FridayM FridayA
			]


		       }
      GrundStudiumLectures = {Append LecturesSecond LecturesFourth}
      FlatGrundStudiumLectures = {List.flatten GrundStudiumLectures}

      %% Sixth Semester
      %% %%%%%%%%%%%%%%

      LecturesSixth = {MakeLectures
		       LecturesDescription
		       sixth
		       %% other priorities

		       [ WednesdayM WednesdayA
			 FridayM FridayA
			 ThursdayM ThursdayA
			 MondayM MondayA
			 TuesdayM TuesdayA
		       ]
		      }

      FlatLecturesSixth = {List.flatten LecturesSixth}

      %% Eighth Semester
      %% %%%%%%%%%%%%%%%

      LecturesEighth = {MakeLectures
			LecturesDescription
			eighth
			[
			 ThursdayM ThursdayA
			 WednesdayA WednesdayM
			 MondayA  MondayM
			 TuesdayA TuesdayM
			 FridayM FridayA
			]}
	 
      FlatLecturesEighth = {List.flatten LecturesEighth}

      NotOnThursdayLectures = {Append GrundStudiumLectures LecturesSixth}
      AllSemesterLectures = {Append NotOnThursdayLectures LecturesEighth}
      FlatAllSemesterLectures={List.flatten AllSemesterLectures}

      %% Medien Lectures
      %% %%%%%%%%%%%%%%%

      MedienLectures = {MakeLectures
			LecturesDescription
			medien
			[
			 ThursdayA TuesdayA
			 TuesdayM ThursdayM
			 WednesdayM WednesdayA
			 MondayM MondayA
			 FridayM FridayA
			]}

      FlatMedienLectures = {List.flatten MedienLectures}
	 
      %% Fakult Lectures
      %% %%%%%%%%%%%%%%%

      FakLectures = {MakeLectures
		     LecturesDescription
		     fac
		     [
		      WednesdayM WednesdayA
		      ThursdayM ThursdayA
		      MondayM MondayA
		      FridayM FridayA
		      TuesdayM TuesdayA
		     ]
		    }

      FlatFakLectures = {List.flatten FakLectures}

      AllLectures = {Append AllSemesterLectures
		     {Append MedienLectures FakLectures}}

      !FlatAllLectures = {List.flatten AllLectures}

      L = {MakeLectureRecord FlatAllLectures}
	 
      %% %%%%%%%%%%
      %% Professors
      %% %%%%%%%%%%

      ProfessorsDescription = ProblemDescription.professors

      Professors = {MakeProfessors ProfessorsDescription FlatAllLectures}

   in

      %% %%%%%%%%%%%%%%%
      %% The Constraints
      %% %%%%%%%%%%%%%%%

      %% General constraints
      %% Lecture must be finished at 17.00

      {ForAll FlatAllLectures
       proc{$ L}
	  Dur = L.dur
	  fun {AfterHours Day} Day.2 + 1 - Dur#Day.2  end
       in
	  L.start :: compl({Map Week AfterHours})
       end}


      %% All semesters but the eighth are not scheduled on thursday
      %% seems to be to hard
	 
      {OnSpecialDayOnly FlatLecturesSixth Wednesday}
      %% The break must be lecturefree

      {DayBreak
       {List.map [0 1 2 3 4] fun{$ I} (20+I*36)#(23+I*36) end}
       {Append FlatLecturesEighth FlatGrundStudiumLectures}}
	 
      {DayBreak {List.map [0 1 2 3 4]
		 fun{$ I} (16+I*36)#(19+I*36) end}
       FlatLecturesSixth}

      %% At Asta time no lectures allowed
      {ForbidAsta FlatAllLectures}

      %% The Lectures for a semester must not overlap
      {NoOverlapSemester [[L.'2.1' L.'2.2' L.'2.3']
			  [L.'2.6']
			  [L.'2.7']
			  [ L.'2.9']
			  [L.'2.10.1' L.'2.10.2' L.'2.10.3']
			  [L.'2.5.1' L.'2.5.2' L.'2.8.1' L.'2.8.2'
			   L.'2.13.1' L.'2.13.2' L.'2.4.1' L.'2.4.2'
			   L.'2.14.1' L.'2.14.2' L.'2.15.1' L.'2.15.2'
			   L.'2.15.3' L.'2.15.4' ]]}

      {ForAll [L.'2.5.1' L.'2.5.2' L.'2.8.1' L.'2.8.2'
	       L.'2.13.1' L.'2.13.2' L.'2.4.1' L.'2.4.2'
	       L.'2.14.1' L.'2.14.2']
       proc{$ Lecture}
	  {AtmostOneOverlap Lecture [L.'2.5.1' L.'2.5.2' L.'2.8.1'
				     L.'2.8.2' L.'2.13.1' L.'2.13.2'
				     L.'2.4.1' L.'2.4.2' L.'2.14.1'
				     L.'2.14.2' L.'2.15.1' L.'2.15.2'
				     L.'2.15.3' L.'2.15.4']}
       end}
      {ForAll [L.'2.15.1' L.'2.15.2' L.'2.15.3' L.'2.15.4']
       proc{$ Lecture}
	  {AtmostOneOverlap Lecture [L.'2.5.1' L.'2.5.2' L.'2.8.1'
				     L.'2.8.2' L.'2.13.1' L.'2.13.2'
				     L.'2.4.1' L.'2.4.2' L.'2.14.1'
				     L.'2.14.2']}
       end}


      {NoOverlapSemester [[L.'4.1'] [L.'4.6'] [L.'4.11' ]
			  [ L.'4.2.1' L.'4.2.2' L.'4.3.1' L.'4.3.2'
			    L.'4.4.1' L.'4.4.2' L.'4.5.1' L.'4.5.2' 
			    L.'4.7.1' L.'4.7.2' L.'4.10.1' L.'4.10.2' 
			    L.'4.12.1' L.'4.12.2'
			    L.'4.8.1' L.'4.8.2' L.'4.8.3' L.'4.8.4']]}

      {ForAll [ L.'4.2.1' L.'4.2.2' L.'4.3.1' L.'4.3.2'
		L.'4.4.1' L.'4.4.2' L.'4.5.1' L.'4.5.2' 
		L.'4.7.1' L.'4.7.2' L.'4.10.1' L.'4.10.2'
		L.'4.12.1' L.'4.12.2']
       proc{$ Lecture}
	  {AtmostOneOverlap
	   Lecture [ L.'4.2.1' L.'4.2.2' L.'4.3.1' L.'4.3.2'
		     L.'4.4.1' L.'4.4.2' L.'4.5.1' L.'4.5.2' 
		     L.'4.7.1' L.'4.7.2' L.'4.10.1' L.'4.10.2'
		     L.'4.12.1' L.'4.12.2'
		     L.'4.8.1' L.'4.8.2' L.'4.8.3' L.'4.8.4']}
       end}

      {ForAll [L.'4.8.1' L.'4.8.2' L.'4.8.3' L.'4.8.4']
       proc{$ Lecture}
	  {AtmostOneOverlap
	   Lecture [ L.'4.2.1' L.'4.2.2' L.'4.3.1' L.'4.3.2'
		     L.'4.4.1' L.'4.4.2' L.'4.5.1' L.'4.5.2' 
		     L.'4.7.1' L.'4.7.2' L.'4.10.1' L.'4.10.2'
		     L.'4.12.1' L.'4.12.2' ]}
       end}



      {NoOverlapSemester [[L.'6.2.1' L.'6.2.2'] [L.'6.5' L.'6.6'] ]}
      {NoOverlapSemester [[L.'8.1'][L.'8.2'][L.'8.3'][L.'8.4']
			  [L.'8.5'][L.'8.6'][L.'8.7.2'][L.'8.8']
			  [L.'8.9'][L.'8.10']
			 ]}

      %% Lectures for a professor must not overlap
      {ForAll Professors proc{$ L} {NoOverlapLectures L.lectures} end}

      %% At most MaximumRooms concurrent
      {AtMostLectures {FilterSize [big small tiny] FlatAllLectures}
       MaximumRooms}

      %% Aula and 155 lectures at most 2
      {AtMostLectures {FilterSize [big] FlatAllLectures} 2}

      %% Rooms Aula, 155, 152, 154, 250 lectures at most 5
      {AtMostLectures {FilterSize [big small] FlatAllLectures} 5}

      %% All professors have a teaching limit of 3 days per week
      {ForAll Professors
       proc{$ Professor} {ThreeDaysOnly Professor.lectures 3} end}

      %% At most 6 hours per day
      {ForAll Professors
       proc{$ Professor}
	  {ForAll [Monday Tuesday Wednesday Thursday Friday]
	   proc{$ Day}
	      {FoldL Professor.lectures
	       fun{$ I L}
		  {FD.plus {FD.times L.dur (L.start::Day)} I}
	       end 0} =<: 6*4
	   end}
       end}
	 
      %% Teacher1/Teacher15 couple cannot teach at the same time (+offset)
      {NotParallel
       Teacher1Off
       {SearchProf Professors 'Teacher1'}
       {SearchProf Professors 'Teacher15'}}
	 
      %% Special constraints for 2nd semester
      L.'2.1'.start=L.'2.2'.start=L.'2.3'.start
      L.'2.10.1'.start=L.'2.10.2'.start=L.'2.10.3'.start
      L.'2.15.1'.start=L.'2.15.2'.start=L.'2.15.3'.start=L.'2.15.4'.start 

      %% Special constraints for 4th semester
      {OnDifferentDays [L.'4.7.1' L.'4.7.2']}  % Teacher17's lecture
	 
      %% Special constraints for 6th semester
      L.'6.5'.start=L.'6.6'.start
      (L.'6.5'.start) >: {FD.max L.'6.2.1'.start L.'6.2.2'.start}

      L.'6.2.1'.start=L.'6.2.2'.start=L.'6.2.3'.start

      %% Special constraints for eighth semester

      %% Special constraints for Mediendidaktik
      {NoOverlapSemester [FlatGrundStudiumLectures FlatMedienLectures]}

      %% Special constraints for Fakultative Veranstaltungen
      {NoOverlapSemester FakLectures}
      {OnSpecialTimeOnly FlatFakLectures Afternoon}

      %% Special constraint for Teacher32
      {OnSameDay [L.'F.2.1' L.'F.2.2']}
	 
      %% %%%%%%%%%%%%%%%
      %% The Enumeration
      %% %%%%%%%%%%%%%%%

      {Enum FlatAllSemesterLectures}
      {Enum {Append FlatMedienLectures FlatFakLectures}}
   end
end  % end of function 'MakeProblem'      

ProblemDescription =
problem(
	 professors:
	    profs(
		   'Teacher1': inDays([monday tuesday wednesday])
		   'Teacher2'   : nil
		   'Teacher3'  : inDays([monday tuesday wednesday])
		   'Teacher4': weekInterval(11#00#16#15)
		   'Teacher5'  : inDays([monday tuesday wednesday])
		   'Teacher6'    : nil
		   'Teacher7'  : noT(inDays([monday]))
		   'Teacher8'  : fix(monday#8#15)
		   'Teacher9'   : nil
		   'Teacher10'     : inDays([monday tuesday])
		   'Teacher11': nil
		   'Teacher12' : oR(dayInterval(monday   # 8#00#12#00)
				   dayInterval(tuesday  # 8#00#12#00)
				   dayInterval(wednesday#13#00#16#15))
		   'Teacher13' : nil
		   'Teacher14'    : noT(inDays([monday wednesday]))
		   'Teacher15': inDays([monday tuesday wednesday])
		   'Teacher16'     : nil
		   'Teacher17' : nil
		   'Teacher18'    : nil
		   'Teacher19': weekInterval(12#45#16#15)
		   'Teacher20': nil
		   'Teacher21'	: nil
		   'Teacher22'	: nil
		   'Teacher23': nil
		   'Teacher24'	: nil
		   'Teacher25'	: nil
		   'Teacher26'	: nil
		   'Teacher27': nil
		   'Teacher28'	: nil
		   'Teacher29': nil
		   'Teacher30'	: nil
		   'Teacher31'	: nil
		   'Teacher32'	: nil
		   'Teacher33'	: nil
		   'Teacher34': nil
		 )

	 lectures:
	    lectures(second:
			semester( vm:
				     [
				       l(name:'2.1' dur:6 size:big 
					 professor:'Teacher1')
				       l(name:'2.2' dur:6 size:other
					 professor:'Teacher2')
				       l(name:'2.3' dur:6 size:other
					 professor:'Teacher3')
				     ]
				  v4:
				     [
				       l(name:'2.4.1' dur: 6 size:small
					 professor:'Teacher1')
				       l(name:'2.4.2' dur: 6 size:small
					 professor:'Teacher4')
				     ]
				  v5:
				     [
				       l(name:'2.5.1' dur: 6 size:small
					 professor:'Teacher5')
				       l(name:'2.5.2' dur: 6 size:small
					 professor:'Teacher3')
				     ]
				  v6:
				     [
				       l(name:'2.6' dur: 3 size:big
					 professor:'Teacher6'
					 constraints: fix(friday#8#15))
				     ]
				  v7:
				     [
				       l(name:'2.7' dur: 3 size:big
					constraints: fix(thursday#10#15)
					 professor:'Teacher7')
				     ]
				  v8:
				     [
				       l(name:'2.8.1' dur: 6 size:small
					 professor:'Teacher7')
				       l(name:'2.8.2' dur: 6 size:small
					 professor:'Teacher7')
				     ]
				  v9:
				     [
				       l(name:'2.9' dur: 6 size:big
					 professor:'Teacher8')
				     ]
				  v10:
				     [
				       l(name:'2.10.1' dur: 3 size:big
					 professor:'Teacher9')
				       l(name:'2.10.2' dur: 3 size:other
					 professor:'Teacher10')
				       l(name:'2.10.3' dur: 3 size:other
					 professor:'Teacher11')
				     ] 
				  v13:
				     [
				       l(name:'2.13.1' dur: 6 size:small
					 professor:'Teacher12')
				       l(name:'2.13.2' dur: 6 size:small
					 professor:'Teacher13')
				     ]
				  v14:
				     [
				       l(name:'2.14.1' dur: 6 size:tiny
					 professor:'Teacher14')
				       l(name:'2.14.2' dur: 6 size:tiny
					 professor:'Teacher14')
				     ]
				  v15:
				     [
				       l(name:'2.15.1' dur: 6 size:tiny
					 professor:'Teacher10')
				       l(name:'2.15.2' dur: 6 size:tiny
					 professor:'Teacher5')
				       l(name:'2.15.3' dur: 6 size:tiny
					 professor:'Teacher2')
				       l(name:'2.15.4' dur: 6 size:tiny
					 professor:'Teacher3')
				     ]
				)
		     fourth:
			semester( v1:	    
				     [
				       l(name:'4.1' dur: 6 size: big
					 professor:'Teacher5')
				     ]
				  v2:
				     [
				       l(name:'4.2.1' dur: 6 size: small
					 professor:'Teacher15')
				       l(name:'4.2.2' dur: 6 size: small
					 professor:'Teacher15')
				     ]
				  v3:
				     [
				       l(name:'4.3.1' dur: 3 size: small
					 professor:'Teacher1')
				       l(name:'4.3.2' dur: 3 size: small
					 professor:'Teacher1')
				     ]
				  v4:
				     [
				       l(name:'4.4.1' dur: 6 size: small
					 professor:'Teacher16')
				       l(name:'4.4.2' dur: 6 size: small
					 professor:'Teacher3')
				     ]
				  v5:
				     [
				       l(name:'4.5.1' dur: 6 size: small
					 professor:'Teacher7')
				       l(name:'4.5.2' dur: 6 size: small
					 professor:'Teacher7')
				     ]
				  v6:
				     [
				       l(name:'4.6' dur: 3 size: big
					 professor:'Teacher7')
				     ]
				  v7:
				     [
				       l(name:'4.7.1' dur: 6 size: small
					 professor:'Teacher17')
				       l(name:'4.7.2' dur: 6 size: small
					 professor:'Teacher17')
				     ]
				  v8:
				     [
				       l(name:'4.8.1' dur: 6 size: tiny
					 professor:'Teacher18')
				       l(name:'4.8.2' dur: 6 size: tiny
					 professor:'Teacher2')
				       l(name:'4.8.3' dur: 6 size: tiny
					 professor:'Teacher19')
				       l(name:'4.8.4' dur: 6 size: tiny
					 professor:'Teacher11')
				     ]
				  v10:
				     [
				       l(name:'4.10.1' dur: 6 size: small
					 professor:'Teacher1')
				       l(name:'4.10.2' dur: 6 size: small
					 professor:'Teacher1')
				     ]
				  v11:
				     [
				       l(name:'4.11' dur: 6 size: small
					 professor:'Teacher20')
				     ]
				  v12:
				     [
				       l(name:'4.12.1' dur: 6 size: small
					 professor:'Teacher14')
				       l(name:'4.12.2' dur: 6 size: small
					 professor:'Teacher14')
				     ]
				)
		     sixth:
			semester(
				  v2:
				     [
				       l(name:'6.2.1' dur: 6 size: small
					 professor:'Teacher16'
					 constraints:
					    dayInterval(wednesday#13#00#14#00))
				       l(name:'6.2.2' dur: 6 size: small
					 professor:'Teacher2'
					 constraints:
					    dayInterval(wednesday#13#00#14#00))
				       l(name:'6.2.3' dur: 6 size: small
					 professor:'Teacher26')
				     ]
				  v5:
				     [
				       l(name:'6.5' dur: 6 size: small
					 professor:'Teacher21')
				     ]
				  v6:
				     [
				       l(name:'6.6' dur: 6 size: small
					 professor:'Teacher7')
				     ]
				)
		     eighth:
			semester(
				  v1:
				     [
				       l(name:'8.1' dur: 6 size: big
					 professor:'Teacher1')
				     ]
				  v2:
				     [
				       l(name:'8.2' dur: 6 size: small
					 professor:'Teacher7')
				     ]
				  v3:
				     [
				       l(name:'8.3' dur: 6 size: small
					 professor:'Teacher3')
				     ]
				  v4:
				     [
				       l(name:'8.4' dur: 6 size: small
					 professor:'Teacher17')
				     ]
				  v5:
				     [
				       l(name:'8.5' dur: 6 size: small
					 professor:'Teacher23')
				     ]
				  v6:
				     [
				       l(name:'8.6' dur: 3 size: small
					 professor:'Teacher22')
				     ]
				  v7:
				     % l(name:'8.7.1' dur: 6 size: small
				     %   professor:'Hamm')
				  [
				    l(name:'8.7.2' dur: 6 size: tiny
				      professor:'Teacher2')
				  ]
				  v8:
				     [
				       l(name:'8.8' dur: 6 size: small
					 professor:'Teacher24')
				     ]
				  v9:
				     [
				       l(name:'8.9' dur: 6 size: big
					 professor:'Teacher28')
				     ]
				  v10:
				     [
				       l(name:'8.10' dur: 6 size: small
					 professor:'Teacher14')
				     ]
				  v11:
				     [
				       l(name:'8.11.1' dur: 3 size: tiny
					 professor:'Teacher11'
					 constraints:fix(tuesday#8#15))
				       l(name:'8.11.2' dur: 3 size: other
					 professor:'Teacher2'
					constraints:fix(tuesday#8#15))
				     ]
				  v12:
				     [
				       l(name:'8.12.1' dur: 6 size: tiny
					 professor:'Teacher2'
					 constraints:fix(tuesday#9#15))
				       l(name:'8.12.2' dur: 6 size: other
					 professor:'Teacher11'
					 constraints:fix(tuesday#9#15))
				     ]
				  v13:
				     [
				       l(name:'8.13.1' dur: 6 size: tiny
					 professor:'Teacher6')
				       l(name:'8.13.2' dur: 6 size: tiny
					 professor:'Teacher2'
					 constraints:fix(tuesday#11#15))
				       l(name:'8.13.3' dur: 6 size: other
					 professor:'Teacher11'
					 constraints:fix(tuesday#11#15))
				     ]
				  v14:
				     [
				       l(name:'8.14.1' dur: 3 size: tiny
					 professor:'Teacher9')
				       l(name:'8.14.2' dur: 3 size: tiny
					 professor:'Teacher27'
					 constraints:fix(tuesday#8#15))
				       l(name:'8.14.3' dur: 3 size: other
					 professor:'Teacher29'
					 constraints:fix(tuesday#8#15))
				     ]
				  v15:
				     [
				       l(name:'8.15.1' dur: 6 size: tiny
					 professor:'Teacher9'
					 constraints:fix(tuesday#9#15))
				       l(name:'8.15.2' dur: 6 size: other
					 professor:'Teacher27'
					 constraints:fix(tuesday#9#15))
				     ]
				  v16:
				     [
				       l(name:'8.16.1' dur: 6 size: tiny
					 professor:'Teacher9'
					 constraints:fix(tuesday#11#15))
				       l(name:'8.16.2' dur: 6 size: other
					 professor:'Teacher27'
					 constraints:fix(tuesday#11#15))
				       l(name:'8.16.3' dur: 6 size: tiny
					 professor:'Teacher29')
				     ]
				  v17:
				     [
				       l(name:'8.17.1' dur: 3 size: small
					 professor:'Teacher7')
				       l(name:'8.17.2' dur: 3 size: small
					 professor:'Teacher5'
					 constraints:fix(tuesday#8#15))
				       l(name:'8.17.3' dur: 3 size: other
					 professor:'Teacher3'
					 constraints:fix(tuesday#8#15))
				     ]
				  v18:
				     [
				       l(name:'8.18.1' dur: 6 size: small
					 professor:'Teacher5'
					 constraints:fix(tuesday#9#15))
				       l(name:'8.18.2' dur: 6 size: other
					 professor:'Teacher3'
					 constraints:fix(tuesday#9#15))
				     ]
				  v19:
				     [
				       l(name:'8.19.1' dur: 6 size: small
					 professor:'Teacher7')
				       l(name:'8.19.2' dur: 6 size: other
					 professor:'Teacher5'
					 constraints:fix(tuesday#11#15))
				       l(name:'8.19.3' dur: 6 size: small
					 professor:'Teacher3'
					 constraints:fix(tuesday#11#15))
				     ]
				)
		     medien:
			lectures(
				  v1:
				     [
				       l(name:'M.1' dur: 3 size: other
					 professor:'Teacher30'
					 constraints:fix(tuesday#14#00))
				     ]
				  v8:
				     [
				       l(name:'M.8' dur: 3 size: other
					 professor:'Teacher31'
					 constraints:fix(thursday#16#00))
				     ]
				)
		     fac:
			lectures(
				  v1:
				     [
				       l(name:'F.1' dur: 3 size: small
					 professor:'Teacher5'
					 constraints:fix(monday#16#00))
				     ]
				  v2:
				     [
				       l(name:'F.2.1' dur: 6 size: small
					 professor:'Teacher32')
				       l(name:'F.2.2' dur: 6 size: small
					 professor:'Teacher32')
				     ]
				  v3:
				     [
				       l(name:'F.3' dur: 6 size: small
					 professor:'Teacher12')
				     ]
				  v4:
				     [
				       l(name:'F.4' dur: 6 size: small
					 professor:'Teacher12')
				     ]
				  %% Gitarre is during lunch: omitted here
				  v6:
				     [
				       l(name:'F.6' dur: 6 size: small
					 professor:'Teacher9')
				     ]
				  %% Erlebnis during weekend :-}
				  v10:
				     [
				       l(name:'F.10' dur: 6 size: other
					 professor:'Teacher25')
				     ]
				)
)) 

fun {MakeSearch}
   {New
    Search.object script({MakeProblem ProblemDescription}
			 proc{$ Old New}
			    CN = {Cost New}
			    CO = {Cost Old} in
			    CN <: CO
/*
			    thread
			       {Wait CO}
			       {Show {FD.reflect.min CO}}
			    end
*/
			 end
			 rcd : 30
			 %% rcd=20 3:18.89
			 %% rcd=25 4:30.95
			 %% rcd=28 2:21.88
			 %% rcd=29 2:09.43
			 %% rcd=30 2:25.16
			)}
end

CollegeSol =
[[l(dur:3 name:'2.10.1' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher9' semester:second size:big start:24) l(dur:3 name:'2.10.2' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher10' semester:second size:other start:24) l(dur:3 name:'2.10.3' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher11' semester:second size:other start:24) l(dur:6 name:'2.13.1' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher12' semester:second size:small start:37) l(dur:6 name:'2.13.2' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher13' semester:second size:small start:81) l(dur:6 name:'2.14.1' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher14' semester:second size:tiny start:37) l(dur:6 name:'2.14.2' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher14' semester:second size:tiny start:45) l(dur:6 name:'2.15.1' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher10' semester:second size:tiny start:9) l(dur:6 name:'2.15.2' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher5' semester:second size:tiny start:9) l(dur:6 name:'2.15.3' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher2' semester:second size:tiny start:9) l(dur:6 name:'2.15.4' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher3' semester:second size:tiny start:9) l(dur:6 name:'2.4.1' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher1' semester:second size:small start:73) l(dur:6 name:'2.4.2' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher4' semester:second size:small start:48) l(dur:6 name:'2.5.1' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher5' semester:second size:small start:64) l(dur:6 name:'2.5.2' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher3' semester:second size:small start:64) l(constraints:fix(friday#8#15) dur:3 name:'2.6' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher6' semester:second size:big start:145) l(constraints:fix(thursday#10#15) dur:3 name:'2.7' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher7' semester:second size:big start:117) l(dur:6 name:'2.8.1' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher7' semester:second size:small start:73) l(dur:6 name:'2.8.2' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher7' semester:second size:small start:81) l(dur:6 name:'2.9' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher8' semester:second size:big start:1) l(dur:6 name:'2.1' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher1' semester:second size:big start:28) l(dur:6 name:'2.2' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher2' semester:second size:other start:28) l(dur:6 name:'2.3' ordering:[1#18 19#36 55#72 37#54 73#90 91#108 145#162 163#180 109#126 127#144] professor:'Teacher3' semester:second size:other start:28) l(dur:6 name:'4.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher5' semester:fourth size:big start:81) l(dur:6 name:'4.10.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher1' semester:fourth size:small start:46) l(dur:6 name:'4.10.2' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher1' semester:fourth size:small start:64) l(dur:6 name:'4.11' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher20' semester:fourth size:small start:1) l(dur:6 name:'4.12.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher14' semester:fourth size:small start:64) l(dur:6 name:'4.12.2' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher14' semester:fourth size:small start:109) l(dur:6 name:'4.2.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher15' semester:fourth size:small start:96) l(dur:6 name:'4.2.2' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher15' semester:fourth size:small start:37) l(dur:3 name:'4.3.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher1' semester:fourth size:small start:105) l(dur:3 name:'4.3.2' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher1' semester:fourth size:small start:9) l(dur:6 name:'4.4.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher16' semester:fourth size:small start:24) l(dur:6 name:'4.4.2' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher3' semester:fourth size:small start:73) l(dur:6 name:'4.5.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher7' semester:fourth size:small start:37) l(dur:6 name:'4.5.2' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher7' semester:fourth size:small start:45) l(dur:3 name:'4.6' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher7' semester:fourth size:big start:121) l(dur:6 name:'4.7.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher17' semester:fourth size:small start:24) l(dur:6 name:'4.7.2' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher17' semester:fourth size:small start:109) l(dur:6 name:'4.8.1' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher18' semester:fourth size:tiny start:13) l(dur:6 name:'4.8.2' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher2' semester:fourth size:tiny start:73) l(dur:6 name:'4.8.3' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher19' semester:fourth size:tiny start:96) l(dur:6 name:'4.8.4' ordering:[73#90 91#108 37#54 55#72 1#18 19#36 109#126 127#144 145#162 163#180] professor:'Teacher11' semester:fourth size:tiny start:9) l(constraints:dayInterval(wednesday#13#0#14#0) dur:6 name:'6.2.1' ordering:[73#90 91#108 145#162 163#180 109#126 127#144 1#18 19#36 37#54 55#72] professor:'Teacher16' semester:sixth size:small start:92) l(constraints:dayInterval(wednesday#13#0#14#0) dur:6 name:'6.2.2' ordering:[73#90 91#108 145#162 163#180 109#126 127#144 1#18 19#36 37#54 55#72] professor:'Teacher2' semester:sixth size:small start:92) l(dur:6 name:'6.2.3' ordering:[73#90 91#108 145#162 163#180 109#126 127#144 1#18 19#36 37#54 55#72] professor:'Teacher26' semester:sixth size:small start:92) l(dur:6 name:'6.5' ordering:[73#90 91#108 145#162 163#180 109#126 127#144 1#18 19#36 37#54 55#72] professor:'Teacher21' semester:sixth size:small start:100) l(dur:6 name:'6.6' ordering:[73#90 91#108 145#162 163#180 109#126 127#144 1#18 19#36 37#54 55#72] professor:'Teacher7' semester:sixth size:small start:100) l(dur:6 name:'8.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher1' semester:eighth size:big start:1) l(dur:6 name:'8.10' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher14' semester:eighth size:small start:117) l(constraints:fix(tuesday#8#15) dur:3 name:'8.11.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher11' semester:eighth size:tiny start:37) l(constraints:fix(tuesday#8#15) dur:3 name:'8.11.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher2' semester:eighth size:other start:37) l(constraints:fix(tuesday#9#15) dur:6 name:'8.12.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher2' semester:eighth size:tiny start:41) l(constraints:fix(tuesday#9#15) dur:6 name:'8.12.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher11' semester:eighth size:other start:41) l(dur:6 name:'8.13.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher6' semester:eighth size:tiny start:109) l(constraints:fix(tuesday#11#15) dur:6 name:'8.13.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher2' semester:eighth size:tiny start:49) l(constraints:fix(tuesday#11#15) dur:6 name:'8.13.3' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher11' semester:eighth size:other start:49) l(dur:3 name:'8.14.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher9' semester:eighth size:tiny start:109) l(constraints:fix(tuesday#8#15) dur:3 name:'8.14.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher27' semester:eighth size:tiny start:37) l(constraints:fix(tuesday#8#15) dur:3 name:'8.14.3' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher29' semester:eighth size:other start:37) l(constraints:fix(tuesday#9#15) dur:6 name:'8.15.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher9' semester:eighth size:tiny start:41) l(constraints:fix(tuesday#9#15) dur:6 name:'8.15.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher27' semester:eighth size:other start:41) l(constraints:fix(tuesday#11#15) dur:6 name:'8.16.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher9' semester:eighth size:tiny start:49) l(constraints:fix(tuesday#11#15) dur:6 name:'8.16.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher27' semester:eighth size:other start:49) l(dur:6 name:'8.16.3' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher29' semester:eighth size:tiny start:109) l(dur:3 name:'8.17.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher7' semester:eighth size:small start:140) l(constraints:fix(tuesday#8#15) dur:3 name:'8.17.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher5' semester:eighth size:small start:37) l(constraints:fix(tuesday#8#15) dur:3 name:'8.17.3' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher3' semester:eighth size:other start:37) l(constraints:fix(tuesday#9#15) dur:6 name:'8.18.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher5' semester:eighth size:small start:41) l(constraints:fix(tuesday#9#15) dur:6 name:'8.18.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher3' semester:eighth size:other start:41) l(dur:6 name:'8.19.1' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher7' semester:eighth size:small start:109) l(constraints:fix(tuesday#11#15) dur:6 name:'8.19.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher5' semester:eighth size:other start:49) l(constraints:fix(tuesday#11#15) dur:6 name:'8.19.3' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher3' semester:eighth size:small start:49) l(dur:6 name:'8.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher7' semester:eighth size:small start:132) l(dur:6 name:'8.3' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher3' semester:eighth size:small start:81) l(dur:6 name:'8.4' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher17' semester:eighth size:small start:73) l(dur:6 name:'8.5' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher23' semester:eighth size:small start:109) l(dur:3 name:'8.6' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher22' semester:eighth size:small start:140) l(dur:6 name:'8.7.2' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher2' semester:eighth size:tiny start:100) l(dur:6 name:'8.8' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher24' semester:eighth size:small start:24) l(dur:6 name:'8.9' ordering:[109#126 127#144 91#108 73#90 19#36 1#18 55#72 37#54 145#162 163#180] professor:'Teacher28' semester:eighth size:big start:9) l(constraints:fix(tuesday#14#0) dur:3 name:'M.1' ordering:[127#144 55#72 37#54 109#126 73#90 91#108 1#18 19#36 145#162 163#180] professor:'Teacher30' semester:medien size:other start:60) l(constraints:fix(thursday#16#0) dur:3 name:'M.8' ordering:[127#144 55#72 37#54 109#126 73#90 91#108 1#18 19#36 145#162 163#180] professor:'Teacher31' semester:medien size:other start:140) l(constraints:fix(monday#16#0) dur:3 name:'F.1' ordering:[73#90 91#108 109#126 127#144 1#18 19#36 145#162 163#180 37#54 55#72] professor:'Teacher5' semester:fac size:small start:32) l(dur:6 name:'F.10' ordering:[73#90 91#108 109#126 127#144 1#18 19#36 145#162 163#180 37#54 55#72] professor:'Teacher25' semester:fac size:other start:135) l(dur:6 name:'F.2.1' ordering:[73#90 91#108 109#126 127#144 1#18 19#36 145#162 163#180 37#54 55#72] professor:'Teacher32' semester:fac size:small start:163) l(dur:6 name:'F.2.2' ordering:[73#90 91#108 109#126 127#144 1#18 19#36 145#162 163#180 37#54 55#72] professor:'Teacher32' semester:fac size:small start:171) l(dur:6 name:'F.3' ordering:[73#90 91#108 109#126 127#144 1#18 19#36 145#162 163#180 37#54 55#72] professor:'Teacher12' semester:fac size:small start:92) l(dur:6 name:'F.4' ordering:[73#90 91#108 109#126 127#144 1#18 19#36 145#162 163#180 37#54 55#72] professor:'Teacher12' semester:fac size:small start:100) l(dur:6 name:'F.6' ordering:[73#90 91#108 109#126 127#144 1#18 19#36 145#162 163#180 37#54 55#72] professor:'Teacher9' semester:fac size:small start:127)]]

Return=
   fd([college([
		first_sol(equal(fun {$}
				   SO = {MakeSearch}
				in
				   {SO next($)}
				end
				CollegeSol)
			  keys: [fd pel scheduling])
		first_sol_entailed(entailed(proc {$}
					       SO = {MakeSearch}
					    in {SO next(_)}
					    end)
				   keys: [fd entailed pel scheduling])
		third_sol_twice(equal(fun {$}
					 SO1 = {MakeSearch}
					 SO2 = {MakeSearch}
					 {SO1 next(_)}
					 {SO1 next(_)}
					 {SO2 next(_)}
					 {SO2 next(_)}
					 Sol1 = {SO1 next($)}
					 Sol2 = {SO2 next($)}
				      in
					 cond Sol1 = Sol2 then yes else no end
				      end
				yes)
			  keys: [fd pel scheduling])
	       ])
      ])
end


