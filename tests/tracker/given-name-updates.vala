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

using Tracker.Sparql;
using TrackerTest;
using Folks;
using Gee;

public class GivenNameUpdatesTests : TrackerTest.TestCase
{
  private GLib.MainLoop _main_loop;
  private IndividualAggregator _aggregator;
  private bool _updated_given_name_found;
  private string _updated_given_name;
  private string _individual_id;
  private string _initial_fullname;
  private string _initial_given_name;
  private string _contact_urn;
  private bool _initial_given_name_found;

  public GivenNameUpdatesTests ()
    {
      base ("GivenNameUpdates");

      ((!) this.tracker_backend).debug = false;

      this.add_test ("given name updates", this.test_given_name_updates);
    }

  public void test_given_name_updates ()
    {
      this._main_loop = new GLib.MainLoop (null, false);
      Gee.HashMap<string, string> c1 = new Gee.HashMap<string, string> ();
      this._initial_fullname = "persona #1";
      this._initial_given_name = "given name #1";
      this._updated_given_name = "updated given #1";
      this._contact_urn = "<urn:contact001>";

      c1.set (TrackerTest.Backend.URN, this._contact_urn);
      c1.set (Trf.OntologyDefs.NCO_FULLNAME, this._initial_fullname);
      c1.set (Trf.OntologyDefs.NCO_GIVEN, this._initial_given_name);
      ((!) this.tracker_backend).add_contact (c1);

      ((!) this.tracker_backend).set_up ();

      this._initial_given_name_found = false;
      this._updated_given_name_found = false;
      this._individual_id = "";

      this._test_given_name_updates_async.begin ();

      Timeout.add_seconds (5, () =>
        {
          this._main_loop.quit ();
          assert_not_reached ();
        });

      this._main_loop.run ();

      assert (this._initial_given_name_found == true);
      assert (this._updated_given_name_found == true);
    }

  private async void _test_given_name_updates_async ()
    {
      var store = BackendStore.dup ();
      yield store.prepare ();
      this._aggregator = new IndividualAggregator ();
      this._aggregator.individuals_changed_detailed.connect
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

  private void _individuals_changed_cb (
       MultiMap<Individual?, Individual?> changes)
    {
      var added = changes.get_values ();
      var removed = changes.get_keys ();

      foreach (var i in added)
        {
          assert (i != null);

          if (this._initial_fullname == i.full_name)
            {
              i.structured_name.notify["given-name"].connect
                 (this._notify_given_name_cb);
              var given_name = i.structured_name.given_name;
              if (given_name == this._initial_given_name)
                {
                  this._individual_id = i.id;
                  this._initial_given_name_found = true;
                  ((!) this.tracker_backend).update_contact (this._contact_urn,
                      Trf.OntologyDefs.NCO_GIVEN, this._updated_given_name);
                }
            }
        }

      assert (removed.size == 1);

      foreach (var i in removed)
        {
          assert (i == null);
        }
    }

  private void _notify_given_name_cb (Object individual_obj, ParamSpec ps)
    {
      Folks.StructuredName structured_name =
          (Folks.StructuredName) individual_obj;

      var given_name = structured_name.given_name;
      if (given_name == this._updated_given_name)
        {
          this._updated_given_name_found = true;
          this._main_loop.quit ();
        }
    }
}

public int main (string[] args)
{
  Test.init (ref args);

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new GivenNameUpdatesTests ().get_suite ());

  Test.run ();

  return 0;
}
