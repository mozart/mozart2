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
     { name  => 'GtkCalendar',

       super => 'GtkWidget',

       inits => { 'gtk_calendar_new'              => { out => 'GtkWidget*' } },

       meths => { 'gtk_calendar_select_month'     => { in  => ['GtkCalendar*',
                                                               'guint',
                                                               'guint'],
                                                       out => 'gint' },
                  'gtk_calendar_select_day'       => { in  => ['GtkCalendar*',
                                                               'guint'] },
                  'gtk_calendar_mark_day'         => { in  => ['GtkCalendar*',
                                                               'guint'],
                                                       out => 'gint' },
                  'gtk_calendar_unmark_day'       => { in  => ['GtkCalendar*',
                                                               'guint'],
                                                       out => 'gint' },
                  'gtk_calendar_clear_marks'      => { in  => ['GtkCalendar*'] },
                  'gtk_calendar_display_options'  => { in  => ['GtkCalendar*',
                                                               '%GtkCalendarDisplayOptions'] },
                  'gtk_calendar_get_date'         => { in  => ['GtkCalendar*',
                                                               'guint*',
                                                               'guint*',
                                                               'guint*'] },
                  'gtk_calendar_freeze'           => { in  => ['GtkCalendar*'] },
                  'gtk_calendar_thaw'             => { in  => ['GtkCalendar*'] } }}
     );
