fun {$ IMPORT}
   \insert '../lib/import.oz'

   proc {Color ?EC}
      Germany
      France
      Belgium
      Netherlands
      Spain
      Portugal
      Luxemburg
      Denmark
      Italy
      England
      Greece
   in
      map(germany:     Germany
          france:      France
          belgium:     Belgium
          netherlands: Netherlands
          spain:       Spain
          portugal:    Portugal
          luxemburg:   Luxemburg
          denmark:     Denmark
          italy:       Italy
          england:     England
          greece:      Greece) = EC
      {Record.forAll EC proc {$ Country} Country :: 0#3 end}
      Netherlands \=: Germany
      France   \=:    Germany
      Belgium  \=:    Germany
      Luxemburg \=:   Germany
      Denmark   \=:   Germany
      Belgium   \=:   France
      Luxemburg \=:   France
      Spain     \=:   France
      Italy     \=:   France
      Netherlands\=:  Belgium
      Portugal   \=:  Spain
      {FD.distribute ff EC}
   end

   ColorSol =
   [map(
        belgium:0
        denmark:0
        england:0
        france:1
        germany:2
        greece:0
        italy:0
        luxemburg:0
        netherlands:1
        portugal:1
        spain:0)]
in

   fd([color([one(equal(fun {$}
                           {SearchOne Color}
                        end
                        ColorSol)
                  keys: [fd])
             ])
      ])

end
