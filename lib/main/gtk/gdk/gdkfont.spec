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
     { name  => 'GdkFont',

       super => 'BaseObject',

       inits => { 'gdk_font_load'                 => { in  => ['const gchar*'],
                                                       out => 'GdkFont*' },
                  'gdk_fontset_load'              => { in  => ['const gchar*'],
                                                       out => 'GdkFont*' } },

       meths => { 'gdk_font_ref'                  => { in  => ['GdkFont*'],
                                                       out => 'GdkFont*' },
                  'gdk_font_unref'                => { in  => ['GdkFont*'] },
                  'gdk_font_id'                   => { in  => ['GdkFont*'],
                                                       out => 'gint' },
                  'gdk_font_equal'                => { in  => ['GdkFont*',
                                                               '!GdkFont*'],
                                                       out => 'gint' },
                  'gdk_string_extends'            => { in  => ['GdkFont*',
                                                               'const gchar*',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*'] },
                  'gdk_text_extends'              => { in  => ['GdkFont*',
                                                               'const gchar*',
                                                               'gint',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*'] },
                  'gdk_text_extends_wc'           => { in  => ['GdkFont*',
                                                               'const GdkWChar*',
                                                               'gint',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*',
                                                               'gint*'] },

                  'gdk_string_width'              => { in  => ['GdkFont*',
                                                               'const gchar*'],
                                                       out => 'gint' },
                  'gdk_text_width'                => { in  => ['GdkFont*',
                                                               'const gchar*',
                                                               'gint'],
                                                       out => 'gint' },
                  'gdk_text_width_wc'             => { in  => ['GdkFont*',
                                                               'const GdkWChar*',
                                                               'gint'],
                                                       out => 'gint' },
                  'gdk_char_width'                => { in  => ['GdkFont*',
                                                               'gchar'],
                                                       out => 'gint' },
                  'gdk_char_width'                => { in  => ['GdkFont*',
                                                               'GdkWChar'],
                                                       out => 'gint' },
                  'gdk_string_measure'            => { in  => ['GdkFont*',
                                                               'const gchar*'],
                                                       out => 'gint' },
                  'gdk_text_measure'              => { in  => ['GdkFont*',
                                                               'const gchar*',
                                                               'gint'],
                                                       out => 'gint' },
                  'gdk_char_measure'              => { in  => ['GdkFont*',
                                                               'gchar'],
                                                       out => 'gint' },
                  'gdk_string_height'             => { in  => ['GdkFont*',
                                                               'const gchar*'],
                                                       out => 'gint' },
                  'gdk_text_height'               => { in  => ['GdkFont*',
                                                               'const gchar*',
                                                               'gint'],
                                                       out => 'gint' },
                  'gdk_char_height'               => { in  => ['GdkFont*',
                                                               'gchar'],
                                                       out => 'gint' } }}
     );
