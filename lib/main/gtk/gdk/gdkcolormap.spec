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
     { name  => 'GdkColormap',

       super => 'BaseObject',

       inits => { 'gdk_colormap_new'              => { in  => ['!GdkVisual',
                                                               'gint'],
                                                       out => 'GdkColormap*' } },

       meths => { 'gdk_colormap_ref'              => { in  => ['GdkColormap*'],
                                                       out => 'GdkColormap*' },
                  'gdk_colormap_unref'            => { in  => ['GdkColormap*'] },
                  'gdk_colormap_system'           => { out => 'GdkColormap*' },
                  'gdk_colormap_get_system_size'  => { out => 'gint' },
                  'gdk_colormap_change'           => { in  => ['GdkColormap*',
                                                               'gint'] },
                  'gdk_colormap_alloc_colors'     => { in  => ['GdkColormap*',
                                                               '!GdkColor*',
                                                               'gint',
                                                               'gboolean',
                                                               'gboolean',
                                                               'gboolean*'],
                                                       out => 'gint' },
                  'gdk_colormap_alloc_color'      => { in  => ['GdkColormap*',
                                                               '!GdkColor*',
                                                               'gboolean',
                                                               'gboolean'],
                                                       out => 'gboolean' },
                  'gdk_colormap_free_colors'      => { in  => ['GdkColormap*',
                                                               'GdkColor*',
                                                               'gint'] },
                  'gdk_colormap_get_visual'       => { in  => ['GdkColormap*'],
                                                       out => 'GdkVisual*' },
                  'gdk_colors_store'              => { in  => ['GdkColormap*',
                                                               'GdkColor*',
                                                               'gint'] },
                  'gdk_colors_free'               => { in  => ['GdkColormap*',
                                                               'gulong*',
                                                               'gint',
                                                               'glong*'] },
                  'gdk_color_white'               => { in  => ['GdkColormap*',
                                                               'GdkColor*'],
                                                       out => 'gboolean' },
                  'gdk_color_black'               => { in  => ['GdkColormap*',
                                                               'GdkColor*'],
                                                       out => 'gboolean' },
                  'gdk_color_parse'               => { in  => ['GdkColormap*',
                                                               'GdkColor*'],
                                                       out => 'gboolean' },
                  'gdk_color_alloc'               => { in  => ['GdkColormap*',
                                                               'GdkColor*'],
                                                       out => 'gboolean' },
                  'gdk_color_change'              => { in  => ['GdkColormap*',
                                                               'GdkColor*'],
                                                       out => 'gboolean' } }}
     );
