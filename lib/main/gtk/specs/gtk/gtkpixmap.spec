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
     { name  => 'GtkPixmap',

       super => 'GtkMisc',


       inits => { 'gtk_pixmap_new'                   => { in  => ['GdkPixmap*',
                                                                  'GdkBitmap*'],
                                                          out => 'GtkWidget*' }},

       meths => { 'gtk_pixmap_set'                   => { in  => ['GtkPixmap*',
                                                                  'GdkPixmap*',
                                                                  'GdkBitmap*'] },
                  'gtk_pixmap_get'                   => { in  => ['GtkPixmap*',
                                                                  '+GdkPixmap**',
                                                                  '+GdkBitmap**'] },
                  'gtk_pixmap_set_build_insensitive' => { in  => ['GtkPixmap*',
                                                                  'gint'] } }}
     );
