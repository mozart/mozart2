functor

import
   System(show:Show)
   OS at 'x-oz://system/OS.ozf'

define

   {Show 'Hello world!'}
   {OS.fwrite OS.stdout {Append "Hello world!" [10]} _}

end
