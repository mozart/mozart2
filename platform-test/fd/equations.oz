fun {$ IMPORT}
   \insert '../lib/import.oz'

   EqSol1 = [3]
   EqSol2 = [7#5#2]
in
   fd([equations([
                  test1(equal(fun {$}
                                 {SearchOne proc{$ X} X :: 1#10 27 =: X*X*X
                                               {FD.distribute ff [X]} end}
                              end

                              EqSol1)
                        keys: [fd])
                  test2(equal(fun {$}
                                 {SearchOne proc{$ S} X Y Z in
                                               S = X#Y#Z
                                               [X Y Z] = {FD.dom 1#10 }
                                               176 =: X*X + Y*Y*Y + Z
                                               {FD.distribute split [X Y Z]}
                                            end}

                              end
                              EqSol2)
                        keys: [fd])
                 ])
      ])

end
