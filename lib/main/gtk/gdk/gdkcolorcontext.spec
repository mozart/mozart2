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
     { name  => 'GdkColorContext',

       super => 'BaseObject',

       inits => { 'gdk_color_context_new'                      => { in  => ['!GdkVisual*',
                                                                            '!GdkColormap*'],
                                                                    out => 'GdkColorContext*' },
                  'gdk_color_context_new_mono'                 => { in  => ['!GdkVisual*',
                                                                            '!GdkColormap*'],
                                                                    out => 'GdkColorContext*' } },

       meths => { 'gdk_color_context_free'                     => { in  => ['GdkColorContext*'] },
                  'gdk_color_context_get_pixel'                => { in  => ['GdkColorContext*',
                                                                            'gushort',
                                                                            'gushort',
                                                                            'gushort',
                                                                            'gint*'],
                                                                    out => 'gulong' },
                  'gdk_color_context_get_pixels'               => { in  => ['GdkColorContext*',
                                                                            'gushort*',
                                                                            'gushort*',
                                                                            'gushort*',
                                                                            'gint',
                                                                            'gulong*',
                                                                            'gint*'] },
                  'gdk_color_context_get_pixels_incremental'   => { in  => ['GdkColorContext*',
                                                                            'gushort*',
                                                                            'gushort*',
                                                                            'gushort*',
                                                                            'gint',
                                                                            'gint*',
                                                                            'gulong*',
                                                                            'gint*'] },
                  'gdk_color_context_query_color'              => { in  => ['GdkColorContext*',
                                                                            'GdkColor*'],
                                                                    out => 'gint' },
                  'gdk_color_context_query_colors'             => { in  => ['GdkColorContext*',
                                                                            'GdkColor*',
                                                                            'gint'],
                                                                    out => 'gint' },
                  'gdk_color_context_add_palette'              => { in  => ['GdkColorContext*',
                                                                            'GdkColor*',
                                                                            'gint'],
                                                                    out => 'gint' },
                  'gdk_color_context_init_dither'              => { in  => ['GdkColorContext*'] },
                  'gdk_color_context_free_dither'              => { in  => ['GdkColorContext*'] },
                  'gdk_color_context_get_pixel_from_palette'   => { in  => ['GdkColorContext*',
                                                                            'gushort*',
                                                                            'gushort*',
                                                                            'gushort*',
                                                                            'gint*'],
                                                                    out => 'gulong' },
                  'gdk_color_context_get_index_from_palette'   => { in  => ['GdkColorContext*',
                                                                            'gint*',
                                                                            'gint*',
                                                                            'gint*',
                                                                            'gint*'],
                                                                    out => 'guchar' } }}
     );
