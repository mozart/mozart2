%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1997-1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% Sample Area
%%%

%% Watch FD Propagators

declare X Y Z

{Inspect [X Y Z]}

X :: 1#13
Y :: 0#27
Z :: 1#12

2*Y =: Z

X <: Y

Z <: 7

X \=: 1

%% Watch Feature Constraints

declare X Y Z F

{Inspect X}

{Record.tell estoril X}

X^food = fish

X^F = Y

F = weather

X^country = portugal

{WidthC X 3}

Y = tuple(1 2 3)

Y = X %% Different result depending on treeDisplayMode

%% Exponential Growth

declare T A B C D E

{Inspect T}

T = t(A A A A)
A = t(B B B B)
B = t(C C C C)
C = t(D D D D)
D = t(E E E E)
E = 5

%% "Pseudo Arrays"

declare X Y

X = {MakeTuple big_tuple 100}
Y = {MakeTuple lines 100}

{For 1 100 1 proc {$ I} Y.I = I end}
{For 1 100 1 proc {$ I} X.I = Y end}

{Inspect X}

%% Array Stuff

declare A B C

{Inspect A}

A = {NewArray 1 100 B}
B = {NewArray 1 100 C}
C = 1

%% Cycle Mode Stuff
%% perform Options/Preferences treeDisplayNode cycle set

declare U V W X Y Z

{Inspect U}

U = [V W X Y]
V = [V]
W = [V W]
X = [V W X]
Y = U

declare X Y Z

{Inspect X}

X = Y|Z|X
Y = 1|Y
Z = X
