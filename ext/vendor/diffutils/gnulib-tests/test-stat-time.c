/* -*- buffer-read-only: t -*- vi: set ro: */
/* DO NOT EDIT! GENERATED AUTOMATICALLY! */
/* Test of <stat-time.h>.
   Copyright (C) 2007-2010 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* Written by James Youngman <jay@gnu.org>, 2007.  */

#include <config.h>

#include "stat-time.h"

#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>
#include <unistd.h>

#include "macros.h"

enum { NFILES = 4 };

static int
force_unlink (const char *filename)
{
  /* This chmod is necessary on mingw, where unlink() of a read-only file
     fails with EPERM.  */
  chmod (filename, 0600);
  return unlink (filename);
}

static void
cleanup (int sig)
{
  /* Remove temporary files.  */
  force_unlink ("t-stt-stamp1");
  force_unlink ("t-stt-testfile");
  force_unlink ("t-stt-stamp2");
  force_unlink ("t-stt-renamed");
  force_unlink ("t-stt-stamp3");

  if (sig != 0)
    _exit (1);
}

static int
open_file (const char *filename, int flags)
{
  int fd = open (filename, flags | O_WRONLY, 0500);
  if (fd >= 0)
    {
      close (fd);
      return 1;
    }
  else
    {
      return 0;
    }
}

static void
create_file (const char *filename)
{
  ASSERT (open_file (filename, O_CREAT | O_EXCL));
}

static void
do_stat (const char *filename, struct stat *p)
{
  ASSERT (stat (filename, p) == 0);
}

/* Sleep long enough to notice a timestamp difference on the file
   system in the current directory.  */
static void
nap (void)
{
  static long delay;
  if (!delay)
    {
      /* Initialize only once, by sleeping for 20 milliseconds (needed
         since xfs has a quantization of about 10 milliseconds, even
         though it has a granularity of 1 nanosecond, and since NTFS
         has a default quantization of 15.25 milliseconds, even though
         it has a granularity of 100 nanoseconds).  If the seconds
         differ, repeat the test one more time (in case we crossed a
         quantization boundary on a file system with 1 second
         resolution).  If we can't observe a difference in only the
         nanoseconds, then fall back to 1 second if the time is odd,
         and 2 seconds (needed for FAT) if time is even.  */
      struct stat st1;
      struct stat st2;
      ASSERT (stat ("t-stt-stamp1", &st1) == 0);
      ASSERT (force_unlink ("t-stt-stamp1") == 0);
      delay = 20000;
      usleep (delay);
      create_file ("t-stt-stamp1");
      ASSERT (stat ("t-stt-stamp1", &st2) == 0);
      if (st1.st_mtime != st2.st_mtime)
        {
          /* Seconds differ, give it one more shot.  */
          st1 = st2;
          ASSERT (force_unlink ("t-stt-stamp1") == 0);
          usleep (delay);
          create_file ("t-stt-stamp1");
          ASSERT (stat ("t-stt-stamp1", &st2) == 0);
        }
      if (! (st1.st_mtime == st2.st_mtime
             && get_stat_mtime_ns (&st1) < get_stat_mtime_ns (&st2)))
        delay = (st1.st_mtime & 1) ? 1000000 : 2000000;
    }
  usleep (delay);
}

static void
prepare_test (struct stat *statinfo, struct timespec *modtimes)
{
  int i;

  create_file ("t-stt-stamp1");
  nap ();
  create_file ("t-stt-testfile");
  nap ();
  create_file ("t-stt-stamp2");
  nap ();
  ASSERT (chmod ("t-stt-testfile", 0400) == 0);
  nap ();
  create_file ("t-stt-stamp3");

  do_stat ("t-stt-stamp1",  &statinfo[0]);
  do_stat ("t-stt-testfile", &statinfo[1]);
  do_stat ("t-stt-stamp2",  &statinfo[2]);
  do_stat ("t-stt-stamp3",  &statinfo[3]);

  /* Now use our access functions. */
  for (i = 0; i < NFILES; ++i)
    {
      modtimes[i] = get_stat_mtime (&statinfo[i]);
    }
}

