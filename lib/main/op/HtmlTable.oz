%%%
%%% Author:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   fun {NewTagTest T}
      TAGS={List.toRecord tags
            {Map {Record.toList T} fun {$ A} A#unit end}}
   in
      fun {$ T}
         {HasFeature TAGS T}
      end
   end

   IsTag =
   {NewTagTest tags(a abbr acronym address applet area
                    b base basefont bdo big blockquote 'body' br button
                    caption center cite code col colgroup
                    dd del dfn dir 'div' dl dt
                    em
                    fieldset font form frame frameset
                    h1 h2 h3 h4 h5 h6 head hr html
                    i iframe img input ins isindex
                    kbd
                    label legend li link
                    map menu meta
                    noframes noscript
                    object ol optgroup option
                    p param pre
                    q
                    s samp script select small span strike strong
                    style sub sup
                    table tbody td textarea tfoot th thead title tr tt
                    u ul
                    var)}

   IsNonFinalTag =
   {NewTagTest tags(area
                    base basefont br
                    col
                    frame
                    hr
                    img input isindex
                    link
                    meta
                    param)}

   IsNlTag =
   {NewTagTest tags(blockquote 'body'
                    center
                    h1 h2 h3 h4 h5 h6 head html
                    map menu
                    p pre
                    table td th title)}

in

   HtmlTable = html(isTag:         IsTag
                    isNonFinalTag: IsNonFinalTag
                    isNlTag:       IsNlTag)

end
