# -*-perl-*-

# Authors:
#   Andreas Simon (2000)
#
# Copyright:
#   Andreas Simon (2000)
#
# Last change:
#   $Date$
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
     { name  => 'GdkGC',

       super => 'BaseObject',

       inits => { 'gdk_gc_new'                     => { in  => ['!GdkWindow*'],
                                                        out => 'GdkGC*' },
                  'gdk_gc_new_with_values'         => { in  => ['!GdkWindow*',
                                                                'GtkGCValues',
                                                                'GtkGCValuesMask'],
                                                        out => 'GdkGC*' } },

       meths => { 'gdk_gc_destroy'                 => { in  => ['GdkGC*'] },
                  'gdk_gc_get_values'              => { in  => ['GdkGC*',
                                                                '!GdkGCValues*'] },
                  'gdk_gc_set_forground'           => { in  => ['GdkGC*',
                                                                '!GdkColor*'] },
                  'gdk_gc_set_background'          => { in  => ['GdkGC*',
                                                                '!GdkColor*'] },
                  'gdk_gc_set_font'                => { in  => ['GdkGC*',
                                                                '!GdkFont*'] },
#                 'gdk_gc_set_function'
                  'gdk_gc_set_fill'                => { in  => ['GdkGC*',
                                                                'GdkFill'] },
                  'gdk_gc_set_tile'                => { in  => ['GdkGC*',
                                                                '!GdkPixmap'] },
                  'gdk_gc_set_stipple'             => { in  => ['GdkGC*',
                                                                '!GdkPixmap'] },
                  'gdk_gc_set_ts_origin'           => { in  => ['GdkGC*',
                                                                'gint',
                                                                'gint'] },
                  'gdk_gc_set_clip_origin'         => { in  => ['GdkGC*',
                                                                'gint',
                                                                'gint'] },
                  'gdk_gc_set_clip_mask'           => { in  => ['GdkGC*',
                                                                '!GdkBitmap*'] },
                  'gdk_gc_set_clip_rectangle'      => { in  => ['GdkGC*',
                                                                '!GdkRectangle*'] },
                  'gdk_gc_set_clip_region'         => { in  => ['GdkGC*',
                                                                '!GdkRegion*'] },
                  'gdk_gc_set_subwindow'           => { in  => ['GdkGC*',
                                                                'GdkSubwindowMode'] },
                  'gdk_gc_set_exposure'            => { in  => ['GdkGC*',
                                                                'gint'] },
                  'gdk_gc_set_line_attributes'     => { in  => ['GdkGC*',
                                                                'gint',
                                                                'GdkLineStyle',
                                                                'GdkCapStyle',
                                                                'GdkJoinStyle'] },
                  'gdk_gc_set_dashes'              => { in  => ['GdkGC*',
                                                                'gint',
                                                                'gchar[]',
                                                                'gint'] } }}
     );