static void
test_mtime (const struct stat *statinfo, struct timespec *modtimes)
{
  int i;

  /* Use the struct stat fields directly. */
  /* mtime(stamp1) < mtime(stamp2) */
  ASSERT (statinfo[0].st_mtime < statinfo[2].st_mtime
          || (statinfo[0].st_mtime == statinfo[2].st_mtime
              && (get_stat_mtime_ns (&statinfo[0])
                  < get_stat_mtime_ns (&statinfo[2]))));
  /* mtime(stamp2) < mtime(stamp3) */
  ASSERT (statinfo[2].st_mtime < statinfo[3].st_mtime
          || (statinfo[2].st_mtime == statinfo[3].st_mtime
              && (get_stat_mtime_ns (&statinfo[2])
                  < get_stat_mtime_ns (&statinfo[3]))));

  /* Now check the result of the access functions. */
  /* mtime(stamp1) < mtime(stamp2) */
  ASSERT (modtimes[0].tv_sec < modtimes[2].tv_sec
          || (modtimes[0].tv_sec == modtimes[2].tv_sec
              && modtimes[0].tv_nsec < modtimes[2].tv_nsec));
  /* mtime(stamp2) < mtime(stamp3) */
  ASSERT (modtimes[2].tv_sec < modtimes[3].tv_sec
          || (modtimes[2].tv_sec == modtimes[3].tv_sec
              && modtimes[2].tv_nsec < modtimes[3].tv_nsec));

  /* verify equivalence */
  for (i = 0; i < NFILES; ++i)
    {
      struct timespec ts;
      ts = get_stat_mtime (&statinfo[i]);
      ASSERT (ts.tv_sec == statinfo[i].st_mtime);
    }
}

#if (defined _WIN32 || defined __WIN32__) && !defined __CYGWIN__
/* Skip the ctime tests on native Windows platforms, because their
   st_ctime is either the same as st_mtime (plus or minus an offset)
   or set to the file _creation_ time, and is not influenced by rename
   or chmod.  */
# define test_ctime(ignored) ((void) 0)
#else
static void
test_ctime (const struct stat *statinfo)
{
  /* On some buggy NFS clients, mtime and ctime are disproportionately
     skewed from one another.  Skip this test in that case.  */
  if (statinfo[0].st_mtime != statinfo[0].st_ctime)
    return;

  /* mtime(stamp2) < ctime(renamed) */
  ASSERT (statinfo[2].st_mtime < statinfo[1].st_ctime
          || (statinfo[2].st_mtime == statinfo[1].st_ctime
              && (get_stat_mtime_ns (&statinfo[2])
                  < get_stat_ctime_ns (&statinfo[1]))));
}
#endif

static void
test_birthtime (const struct stat *statinfo,
                const struct timespec *modtimes,
                struct timespec *birthtimes)
{
  int i;

  /* Collect the birth times.  */
  for (i = 0; i < NFILES; ++i)
    {
      birthtimes[i] = get_stat_birthtime (&statinfo[i]);
      if (birthtimes[i].tv_nsec < 0)
        return;
    }

  /* mtime(stamp1) < birthtime(renamed) */
  ASSERT (modtimes[0].tv_sec < birthtimes[1].tv_sec
          || (modtimes[0].tv_sec == birthtimes[1].tv_sec
              && modtimes[0].tv_nsec < birthtimes[1].tv_nsec));
  /* birthtime(renamed) < mtime(stamp2) */
  ASSERT (birthtimes[1].tv_sec < modtimes[2].tv_sec
          || (birthtimes[1].tv_sec == modtimes[2].tv_sec
              && birthtimes[1].tv_nsec < modtimes[2].tv_nsec));
}

int
main (void)
{
  struct stat statinfo[NFILES];
  struct timespec modtimes[NFILES];
  struct timespec birthtimes[NFILES];

#ifdef SIGHUP
  signal (SIGHUP, cleanup);
#endif
#ifdef SIGINT
  signal (SIGINT, cleanup);
#endif
#ifdef SIGQUIT
  signal (SIGQUIT, cleanup);
#endif
#ifdef SIGTERM
  signal (SIGTERM, cleanup);
#endif

  cleanup (0);
  prepare_test (statinfo, modtimes);
  test_mtime (statinfo, modtimes);
  test_ctime (statinfo);
  test_birthtime (statinfo, modtimes, birthtimes);

  cleanup (0);
  return 0;
}
