/*
 * Copyright (C) 2012 Collabora Ltd.
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
 * Authors: Jeremy Whiting <jeremy.whiting@collabora.com>
 *
 */

using Folks;
using Gee;

public class CreateRemoveStoresTests : Folks.TestCase
{
  private GLib.MainLoop _main_loop;
  private EdsTest.Backend? _eds_backend;
  private IndividualAggregator _aggregator;
  private HashMap<string, bool> _store_removed;
  private HashMap<string, bool> _store_added;
  private BackendStore? _backend_store;

  public CreateRemoveStoresTests ()
    {
      base ("CreateRemoveStoresTests");

      this.add_test ("test creating and removing of PersonaStores",
          this.test_creating_removing_stores);
    }

  public override void set_up ()
    {
      this._eds_backend = new EdsTest.Backend ();
      this._store_removed = new HashMap<string, bool> ();
      this._store_added = new HashMap<string, bool> ();
      this._backend_store = BackendStore.dup();

      this._eds_backend.set_up ();

      /* We configure eds as the primary store */
      var config_val = "eds:%s".printf (this._eds_backend.address_book_uid);
      Environment.set_variable ("FOLKS_PRIMARY_STORE", config_val, true);
      Environment.set_variable ("FOLKS_BACKEND_EDS_USE_ADDRESS_BOOKS",
                                "test:other:test1:test2", true);
    }

  public override void tear_down ()
    {
      this._eds_backend.tear_down ();

      Environment.unset_variable ("FOLKS_PRIMARY_STORE");
      Environment.unset_variable ("FOLKS_BACKEND_EDS_USE_ADDRESS_BOOKS");

      this._eds_backend = null;
    }

  public void test_creating_removing_stores ()
    {
      this._main_loop = new GLib.MainLoop (null, false);

      this._test_creating_removing_stores_async.begin ();

      var timer_id = Timeout.add_seconds (20, () =>
        {
          this._main_loop.quit ();
          assert_not_reached ();
        });

      this._main_loop.run ();

      assert (this._store_removed.size > 0);
      foreach (bool removed in this._store_removed.values)
        {
          assert (removed == true);
        }
        
      GLib.Source.remove (timer_id);
      this._aggregator = null;
      this._main_loop = null;
    }

  private async void _test_creating_removing_stores_async ()
    {
      yield this._backend_store.prepare ();
      this._aggregator = new IndividualAggregator ();
      try
        {
          yield this._backend_store.load_backends ();
          
          var backend = this._backend_store.enabled_backends.get ("eds");
          assert (backend != null);

          yield this._aggregator.prepare ();
          assert (this._aggregator.is_prepared);
          backend.persona_store_removed.connect (this._store_removed_cb);
          backend.persona_store_added.connect (this._store_added_cb);
          
          var pstore = "test1";
          this._store_removed[pstore] = false;
          this._store_added[pstore] = false;

          debug ("Creating addressbook test1");
          yield Edsf.PersonaStore.create_address_book (pstore);

          pstore = "test2";
          this._store_removed[pstore] = false;
          this._store_added[pstore] = false;
          
          debug ("Creating addressbook test2");
          yield Edsf.PersonaStore.create_address_book (pstore);
        }
      catch (GLib.Error e)
        {
          GLib.warning ("Error when calling prepare: %s\n", e.message);
        }
    }

  private void _store_removed_cb (
       PersonaStore store)
    {
      assert (store != null);
      debug ("store removed %s", store.id);
      this._store_removed[store.id] = true;
      
      int removed_count = 0;
      
      foreach (bool removed in this._store_removed.values)
        {
          if (removed)
            {
              ++removed_count;
            }
        }
      
      debug ("removed_count is %d, expected size is %d\n", removed_count,
            this._store_removed.size);
      if (removed_count == this._store_removed.size)
        {
          this._main_loop.quit ();
        }
    }

  private void _store_added_cb (PersonaStore store)
    {
      debug ("store added %s", store.id);
      this._store_added[store.id] = true;
      
      var backend = this._backend_store.enabled_backends.get ("eds");
      assert (backend != null);
      
      debug ("removing store %s", store.id);
      Edsf.PersonaStore.remove_address_book.begin ((Edsf.PersonaStore)store);
    }
}

public int main (string[] args)
{
  Test.init (ref args);

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new CreateRemoveStoresTests ().get_suite ());

  Test.run ();

  return 0;
}
