functor
import
   System
   Property
export
   Return
define
   Return =
   gc2([changingLimits(proc {$}
			  % Do not depend on initial threshold
			  {System.gcDo}

			  Min={Property.get 'gc.min'}
			  Max={Property.get 'gc.max'}
			  Threshold={Property.get 'gc.threshold'}
			  NewMax=Threshold
			  NewMin=Threshold-1
		       in
			  {Property.put 'gc.max' 0} % no-op
			  {Property.get 'gc.max'} = Max

			  {Property.put 'gc.max' Min-1} % no-op
			  {Property.get 'gc.max'} = Max

			  {Property.put 'gc.min' 0} % no-op
			  {Property.get 'gc.min'} = Min

			  {Property.put 'gc.min' Max+1} % no-op
			  {Property.get 'gc.min'} = Min

			  {Property.put 'gc.min' NewMin}
			  {Property.get 'gc.min'} = NewMin

			  {Property.put 'gc.max' NewMax}
			  {Property.get 'gc.max'} = NewMax
			  {Property.get 'gc.threshold'} < Threshold = true
			  {System.gcDo}

			  % restore
			  {Property.put 'gc.max' Max}
			  {Property.put 'gc.min' Min}
			  {System.gcDo}
		       end
		       keys:[gc])
       ])
end
