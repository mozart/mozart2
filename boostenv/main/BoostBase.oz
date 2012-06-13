functor

require
   Boot_OS at 'x-oz://boot/OS'

prepare

   OS = os(rand:       Boot_OS.rand
           srand:      Boot_OS.srand
           randLimits: Boot_OS.randLimits)

end
