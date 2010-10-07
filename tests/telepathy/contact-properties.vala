using DBus;
using TelepathyGLib;
using TpTest;
using Tpf;
using Folks;
using Gee;

public class ContactPropertiesTests : Folks.TestCase
{
  private DBusDaemon daemon;
  private TpTest.Account account;
  private TpTest.AccountManager account_manager;
  private TpTest.ContactListConnection conn;
  private MainLoop main_loop;
  private string bus_name;
  private string object_path;
  private string individual_id_prefix = "telepathy:protocol:";

  public ContactPropertiesTests ()
    {
      base ("ContactProperties");

      this.add_test ("individual properties",
          this.test_individual_properties);
      this.add_test ("individual properties:change alias through tp backend",
          this.test_individual_properties_change_alias_through_tp_backend);
      this.add_test ("individual properties:change alias through test cm",
          this.test_individual_properties_change_alias_through_test_cm);
    }

  public override void set_up ()
    {
      this.main_loop = new GLib.MainLoop (null, false);

      try
        {
          this.daemon = DBusDaemon.dup ();
        }
      catch (GLib.Error e)
        {
          error ("Couldn't get D-Bus daemon: %s", e.message);
        }

      /* Set up a contact list connection */
      this.conn = new TpTest.ContactListConnection ("me@example.com",
          "protocol", 0, 0);

      try
        {
          this.conn.register ("cm", out this.bus_name, out this.object_path);
        }
      catch (GLib.Error e)
        {
          error ("Failed to register connection %p.", this.conn);
        }

      var handle_repo = this.conn.get_handles (HandleType.CONTACT);
      Handle self_handle = 0;
      try
        {
          self_handle = TelepathyGLib.handle_ensure (handle_repo,
              "me@example.com", null);
        }
      catch (GLib.Error e)
        {
          error ("Couldn't ensure self handle '%s': %s", "me@example.com",
              e.message);
        }

      this.conn.set_self_handle (self_handle);
      this.conn.change_status (ConnectionStatus.CONNECTED,
          ConnectionStatusReason.REQUESTED);

      /* Create an account */
      this.account = new TpTest.Account (this.object_path);
      this.daemon.register_object (
          TelepathyGLib.ACCOUNT_OBJECT_PATH_BASE + "cm/protocol/account",
          this.account);

      /* Create an account manager */
      try
        {
          this.daemon.request_name (TelepathyGLib.ACCOUNT_MANAGER_BUS_NAME,
              false);
        }
      catch (GLib.Error e)
        {
          error ("Couldn't request account manager bus name '%s': %s",
              TelepathyGLib.ACCOUNT_MANAGER_BUS_NAME, e.message);
        }

      this.account_manager = new TpTest.AccountManager ();
      this.daemon.register_object (TelepathyGLib.ACCOUNT_MANAGER_OBJECT_PATH,
          this.account_manager);
    }

  public override void tear_down ()
    {
      this.conn.change_status (ConnectionStatus.DISCONNECTED,
          ConnectionStatusReason.REQUESTED);

      this.daemon.unregister_object (this.account_manager);
      this.account_manager = null;

      try
        {
          this.daemon.release_name (TelepathyGLib.ACCOUNT_MANAGER_BUS_NAME);
        }
      catch (GLib.Error e)
        {
          error ("Couldn't release account manager bus name '%s': %s",
              TelepathyGLib.ACCOUNT_MANAGER_BUS_NAME, e.message);
        }

      this.daemon.unregister_object (this.account);
      this.account = null;

      this.conn = null;
      this.daemon = null;
      this.bus_name = null;
      this.object_path = null;

      Timeout.add_seconds (5, () =>
        {
          this.main_loop.quit ();
          this.main_loop = null;
          return false;
        });

      /* Run the main loop to process the carnage and destruction */
      this.main_loop.run ();
    }

  public void test_individual_properties ()
    {
      var main_loop = new GLib.MainLoop (null, false);

      /* Ignore the error caused by not running the logger */
      Test.log_set_fatal_handler ((d, l, m) =>
        {
          return !m.has_suffix ("couldn't get list of favourite contacts: " +
              "The name org.freedesktop.Telepathy.Logger was not provided by " +
              "any .service files");
        });

      /* Set up the aggregator */
      var aggregator = new IndividualAggregator ();
      aggregator.individuals_changed.connect ((added, removed, m, a, r) =>
        {
          foreach (Individual i in added)
            {
              /* We only check one */
              if (i.id != (this.individual_id_prefix + "olivier@example.com"))
                {
                  continue;
                }

              /* Check properties */
              assert (i.alias == "Olivier");
              assert (i.presence_message == "");
              assert (i.presence_type == PresenceType.AWAY);
              assert (i.is_online () == true);

              /* Check groups */
              assert (i.groups.size () == 2);
              assert (i.groups.lookup ("Montreal") == true);
              assert (i.groups.lookup ("Francophones") == true);
            }

          assert (removed == null);
        });
      aggregator.prepare ();

      /* Kill the main loop after a few seconds. If there are still individuals
       * in the set of expected individuals, the aggregator has either failed
       * or been too slow (which we can consider to be failure). */
      Timeout.add_seconds (3, () =>
        {
          main_loop.quit ();
          return false;
        });

      main_loop.run ();

      /* necessary to reset the aggregator for the next test */
      aggregator = null;
    }

