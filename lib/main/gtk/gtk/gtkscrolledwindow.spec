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
     { name  => 'GtkScrolledWindow',

       super => 'GtkBin',

       args  => { 'hadjustment'                             => 'GtkAdjustment*',
                  'vadjustment'                             => 'GtkAdjustment*',
                  'hscrollbar_policy'                       => 'GtkPolicyType',
                  'vscrollbar_policy'                       => 'GtkPolicyType',
                  'window_placement'                        => 'GtkCornerType' },

       inits => { 'gtk_scrolled_window_new'                 => { in  => ['!GtkAdjustment*',
                                                                         '!GtkAdjustment*'],
                                                                 out => 'GtkWidget*' } },

       meths => { 'gtk_scrolled_window_get_hadjustment'     => { in  => ['GtkScrolledWindow*'],
                                                                 out => 'GtkAdjustment*' },
                  'gtk_scrolled_window_get_vadjustment'     => { in  => ['GtkScrolledWindow*'],
                                                                 out => 'GtkAdjustment*' },
                  'gtk_scrolled_window_set_policy'          => { in  => ['GtkScrolledWindow*',
                                                                         'GtkPolicyType',
                                                                         'GtkPolicyType'] },
                  'gtk_scrolled_window_add_with_viewport'   => { in  => ['GtkScrolledWindow*',
                                                                         '!GtkWidget'] },
                  'gtk_scrolled_window_set_hadjustment'     => { in  => ['GtkScrolledWindow*',
                                                                         '!GtkAdjustment'] },
                  'gtk_scrolled_window_set_vadjustment'     => { in  => ['GtkScrolledWindow*',
                                                                         '!GtkAdjustment'] },
                  'gtk_scrolled_window_set_placement'       => { in  => ['GtkScrolledWindow*',
                                                                         'GtkCornerType'] } }}
     );
