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
     { name  => 'GdkDrawable',

       super => 'BaseObject',

       meths => { 'gdk_draw_point'                 => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                'gint',
                                                                'gint'] },
                  'gdk_draw_points'                => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                'GdkPoint*',
                                                                'gint'] },
                  'gdk_draw_line'                  => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint'] },
                  'gdk_draw_lines'                 => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                'GdkPoint*',
                                                                'gint'] },
                  'gdk_draw_segments'              => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                'GdkSegment*',
                                                                'gint'] },
                  'gdk_draw_rectangle'             => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint'] },
                  'gdk_draw_arc'                   => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint'] },
                  'gdk_draw_polygon'               => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                'gint',
                                                                'GdkPoint*',
                                                                'gint'] },
                  'gdk_draw_string'                => { in  => ['GdkDrawable*',
                                                                '!GdkFont*',
                                                                '!GdkGC*',
                                                                'gint',
                                                                'gint',
                                                                'const gchar*'] },
                  'gdk_draw_text'                  => { in  => ['GdkDrawable*',
                                                                '!GdkFont*',
                                                                '!GdkGC*',
                                                                'gint',
                                                                'gint',
                                                                'const gchar*',
                                                                'gint'] },
                  'gdk_draw_text_wc'               => { in  => ['GdkDrawable*',
                                                                '!GdkFont*',
                                                                '!GdkGC*',
                                                                'gint',
                                                                'gint',
                                                                'const GdkWChar*',
                                                                'gint'] },
                  'gdk_draw_pixmap'                => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                '!GdkDrawable*',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint'] },
                  'gdk_draw_image'                 => { in  => ['GdkDrawable*',
                                                                '!GdkGC*',
                                                                '!GdkImage*',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint',
                                                                'gint'] } }}
     );
