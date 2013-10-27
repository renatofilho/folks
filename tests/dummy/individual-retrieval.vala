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
 * Authors: Renato Araujo Oliveira Filho <renato@canonical.com>
 */

using Gee;
using Folks;
using DummyTest;
using Dummyf;

public class IndividualRetrievalTests : DummyTest.TestCase
{
  public IndividualRetrievalTests ()
    {
      base ("IndividualRetrieval");

      this.add_test ("dummy individuals", this.test_aggregator);
    }

  private Folks.Persona create_persona_rodrigo()
    {
      var rodrigo = new FatPersona(this.dummy_persona_store, "dummy@2");
      var main_loop = new GLib.MainLoop (null, false);

      rodrigo.change_full_name.begin("Rodrigo Almeida", (s, r) =>
            {
              try
                {
                  rodrigo.change_full_name.end(r);
                }
              catch (Folks.PropertyError e)
                {
                }
                main_loop.quit();
            });
      TestUtils.loop_run_with_timeout (main_loop);

      rodrigo.nickname = "kiko";
      rodrigo.change_nickname.begin("kiko", (s, r) =>
            {
              try
                {
                  rodrigo.change_nickname.end(r);
                }
              catch (Folks.PropertyError e)
                {
                }
                main_loop.quit();
            });
      TestUtils.loop_run_with_timeout (main_loop);

      // Emails
      var emails = new HashSet<EmailFieldDetails> (
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);

      var email_1 = new EmailFieldDetails ("rodrigo@gmail.com");
      email_1.set_parameter (AbstractFieldDetails.PARAM_TYPE,
          AbstractFieldDetails.PARAM_TYPE_HOME);
      emails.add (email_1);
      rodrigo.change_email_addresses.begin(emails, (s, r) =>
            {
              try
                {
                  rodrigo.change_email_addresses.end(r);
                }
              catch (Folks.PropertyError e)
                {
                }
                main_loop.quit();
            });
      TestUtils.loop_run_with_timeout (main_loop);

      //Ims
      var im_fds = new HashMultiMap<string, ImFieldDetails> ();
      im_fds.set ("jabber", new ImFieldDetails ("rodrigo@jabber.com"));
      im_fds.set ("yahoo", new ImFieldDetails ("rodrigo@yahoo.com"));
      rodrigo.change_im_addresses.begin(im_fds, (s, r) =>
            {
              try
                {
                  rodrigo.change_im_addresses.end(r);
                }
              catch (Folks.PropertyError e)
                {
                }
                main_loop.quit();
            });
      TestUtils.loop_run_with_timeout (main_loop);
      return rodrigo;
    }


  private Folks.Persona create_persona_renato()
    {
      var renato = new FatPersona(this.dummy_persona_store, "dummy@1");
      var main_loop = new GLib.MainLoop (null, false);

      renato.change_full_name.begin("Renato Araujo Oliveira Filho", (s, r) =>
            {
              try
                {
                  renato.change_full_name.end(r);
                }
              catch (Folks.PropertyError e)
                {                 
                  assert_not_reached ();
                }
                main_loop.quit();
            });
      TestUtils.loop_run_with_timeout (main_loop);

      renato.change_nickname.begin("renatofilho", (s, r) =>
            {
              try
                {
                  renato.change_nickname.end(r);
                }
              catch (Folks.PropertyError e)
                {
                }
                main_loop.quit();
            });
      TestUtils.loop_run_with_timeout (main_loop);

      // Emails
      var emails = new HashSet<EmailFieldDetails> (
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);

      var email_1 = new EmailFieldDetails ("renato@canonical.com");
      email_1.set_parameter (AbstractFieldDetails.PARAM_TYPE,
          AbstractFieldDetails.PARAM_TYPE_HOME);
      emails.add (email_1);
      renato.change_email_addresses.begin(emails, (s, r) =>
            {
              try
                {
                  renato.change_email_addresses.end(r);
                }
              catch (Folks.PropertyError e)
                {
                }
                main_loop.quit();
            });
      TestUtils.loop_run_with_timeout (main_loop);

      //Ims
      var im_fds = new HashMultiMap<string, ImFieldDetails> ();
      im_fds.set ("jabber", new ImFieldDetails ("renato@jabber.com"));
      im_fds.set ("yahoo", new ImFieldDetails ("renato@yahoo.com"));
      renato.change_im_addresses.begin(im_fds, (s, r) =>
            {
              try
                {
                  renato.change_im_addresses.end(r);
                }
              catch (Folks.PropertyError e)
                {
                }
                main_loop.quit();
            });
      TestUtils.loop_run_with_timeout (main_loop);

      return renato;
    }
    
  private void register_personas()
    {
      var personas = new HashSet<Folks.Persona>();
      var kiko = create_persona_rodrigo();
      GLib.debug("CREATED: %s\n", (kiko as NameDetails).nickname);
      personas.add(create_persona_renato());
      personas.add(create_persona_rodrigo());
      this.dummy_persona_store.register_personas (personas);
    }

  public void test_aggregator ()
    {
      var main_loop = new GLib.MainLoop (null, false);

      HashSet<string> expected_individuals = new HashSet<string> ();
      expected_individuals.add("Renato Araujo Oliveira Filho");
      expected_individuals.add("Rodrigo Almeida");

      /* Set up the aggregator */
      var aggregator = new IndividualAggregator ();
      aggregator.individuals_changed_detailed.connect ((changes) =>
        {
          var added = changes.get_values ();
          var removed = changes.get_keys ();

          assert (added.size == 2);

          foreach (Individual i in added)
            {
              assert (i != null);
              expected_individuals.remove (i.full_name);
            }

          assert (removed.size == 1);

          main_loop.quit();
        });

      /* Kill the main loop after a few seconds. If there are still individuals
       * in the set of expected individuals, the aggregator has either failed or
       * been too slow (which we can consider to be failure). */

      Idle.add (() =>
        {
          aggregator.prepare.begin ((s,r) =>
            {
              try
                {
                  aggregator.prepare.end (r);
                  this.dummy_persona_store.reach_quiescence ();
                  register_personas();
                }
              catch (GLib.Error e1)
                {
                  GLib.critical ("failed to prepare aggregator: %s",
                    e1.message);
                  assert_not_reached ();
                }
            });

          return false;
        });

      TestUtils.loop_run_with_timeout (main_loop);

      /* We should have enumerated exactly the individuals in the set */
      assert (expected_individuals.size == 0);

      /* necessary to reset the aggregator for the next test */
      aggregator = null;
    }
}

public int main (string[] args)
{
  Test.init (ref args);

  var tests = new IndividualRetrievalTests ();
  tests.register ();
  Test.run ();
  tests.final_tear_down ();

  return 0;
}
