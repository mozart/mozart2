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
     { name  => 'GtkLayout',

       super => 'GtkContainer',

       inits => { 'gtk_layout_new'                 => { in  => ['!GtkAdjustment*',
                                                                '!GtkAdjustment*'],
                                                        out => 'GtkWidget' } },

       meths => { 'gtk_layout_put'                 => { in  => ['GtkLayout*',
                                                                '!GtkWidget*',
                                                                'gint',
                                                                'gint'] },
                  'gtk_layout_move'                => { in  => ['GtkLayout*',
                                                                '!GtkWidget*',
                                                                'gint',
                                                                'gint'] },
                  'gtk_layout_set_size'            => { in  => ['GtkLayout*',
                                                                'guint',
                                                                'guint'] },
                  'gtk_layout_freeze'              => { in  => ['GtkLayout*'] },
                  'gtk_layout_thaw'                => { in  => ['GtkLayout*'] },
                  'gtk_layout_get_hadjustment'     => { in  => ['GtkLayout*'],
                                                        out => 'GtkAdjustment*' },
                  'gtk_layout_get_vdjustment'      => { in  => ['GtkLayout*'],
                                                        out => 'GtkAdjustment*' },
                  'gtk_layout_set_hadjustment'     => { in  => ['GtkLayout*',
                                                                '!GtkAdjustment*'] },
                  'gtk_layout_set_vadjustment'     => { in  => ['GtkLayout*',
                                                                '!GtkAdjustment*'] } }}
     );
