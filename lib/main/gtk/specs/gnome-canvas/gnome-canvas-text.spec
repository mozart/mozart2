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
     { name  => 'GnomeCanvasText',

       super => 'GnomeCanvasItem',

       args  => { 'text'                          => 'gchar*',
                  'x'                             => 'gdouble',
                  'y'                             => 'gdouble',
                  'font'                          => 'gchar*',
                  'fontset'                       => 'gchar*',
                  'font_gdk'                      => '!GdkFont',
                  'anchor'                        => '%GtkAnchorType',
                  'justification'                 => '%GtkJustification',
                  'clip_width'                    => 'gdouble',
                  'clip_height'                   => 'gdouble',
                  'clip'                          => 'gboolean',
                  'x_offset'                      => 'gdouble',
                  'y_offset'                      => 'gdouble',
                  'fill_color'                    => 'gchar*',
                  'fill_color_gdk'                => '!GdkColor',
                  'fill_color_rgba'               => 'guint',
                  'fill_stipple'                  => '!GdkWindow',
                  'text_width'                    => 'gdouble',
                  'text_heigth'                   => 'gdouble' } }
     );