  public void test_individual_properties_change_alias_through_tp_backend ()
    {
      var main_loop = new GLib.MainLoop (null, false);
      var alias_notified = false;

      /* Ignore the error caused by not running the logger */
      Test.log_set_fatal_handler ((d, l, m) =>
        {
          return !m.has_suffix ("couldn't get list of favourite contacts: " +
              "The name org.freedesktop.Telepathy.Logger was not provided by " +
              "any .service files");
        });

      /* Set up the aggregator */
      var aggregator = new IndividualAggregator ();
      aggregator.individuals_changed.connect ((added, removed, m, a, r) =>
        {
          var new_alias = "New Alias";

          foreach (Individual i in added)
            {
              /* We only check one */
              if (i.id != (this.individual_id_prefix + "olivier@example.com"))
                {
                  continue;
                }

              /* Check properties */
              assert (i.alias != new_alias);

              i.notify["alias"].connect ((s, p) =>
                  {
                    /* we can't re-use i here due to Vala's implementation */
                    var ind = (Individual) s;

                    if (ind.alias == new_alias)
                      alias_notified = true;
                  });

              /* the contact list this aggregator is based upon has exactly 1
               * Tpf.Persona per Individual */
              var persona = i.personas.data;
              assert (persona is Tpf.Persona);

              /* set the alias through Telepathy and wait for it to hit our
               * alias notification callback above */

              ((Tpf.Persona) persona).alias = new_alias;
            }

          assert (removed == null);
        });
      aggregator.prepare ();

      /* Kill the main loop after a few seconds. If the alias hasn't been
       * notified, something along the way failed or been too slow (which we can
       * consider to be failure). */
      Timeout.add_seconds (3, () =>
        {
          main_loop.quit ();
          return false;
        });

      main_loop.run ();

      assert (alias_notified);

      /* necessary to reset the aggregator for the next test */
      aggregator = null;
    }

  public void test_individual_properties_change_alias_through_test_cm ()
    {
      var main_loop = new GLib.MainLoop (null, false);
      var alias_notified = false;

      /* Ignore the error caused by not running the logger */
      Test.log_set_fatal_handler ((d, l, m) =>
        {
          return !m.has_suffix ("couldn't get list of favourite contacts: " +
              "The name org.freedesktop.Telepathy.Logger was not provided by " +
              "any .service files");
        });

      /* Set up the aggregator */
      var aggregator = new IndividualAggregator ();
      aggregator.individuals_changed.connect ((added, removed, m, a, r) =>
        {
          var new_alias = "New Alias";

          foreach (Individual i in added)
            {
              /* We only check one */
              if (i.id != (this.individual_id_prefix + "olivier@example.com"))
                {
                  continue;
                }

              /* Check properties */
              assert (i.alias != new_alias);

              i.notify["alias"].connect ((s, p) =>
                  {
                    /* we can't re-use i here due to Vala's implementation */
                    var ind = (Individual) s;

                    if (ind.alias == new_alias)
                      alias_notified = true;
                  });

              /* the contact list this aggregator is based upon has exactly 1
               * Tpf.Persona per Individual */
              var persona = i.personas.data;
              assert (persona is Tpf.Persona);

              /* set the alias through Telepathy and wait for it to hit our
               * alias notification callback above */

              var handle = (Handle) ((Tpf.Persona) persona).contact.handle;
              this.conn.manager.set_alias (handle, new_alias);
            }

          assert (removed == null);
        });
      aggregator.prepare ();

      /* Kill the main loop after a few seconds. If the alias hasn't been
       * notified, something along the way failed or been too slow (which we can
       * consider to be failure). */
      Timeout.add_seconds (3, () =>
        {
          main_loop.quit ();
          return false;
        });

      main_loop.run ();

      assert (alias_notified);

      /* necessary to reset the aggregator for the next test */
      aggregator = null;
    }
}

public int main (string[] args)
{
  Test.init (ref args);

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new ContactPropertiesTests ().get_suite ());

  Test.run ();

  return 0;
}