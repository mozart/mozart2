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
     { name  => 'GnomeCanvas',

       super => 'GtkLayout',

       inits => { 'gnome_canvas_new'                        => { out => 'GtkWidget*' },
                  'gnome_canvas_new_aa'                     => { out => 'GtkWidget*' } },

       meths => { 'gnome_canvas_root'                       => { in  => ['GnomeCanvas*'],
                                                                 out => '!GnomeCanvasGroup*' },
                  'gnome_canvas_set_scroll_region'          => { in  => ['GnomeCanvas*',
                                                                         'double',
                                                                         'double',
                                                                         'double',
                                                                         'double'] },
                  'gnome_canvas_get_scroll_region'          => { in  => ['GnomeCanvas*',
                                                                         '+double',
                                                                         '+double',
                                                                         '+double',
                                                                         '+double'] },
                  'gnome_canvas_set_pixels_per_unit'        => { in  => ['GnomeCanvas*',
                                                                         'double'] },
                  'gnome_canvas_scroll_to'                  => { in  => ['GnomeCanvas*',
                                                                         'int',
                                                                         'int'] },
                  'gnome_canvas_get_scroll_offsets'         => { in  => ['GnomeCanvas*',
                                                                         '+int*',
                                                                         '+int*'] },
                  'gnome_canvas_update_now'                 => { in  => ['GnomeCanvas*'] },
                  'gnome_canvas_get_item_at'                => { in  => ['GnomeCanvas*',
                                                                         'double',
                                                                         'double'],
                                                                 out => '!GnomeCanvasItem*' },
                  'gnome_canvas_request_redraw_uta'         => { in  => ['GnomeCanvas*',
                                                                         '!ArtUta*'] },
                  'gnome_canvas_request_redraw'             => { in  => ['GnomeCanvas*',
                                                                         'int',
                                                                         'int',
                                                                         'int',
                                                                         'int'] },
                  'gnome_canvas_w2c_affine'                 => { in  => ['GnomeCanvas*',
                                                                         'double[6]'] },
                  'gnome_canvas_w2c'                        => { in  => ['GnomeCanvas*',
                                                                         'double',
                                                                         'double',
                                                                         '+int*',
                                                                         '+int*'] },
                  'gnome_canvas_w2c_d'                      => { in  => ['GnomeCanvas*',
                                                                         'double',
                                                                         'double',
                                                                         '+double*',
                                                                         '+double*'] },
                  'gnome_canvas_c2w'                        => { in  => ['GnomeCanvas*',
                                                                         'int',
                                                                         'int',
                                                                         '+double*',
                                                                         '+double*'] },
                  'gnome_canvas_window_to_world'            => { in  => ['GnomeCanvas*',
                                                                         'double',
                                                                         'double',
                                                                         '+double*',
                                                                         '+double*'] },
                  'gnome_canvas_world_to_window'            => { in  => ['GnomeCanvas*',
                                                                         'double',
                                                                         'double',
                                                                         '+double*',
                                                                         '+double*'] },
                  'gnome_canvas_get_color'                  => { in  => ['GnomeCanvas*',
                                                                         'const char*',
                                                                         '!+GdkColor*'],
                                                                 out => 'int' },
                  'gnome_canvas_set_stipple_origin'         => { in  => ['GnomeCanvas*',
                                                                         '!GdkGC*'] } }}
                  );
