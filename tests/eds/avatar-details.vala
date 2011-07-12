/*
 * Copyright (C) 2011 Collabora Ltd.
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
 * Authors: Raul Gutierrez Segales <raul.gutierrez.segales@collabora.co.uk>
 *
 */

using EdsTest;
using Folks;
using Gee;

public class AvatarDetailsTests : Folks.TestCase
{
  private EdsTest.Backend _eds_backend;
  private GLib.MainLoop _main_loop;
  private IndividualAggregator _aggregator;
  private Gee.HashMap<string, Value?> _c1;
  private bool _avatars_are_equal;
  private string _avatar_path;

  public AvatarDetailsTests ()
    {
      base ("AvatarDetails");

      this._eds_backend = new EdsTest.Backend ();

      this.add_test ("avatar details interface", this.test_avatar);
    }

  public override void set_up ()
    {
      this._eds_backend.set_up ();
    }

  public override void tear_down ()
    {
      this._eds_backend.tear_down ();
    }

  public void test_avatar ()
    {
      this._c1 = new Gee.HashMap<string, Value?> ();
      this._main_loop = new GLib.MainLoop (null, false);
      this._avatar_path = Environment.get_variable ("AVATAR_FILE_PATH");
      this._avatars_are_equal = false;
      Value? v;

      this._eds_backend.reset();

      v = Value (typeof (string));
      v.set_string ("bernie h. innocenti");
      this._c1.set ("full_name", (owned) v);
      v = Value (typeof (string));
      v.set_string (this._avatar_path);
      this._c1.set ("avatar",(owned) v);
      this._eds_backend.add_contact (this._c1);

      this._test_avatar_async ();

      Timeout.add_seconds (5, () =>
        {
          this._main_loop.quit ();
          return false;
        });

      this._main_loop.run ();

      assert (this._avatars_are_equal);
   }

  private async void _test_avatar_async ()
    {

      yield this._eds_backend.commit_contacts_to_addressbook ();

      var store = BackendStore.dup ();
      yield store.prepare ();
      this._aggregator = new IndividualAggregator ();
      this._aggregator.individuals_changed.connect
          (this._individuals_changed_cb);
      try
        {
          yield this._aggregator.prepare ();
        }
      catch (GLib.Error e)
        {
          GLib.warning ("Error when calling prepare: %s\n", e.message);
        }
    }

  private void _individuals_changed_cb
      (Set<Individual> added,
       Set<Individual> removed,
       string? message,
       Persona? actor,
       GroupDetails.ChangeReason reason)
    {

      assert (removed.size == 0);

      foreach (Individual i in added)
        {
          assert (i.personas.size == 1);

          if (i.full_name == "bernie h. innocenti")
            {
              uint8[] content_a;
              uint8[] content_b;
              var b = File.new_for_path (this._avatar_path);

              try
                {
                  i.avatar.load_contents (null, out content_a);
                  b.load_contents (null, out content_b);

                  if (((string) content_a) == ((string) content_b))
                    {
                      this._avatars_are_equal = true;
                      this._main_loop.quit ();
                    }
                }
              catch (GLib.Error e)
                {
                  GLib.warning ("couldn't load file a");
                }
            }
        }
   }
}

public int main (string[] args)
{
  Test.init (ref args);

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new AvatarDetailsTests ().get_suite ());

  Test.run ();

  return 0;
}