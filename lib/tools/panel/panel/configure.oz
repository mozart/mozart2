%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
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

Pad            = 4

MegaByteF      = 1024.0 * 1024.0
KiloByteI      = 1024
MegaByteI      = KiloByteI * KiloByteI

LineColor        #
RunnableColor    # RunnableStipple  #
ThresholdColor   # ThresholdStipple #
SizeColor        # SizeStipple      #
ActiveColor      # ActiveStipple    #
TimeColors       # TimeStipple      #
AboutColor       # CurLoadColor     =
if Tk.isColor then
   gray80 #
   lightslateblue   # '' #
   lightslateblue   # '' #
   mediumvioletred  # '' #
   mediumaquamarine # '' #
   color(run:  yellow4
	 'prop': mediumvioletred
	 copy: mediumaquamarine
	 gc:   mediumseagreen) #
   stipple(run:    ''
	   'prop': ''
	   copy:   ''
	   gc:     '') #
   blue #
   lightslateblue
else
   fun {Bitmap V}
      '@'#{Tk.localize BitmapUrl#V#'.xbm'}
   end
in
   black #
   black # {Bitmap 'grid-50'} #
   black # {Bitmap 'grid-25'} #
   black # {Bitmap 'grid-50'} #
   black # '' #
   color(run:    black
	 'prop': black
	 copy:   black
	 gc:     black) #
   stipple(run:    {Bitmap 'grid-25'}
	   'prop': {Bitmap 'grid-50'}
	   copy:   {Bitmap 'lines-lr'}
	   gc:     {Bitmap 'lines-rl'}) #
   black #
   black
end

AboutFont = '-Adobe-times-bold-r-normal--*-240*'

TitleName = 'Oz Panel'

UpdateTimes         = [500   # '500ms'
		       1000  # '1s'
		       5000  # '5s'
		       10000 # '10s']
DefaultUpdateTime   = 1000

HistoryRanges       = [10000  # '10s'
		       30000  # '30s'
		       60000  # '1m'
		       120000 # '2m']
DefaultHistoryRange = 60000

LoadWidth           = 240

BoldFontFamily   = '-*-helvetica-bold-r-normal--*-'
MediumFontFamily = '-*-helvetica-medium-r-normal--*-'
FontMatch        = '-*-*-*-*-*-*'
BoldFont         = BoldFontFamily   # 120 # FontMatch
MediumFont       = MediumFontFamily # 120 # FontMatch

ZeroTime     = time(copy:      0
		    gc:        0
		    propagate: 0
		    run:       0
		    system:    0
		    user:      0
		    total:     0)
