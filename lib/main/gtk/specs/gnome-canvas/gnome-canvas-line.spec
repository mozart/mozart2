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
     { name  => 'GnomeCanvasLine',

       super => 'GnomeCanvasItem',

       args  => { 'fill_color'                    => 'gchar*',
                  'fill_color_gdk'                => '!GdkColor',
                  'fill_color_rgba'               => 'guint',
                  'fill_stipple'                  => '!GdkWindow',
                  'width_pixels'                  => 'guint',
                  'width_units'                   => 'gdouble',
                  'cap_style'                     => '%GdkCapStyle',
                  'join_style'                    => '%GdkJoinStyle',
                  'line_style'                    => '%GdkLineStyle',
                  'first_arrowhead'               => 'gboolean',
                  'last_arrowhead'                => 'gboolean',
                  'smooth'                        => 'gboolean',
                  'spline_steps'                  => 'guint',
                  'arrow_shape_a'                 => 'gdouble',
                  'arrow_shape_b'                 => 'gdouble',
                  'arrow_shape_c'                 => 'gdouble' } }
     );
