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
     { name  => 'GnomeCanvasItem',

       super => 'GtkObject',

       inits => { 'gnome_canvas_item_new'                   => { in  => ['!GnomeCanvasGroup*',
                                                                         'GtkType',
                                                                         'const gchar*',
                                                                         '...'],
                                                                 out => 'GnomeCanvasItem*' },
                  'gnome_canvas_item_newv'                  => { in  => ['!GnomeCanvasGroup*',
                                                                         'GtkType',
                                                                         'guint',
                                                                         'GtkArg*'],
                                                                 out => 'GnomeCanvasItem*' } },
       meths => { 'gnome_canvas_item_set'                   => { in  => ['GnomeCanvasItem*',
                                                                         'const gchar*',
                                                                         '...'] },
                  'gnome_canvas_item_setv'                  => { in  => ['GnomeCanvasItem*',
                                                                         'guint',
                                                                         'GtkArg*'] },
                  'gnome_canvas_item_set_valist'            => { in  => ['GnomeCanvasItem*',
                                                                         'const gchar*',
                                                                         'va_list'] },
                  'gnome_canvas_item_move'                  => { in  => ['GnomeCanvasItem*',
                                                                         'double',
                                                                         'double'] },
                  'gnome_canvas_item_affine_relative'       => { in  => ['GnomeCanvasItem*',
                                                                         'const double[6]'] },
                  'gnome_canvas_item_affine_absolute'       => { in  => ['GnomeCanvasItem*',
                                                                         'const double[6]'] },
                  'gnome_canvas_item_scale'                 => { in  => ['GnomeCanvasItem*',
                                                                         'double',
                                                                         'double',
                                                                         'double',
                                                                         'double'] },
                  'gnome_canvas_item_rotate'                => { in  => ['GnomeCanvasItem*',
                                                                         'double',
                                                                         'double',
                                                                         'double'] },
                  # raise becomes rais because raise is a key word in Oz
                  'gnome_canvas_item_rais'                 => { in  => ['GnomeCanvasItem*',
                                                                         'int'] },
                  'gnome_canvas_item_lower'                 => { in  => ['GnomeCanvasItem*',
                                                                         'int'] },
                  'gnome_canvas_item_raise_to_top'          => { in  => ['GnomeCanvasItem*'] },
                  'gnome_canvas_item_lower_to_bottom'       => { in  => ['GnomeCanvasItem*'] },
                  'gnome_canvas_item_show'                  => { in  => ['GnomeCanvasItem*'] },
                  'gnome_canvas_item_hide'                  => { in  => ['GnomeCanvasItem*'] },
                  'gnome_canvas_item_grab'                  => { in  => ['GnomeCanvasItem*',
                                                                         'unsigned int',
                                                                         '!GdkCursor*',
                                                                         'guint32'],
                                                                 out => 'int' },
                  'gnome_canvas_item_ungrab'                => { in  => ['GnomeCanvasItem*',
                                                                         'guint32'] },
                  'gnome_canvas_item_w2i'                   => { in  => ['GnomeCanvasItem*',
                                                                         '=double*',
                                                                         '=double*'] },
                  'gnome_canvas_item_i2w'                   => { in  => ['GnomeCanvasItem*',
                                                                         '=double*',
                                                                         '=double*'] },
                  'gnome_canvas_item_i2w_affine'            => { in  => ['GnomeCanvasItem*',
                                                                         '+double[6]'] },

                  'gnome_canvas_item_i2c_affine'            => { in  => ['GnomeCanvasItem*',
                                                                         '+double[6]'] },
                  'gnome_canvas_item_reparent'              => { in  => ['GnomeCanvasItem*',
                                                                         '!GnomeCanvasGroup*'] },
                  'gnome_canvas_item_grab_focus'            => { in  => ['GnomeCanvasItem*'] },
                  'gnome_canvas_item_get_bounds'            => { in  => ['GnomeCanvasItem*',
                                                                         '+double*',
                                                                         '+double*',
                                                                         '+double*',
                                                                         '+double*'] },
                  'gnome_canvas_item_request_update'        => { in  => ['GnomeCanvasItem*'] } }}
     );
