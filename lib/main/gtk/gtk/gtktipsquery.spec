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
     { name  => 'GtkTipsQuery',

       super => 'GtkLabel',

       args  => { 'emit_always'                   => 'gboolean',
                  'caller'                        => 'GtkWidget',
                  'label_inactive'                => 'gchar*',
                  'label_no_tip'                  => 'gchar*' },

       inits => { 'gtk_tips_query_new'            => { out => 'GtkWidget*' } },

       meths => { 'gtk_tips_query_start_query'    => { in  => ['GtkTipsQuery*'] },
                  'gtk_tips_query_stop_query'     => { in  => ['GtkTipsQuery*'] },
                  'gtk_tips_query_set_caller'     => { in  => ['GtkTipsQuery*',
                                                               '!GtkWidget*'] },
                  'gtk_tips_query_set_labels'     => { in  => ['GtkTipsQuery*',
                                                               'const gchar*',
                                                               'const gchar*'] } }}
     );
