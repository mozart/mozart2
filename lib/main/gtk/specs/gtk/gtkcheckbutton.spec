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
     { name  => 'GtkCheckButton',

       super => 'GtkToggleButton',

       inits => { 'gtk_check_button_new'            => { out => 'GtkWidget*' },
                  'gtk_check_button_new_with_label' => { in  => 'const gchar*',
                                                         out => 'GtkWidget*' }}}
     );
