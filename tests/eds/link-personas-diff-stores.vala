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

using Folks;
using Gee;

public class LinkPersonasDiffStoresTests : Folks.TestCase
{
  private GLib.MainLoop _main_loop;
  private EdsTest.Backend? _eds_backend;
  private EdsTest.Backend? _eds_backend_other;
  private IndividualAggregator _aggregator;
  private string _persona_fullname_1;
  private string _persona_fullname_2;
  private bool _linking_fired;
  private bool _linked_individual_found;
  private string _persona_iid_1;
  private string _persona_iid_2;
  private HashSet<Persona> _personas;

  public LinkPersonasDiffStoresTests ()
    {
      base ("LinkPersonasDiffStoresTests");

      this.add_test ("test linking via local IDs using different PersonaStores",
          this.test_linking_via_local_ids_diff_stores);
    }

  public override void set_up ()
    {
      this._eds_backend = new EdsTest.Backend ();
      this._eds_backend_other = new EdsTest.Backend ();
      this._eds_backend_other.address_book_uri = "local://other";

      this._eds_backend.set_up ();
      this._eds_backend_other.set_up ();

      /* We configure eds as the primary store */
      var config_val = "eds:%s".printf (this._eds_backend.address_book_uid);
      Environment.set_variable ("FOLKS_PRIMARY_STORE", config_val, true);
    }

  public override void tear_down ()
    {
      this._eds_backend.tear_down ();
      this._eds_backend_other.tear_down ();

      Environment.unset_variable ("FOLKS_PRIMARY_STORE");

      this._eds_backend = null;
      this._eds_backend_other = null;
    }

  public void test_linking_via_local_ids_diff_stores ()
    {
      this._main_loop = new GLib.MainLoop (null, false);
      this._persona_fullname_1 = "persona #1";
      this._persona_fullname_2 = "persona #2";
      this._personas = new HashSet<Persona> ();
      this._linking_fired = false;
      this._persona_iid_1 = "";
      this._persona_iid_2 = "";
      this._linked_individual_found = false;

      this._test_linking_personas_async ();

      var timer_id = Timeout.add_seconds (8, () =>
        {
          this._main_loop.quit ();
          assert_not_reached ();
        });

      this._main_loop.run ();

      assert (this._linked_individual_found == true);

      GLib.Source.remove (timer_id);
      this._aggregator = null;
      this._main_loop = null;
    }

  private async void _test_linking_personas_async ()
    {
      var store = BackendStore.dup ();
      yield store.prepare ();
      this._aggregator = new IndividualAggregator ();
      this._aggregator.individuals_changed_detailed.connect
          (this._individuals_changed_cb);
      try
        {
          yield this._aggregator.prepare ();

          var pstore = this._get_store (store,
              this._eds_backend.address_book_uid);
          assert (pstore != null);

          var pstore2 = this._get_store (store,
              this._eds_backend_other.address_book_uid);
          assert (pstore2 != null);

          yield this._add_personas (pstore, pstore2);
        }
      catch (GLib.Error e)
        {
          GLib.warning ("Error when calling prepare: %s\n", e.message);
        }
    }

  private PersonaStore? _get_store (BackendStore store, string store_id)
    {
      PersonaStore? pstore = null;
      foreach (var backend in store.enabled_backends.values)
        {
          pstore = backend.persona_stores.get (store_id);
          if (pstore != null)
            break;
        }
      return pstore;
    }

  /* Here is how this test is expected to work:
   * - we start by adding 2 personas
   * - this should trigger individuals-changed with 2 new individuals
   * - we ask the IndividualAggregator to link the 2 personas coming
   *   from those individuals
   * - we wait for a new Individual which contains the linkable
   *   attributes of these 2 personas
   *
   * @param pstore1 the {@link PersonaStore} in which to add the 1st Persona
   * @param pstore2 the {@link PersonaStore} in which to add the 1st Persona
   */
  private async void _add_personas (PersonaStore pstore1, PersonaStore pstore2)
    {
      HashTable<string, Value?> details1 = new HashTable<string, Value?>
          (str_hash, str_equal);
      Value? v1 = Value (typeof (string));
      v1.set_string (this._persona_fullname_1);
      details1.insert ("full-name", (owned) v1);

      HashTable<string, Value?> details2 = new HashTable<string, Value?>
          (str_hash, str_equal);
      Value? v2 = Value (typeof (string));
      v2.set_string (this._persona_fullname_2);
      details2.insert ("full-name", (owned) v2);

      try
        {
          yield this._aggregator.add_persona_from_details (null,
              pstore1, details1);

          yield this._aggregator.add_persona_from_details (null,
              pstore2, details2);
        }
      catch (Folks.IndividualAggregatorError e)
        {
          GLib.warning ("[AddPersonaError] add_persona_from_details: %s\n",
              e.message);
        }
    }

  private void _individuals_changed_cb (
       MultiMap<Individual?, Individual?> changes)
    {
      this._individuals_changed_async (changes);
    }

  private void _individuals_changed_async (
       MultiMap<Individual?, Individual?> changes)
    {
      var added = changes.get_values ();

      foreach (var i in added)
        {
          if (i == null)
            {
              continue;
            }

          this._check_personas (i);
        }
    }

  /* As mentioned in _add_personas here we actually check
   * for the following events
   *
   * - spot the 2 individuals corresponding to the 2 personas we've added
   * - when we've spotted these 2, we pack them in a list and feed that to
   *   IndividualAggregator#link_personas
   * - this should fire a new individuals-changed event with a new individual
   *   which should be the linked individual if it contains the linking
   *   properties of the 2 linked personas.
   */
  private async void _check_personas (Individual i)
    {
      /* Exit early if this is a lingering callback */
      if (this._linked_individual_found == true)
        return;

      Persona first_persona = null;
      foreach (var p in i.personas)
        {
          first_persona = p;
          break;
        }

      if (i.full_name == this._persona_fullname_1 &&
          this._persona_iid_1 == "")
        {
          this._persona_iid_1 = first_persona.iid;
          this._personas.add (first_persona);
        }
      else if (i.full_name == this._persona_fullname_2 &&
          this._persona_iid_2 == "")
        {
          this._persona_iid_2 = first_persona.iid;
          this._personas.add (first_persona);
        }
      else if (i.personas.size > 1)
        {
          bool first_persona_id = false;
          bool second_persona_id = false;

          foreach (var p1 in i.personas)
            {
              if (p1.iid == this._persona_iid_1)
                first_persona_id = true;
              else if (p1.iid == this._persona_iid_2)
                second_persona_id = true;
            }

          if (first_persona_id && second_persona_id)
            {
              this._linked_individual_found = true;
              this._main_loop.quit ();
            }
        }

      /* We can try linking the personas only once we've got the
       * 2 initially created personas. */
      if (this._personas.size == 2 &&
          this._linking_fired == false)
        {
          this._linking_fired = true;
          try
            {
              yield this._aggregator.link_personas (this._personas);
            }
          catch (GLib.Error e)
            {
              GLib.warning ("link_personas: %s\n", e.message);
            }
        }
    }
}

public int main (string[] args)
{
  Test.init (ref args);

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new LinkPersonasDiffStoresTests ().get_suite ());

  Test.run ();

  return 0;
}
