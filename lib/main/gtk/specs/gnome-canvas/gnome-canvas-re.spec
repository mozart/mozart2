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
     { name  => 'GnomeCanvasRE',

       super => 'GnomeCanvasItem',

       args  => { 'x1'                            => 'gdouble',
                  'y1'                            => 'gdouble',
                  'x2'                            => 'gdouble',
                  'y2'                            => 'gdouble',
                  'fill_color'                    => 'gchar*',
                  'fill_color_gdk'                => '!GdkColor',
                  'fill_color_rgba'               => 'guint',
                  'outline_color'                 => 'gchar*',
                  'outline_color_gdk'             => '!Gdkcolor',
                  'outline_color_rgba'            => 'guint',
                  'fill_stipple'                  => '!GdkWindow',
                  'outline_stipple'               => '!GdkWindow',
                  'width_pixels'                  => 'guint',
                  'width_units'                   => 'gdouble' } }
     );
