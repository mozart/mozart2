# -*-perl-*-

# Authors:
#   Andreas Simon (2000)
#
# Copyright:
#   Andreas Simon (2000)
#
# Last change:
#   $Date$ by $Author$
#   $Revision$
#
# This file is part of Mozart, an implementation
# of Oz 3:
#   http://www.mozart-oz.org
#
# See the file "LICENSE" or
#   http://www.mozart-oz.org/LICENSE.html
# for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL
# WARRANTIES.
#

$class =
    (
     { name  => 'GnomeCanvasWidget',

       super => 'GnomeCanvasItem',

       args  => { 'widget'                        => '!GtkObject',
                  'x'                             => 'gdouble',
                  'y'                             => 'gdouble',
                  'width'                         => 'gdouble',
                  'height'                        => 'gdouble',
                  'anchor'                        => '%GtkAnchorType',
                  'size_pixels'                   => 'gboolean' } }
     );
