/* test-case.vala
 *
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 */

using Folks;
using Gee;

/**
 * A test case for the dummy backend, which is configured as the
 * primary store and as the only backend allowed.
 */
public class DummyTest.TestCase : Folks.TestCase
{
  /**
   * The dummy test backend.
   */
  public Dummyf.Backend dummy_backend;

  /**
   * The default persona store
   */
  public Dummyf.PersonaStore dummy_persona_store;

  private BackendStore backend_store;

  public TestCase (string name)
    {
      base (name);

      Environment.set_variable ("FOLKS_BACKENDS_ALLOWED", "dummy", true);
      Environment.set_variable ("FOLKS_PRIMARY_STORE", "dummy", true);
    }

  public override void set_up ()
    {
      base.set_up ();

      var main_loop = new GLib.MainLoop (null, false);
      this.backend_store = BackendStore.dup();
      this.backend_store.load_backends.begin((obj, res) => 
        {
            try 
              {
                this.backend_store.load_backends.end(res);
                main_loop.quit ();
              }
            catch (GLib.Error error)
              {
                GLib.critical("Fail to initialized backend store.\n");
                assert_not_reached ();
              } 
        });
      TestUtils.loop_run_with_timeout (main_loop);

      this.dummy_backend = this.backend_store.dup_backend_by_name ("dummy") as Dummyf.Backend;
      this.configure_primary_store ();
    }

  public virtual void configure_primary_store ()
    {
      var persona_stores = new HashSet<PersonaStore>();
      string[] writable_properties = { Folks.PersonaStore.detail_key (PersonaDetail.BIRTHDAY),
          Folks.PersonaStore.detail_key (PersonaDetail.EMAIL_ADDRESSES),
          Folks.PersonaStore.detail_key (PersonaDetail.PHONE_NUMBERS),
          null };

      this.dummy_persona_store = new Dummyf.PersonaStore ("dummy-store", "Dummy personas", writable_properties);
      this.dummy_persona_store.persona_type = typeof (Dummyf.FatPersona);

      persona_stores.add (this.dummy_persona_store);
      this.dummy_backend.register_persona_stores (persona_stores);
    }

  public override void tear_down ()
    {
      this.dummy_persona_store = null;
      this.dummy_backend = null;
      base.tear_down ();
    }
}
