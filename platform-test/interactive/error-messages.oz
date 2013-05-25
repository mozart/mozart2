%%
%% Examples for kernel errors
%% ==========================
%%

thread raise error(kernel(type a [b c d] int 1 "hello")) end end

thread a+1=_ end

thread raise error(kernel(apply a [b c d])) end end

thread {{fun {$} 1 end} hi} end

thread raise error(kernel(arity Show [b c d])) end end

thread {{fun {$} Show end} hi ho} end

thread raise error(kernel('.' f(a) b)) end end

thread f.a = _ end

thread raise error(kernel(noElse 1)) end end	  
thread raise error(kernel(noElse 1 b)) end end

thread case false then skip end end

thread raise error(kernel(div0 1)) end end

thread 2 mod 0 = _ end 

thread raise error(kernel(mod0 2)) end end

thread 2 div 0 = _ end 

thread raise error(kernel(dict {NewDictionary} a)) end end

thread raise error(kernel(array {NewArray 0 10 1} 17)) end end

thread raise error(kernel(stringNoFloat "hallo")) end end
thread raise error(kernel(stringNoInt "hallo")) end end
thread raise error(kernel(stringNoInt "hallo")) end end
thread raise error(kernel(stringNoAtom "123")) end end
thread raise error(kernel(stringNoValue "a b c")) end end

thread {System.virtualStringToValue "a b c" _} end

thread raise error(kernel(globalState array)) end end
thread raise error(kernel(globalState dict)) end end
thread raise error(kernel(globalState cell)) end end
thread raise error(kernel(globalState io)) end end
thread raise error(kernel(globalState object)) end end
thread raise error(kernel(globalState 'other weird things')) end end

thread raise error(kernel(spaceMerged {Space.new proc {$ X} skip end})) end end
thread raise error(kernel(spaceMerged {Space.new proc {$ X} skip end})) end end
thread raise error(kernel(spaceParent {Space.new proc {$ X} skip end})) end end
thread raise error(kernel(spaceSuper {Space.new proc {$ X} skip end})) end end
thread raise error(kernel(spaceNoChoices)) end end

%%
%% Examples for failures
%% =====================
%% 

thread 1 = 2 end
thread f^a = _ end

thread raise failure(debug:d(info:'fail')) end end
thread raise failure(debug:d(info:apply('FD.plus' [a b c]))) end end
thread raise {Exception.failure apply(a [b c d])} end end
thread raise failure(debug:d(info:eq(a b)))  end end
thread raise failure(debug:d(info:tell(a b))) end end
thread raise {Exception.failure tell(a b)} end end

%%
%% Examples for object errors
%% ==========================
%%

thread raise error(object('<-' f(a) b _)) end end
thread raise error(object('@' f(b) c)) end end
thread raise error(object(internalErrorInheritance)) end end
thread raise error(object(inheritanceUnderspecifiedSharing a b attribute d)) end end
thread raise error(object(inheritanceUnderspecifiedOrder [a#b c#d])) end end
thread raise error(object(messageSend endingLookupNoOtherwise a f(b))) end end
thread raise error(object(methodApplicationLookupNoOtherwise a f(b))) end end
thread raise error(object(methodApplicationLookupOtherwise a f(b))) end end
thread raise error(object(arityMismatchDefaultMethod l)) end end
thread raise error(object(slaveNotFree)) end end
thread raise error(object(slaveAlreadyFree)) end end
thread raise system(object(locking {New BaseObject noop})) end end

%%
%% Examples for record errors
%% ==========================
%%

thread raise error(record(width a [b c d] 17 "hello")) end end

%%
%% Examples for fd errors
%% ==========================
%%
thread raise error(fd(scheduling a [b c s] fdint 5 "hello")) end end
thread raise error(fd(noChoice a [b c d] 17 "hello")) end end

%%
%% Examples for system errors
%% ==========================
%%
thread raise error(system(limitInternal "Float overflow")) end end
thread raise error(system(limitInternal "Non-determined exception thread raised")) end end
thread raise error(system(limitExternal "Communication Problem")) end end

%%
%% Examples for open progr errors
%% ==========================
%%
thread raise system(os(os 17 "hello")) end end

%%
%% Examples for tk errors 
%% ==========================
%%
thread raise error(tk(alreadyInitialized {New Tk.toplevel tkInit} gargel)) end end

thread {Foreign.loaf [x] _} end
thread {Foreign.load [x] _} end
thread {Foreign.load [x] _ _} end