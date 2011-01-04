/*
 * Copyright (C) 2010 Collabora Ltd.
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using GLib;
using Gee;

internal class Folks.Debug : Object
{
  private enum Domains {
    /* Zero is used for "no debug spew" */
    CORE = 1 << 0,
    TELEPATHY_BACKEND = 1 << 1,
    KEY_FILE_BACKEND = 1 << 2
  }

  private static weak Debug _instance;

  internal void _set_flags (string? debug_flags)
    {
      /* FIXME: we obviously shouldn't be hard-coding these. See bgo#638609 */
      GLib.DebugKey keys[3] =
        {
          DebugKey () { key = "Core", value = Domains.CORE },
          DebugKey () { key = "TelepathyBackend",
              value = Domains.TELEPATHY_BACKEND },
          DebugKey () { key = "KeyFileBackend",
              value = Domains.KEY_FILE_BACKEND }
        };

      var flags = GLib.parse_debug_string (debug_flags, keys);

      foreach (unowned DebugKey key in keys)
        {
          if ((flags & key.value) == 0)
            {
              /* Install a log handler which will blackhole the log message.
               * Other log messages will be printed out by the default log
               * handler. */
              Log.set_handler (key.key, LogLevelFlags.LEVEL_DEBUG,
                  (domain, flags, message) => {});
            }
        }
    }

  internal static Debug dup ()
    {
      if (_instance == null)
        {
          /* use an intermediate variable to force a strong reference */
          var new_instance = new Debug ();
          _instance = new_instance;

          return new_instance;
        }

      return _instance;
    }

  ~Debug ()
    {
      /* manually clear the singleton _instance */
      _instance = null;
    }
}
