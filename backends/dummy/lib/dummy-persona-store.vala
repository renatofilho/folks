/*
 * Copyright (C) 2013 Philip Withnall
 * Copyright (C) 2013 Canonical Ltd
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
 *       Philip Withnall <philip@tecnocode.co.uk>
 *       Renato Araujo Oliveira Filho <renato@canonical.com>
 */

using Folks;
using Gee;
using GLib;

/**
 * A persona store which allows {@link FolksDummy.Persona}s to be
 * programmatically created and manipulated, for the purposes of testing the
 * core of libfolks itself.
 *
 * TODO: Mock functions
 * TODO: Unstable API
 *
 * TODO
 *
 * TODO: trust_level and is_user_set_default can be set as normal properties
 *
 * @since UNRELEASED
 */
public class FolksDummy.PersonaStore : Folks.PersonaStore
{
  private bool _is_prepared = false;
  private bool _prepare_pending = false;
  private bool _is_quiescent = false;
  private bool _quiescent_on_prepare = false;
  private int  _contact_id = 0;

  /**
   * The type of persona store this is.
   *
   * See {@link Folks.PersonaStore.type_id}.
   *
   * @since UNRELEASED
   */
  public override string type_id { get { return BACKEND_NAME; } }

  private MaybeBool _can_add_personas = MaybeBool.FALSE;

  /**
   * Whether this PersonaStore can add {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_add_personas}.
   *
   * @since UNRELEASED
   */
  public override MaybeBool can_add_personas
    {
      get
        {
          if (!this._is_prepared)
            {
              return MaybeBool.FALSE;
            }

          return this._can_add_personas;
        }
    }

  private MaybeBool _can_alias_personas = MaybeBool.FALSE;

  /**
   * Whether this PersonaStore can set the alias of {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_alias_personas}.
   *
   * @since UNRELEASED
   */
  public override MaybeBool can_alias_personas
    {
      get
        {
          if (!this._is_prepared)
            {
              return MaybeBool.FALSE;
            }

          return this._can_alias_personas;
        }
    }

  /**
   * Whether this PersonaStore can set the groups of {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_group_personas}.
   *
   * @since UNRELEASED
   */
  public override MaybeBool can_group_personas
    {
      get
        {
          return ("groups" in this._always_writeable_properties)
              ? MaybeBool.TRUE : MaybeBool.FALSE;
        }
    }

  private MaybeBool _can_remove_personas = MaybeBool.FALSE;

  /**
   * Whether this PersonaStore can remove {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_remove_personas}.
   *
   * @since UNRELEASED
   */
  public override MaybeBool can_remove_personas
    {
      get
        {
          if (!this._is_prepared)
            {
              return MaybeBool.FALSE;
            }

          return this._can_remove_personas;
        }
    }

  /**
   * Whether this PersonaStore has been prepared.
   *
   * See {@link Folks.PersonaStore.is_prepared}.
   *
   * @since UNRELEASED
   */
  public override bool is_prepared
    {
      get { return this._is_prepared; }
    }

  private string[] _always_writeable_properties = {};
  private static string[] _always_writeable_properties_empty = {}; /* oh Vala */

  /**
   * {@inheritDoc}
   *
   * @since UNRELEASED
   */
  public override string[] always_writeable_properties
    {
      get
        {
          if (!this._is_prepared)
            {
              return PersonaStore._always_writeable_properties_empty;
            }

          return this._always_writeable_properties;
        }
    }

  /*
   * Whether this PersonaStore has reached a quiescent state.
   *
   * See {@link Folks.PersonaStore.is_quiescent}.
   *
   * @since UNRELEASED
   */
  public override bool is_quiescent
    {
      get { return this._is_quiescent; }
    }

  private HashMap<string, Persona> _personas;
  private Map<string, Persona> _personas_ro;

  /* Personas which have been registered but not yet emitted in a
   * personas-changed signal. */
  private HashSet<Persona> _pending_persona_registrations;

  /* Personas which have been unregistered but not yet emitted in a
   * personas-changed signal. */
  private HashSet<Persona> _pending_persona_unregistrations;

  /* Freeze counter for persona changes: personas-changed is only emitted when
   * this is 0. */
  private uint _persona_changes_frozen = 0;

  /**
   * The {@link Persona}s exposed by this PersonaStore.
   *
   * See {@link Folks.PersonaStore.personas}.
   *
   * @since UNRELEASED
   */
  public override Map<string, Persona> personas
    {
      get { return this._personas_ro; }
    }

  /**
   * Create a new persona store.
   *
   * This store will have no personas to begin with; use
   * {@link FolksDummy.PersonaStore.register_personas} to add some, then call
   * {@link FolksDummy.PersonaStore.reach_quiescence} to signal the store
   * reaching quiescence.
   *
   * @param id The new store's ID.
   * @param display_name The new store's display name.
   * @param always_writeable_properties The set of always writeable properties.
   *
   * @since UNRELEASED
   */
  public PersonaStore (string id, string display_name,
      string[] always_writeable_properties)
    {
      Object (
          id: id,
          display_name: display_name);

      this._always_writeable_properties = always_writeable_properties;
    }

  construct
    {
      this._personas = new HashMap<string, Persona> ();
      this._personas_ro = this._personas.read_only_view;
      this._pending_persona_registrations = new HashSet<Persona> ();
      this._pending_persona_unregistrations = new HashSet<Persona> ();
    }

  /**
   * Delay for the given number of milliseconds.
   *
   * This implements an asynchronous delay (which should be yielded on) until
   * the given number of milliseconds has elapsed.
   *
   * If ``delay`` is negative, this function returns immediately. If it is
   * zero, this function returns in an idle callback.
   *
   * @param delay number of milliseconds to delay for
   * @since UNRELEASED
   */
  private async void _implement_mock_delay (int delay)
    {
      if (delay < 0)
        {
          /* No delay. */
          return;
        }
      else if (delay == 0)
        {
          /* Idle delay. */
          Idle.add (() =>
            {
              this._implement_mock_delay.callback ();
              return false;
            });

          yield;
        }
      else
        {
          /* Timed delay. */
          Timeout.add (delay, () =>
            {
              this._implement_mock_delay.callback ();
              return false;
            });

          yield;
        }
    }

  /**
   * Type of a mock function for {@link PersonaStore.add_persona_from_details}.
   *
   * See {@link FolksDummy.PersonaStore.add_persona_from_details_mock}.
   *
   * @param persona the persona being added to the store, as constructed from
   * the details passed to {@link PersonaStore.add_persona_from_details}.
   * @throws PersonaStoreError to be thrown from
   * {@link PersonaStore.add_persona_from_details}
   * @returns delay to apply to the add persona operation (negative delays
   * complete synchronously; zero delays complete in an idle callback; positive
   * delays complete after that many milliseconds)
   * @since UNRELEASED
   */
  public delegate int AddPersonaFromDetailsMock (Persona persona)
      throws PersonaStoreError;

  /**
   * Mock function for {@link PersonaStore.add_persona_from_details}.
   *
   * This function is called whenever this store's
   * {@link PersonaStore.add_persona_from_details} method is called. It allows
   * the caller to determine whether adding the given persona should fail, by
   * throwing an error from this mock function. If no error is thrown from this
   * function, adding the given persona will succeed. This is useful for testing
   * error handling of calls to {@link PersoneStore.add_persona_from_details}.
   *
   * The value returned by this function gives a delay which is imposed for
   * completion of the {@link PersonaStore.add_persona_from_details} call.
   * Negative delays result in the call completing synchronously, zero delays
   * result in completion in an idle callback, and positive delays result in
   * completion after that many milliseconds.
   *
   * If this is ``null``, all calls to
   * {@link PersonaStore.add_persona_from_details} will succeed.
   *
   * This mock function may be changed at any time; changes will take effect for
   * the next call to {@link PersonaStore.add_persona_from_details}.
   *
   * @since UNRELEASED
   */
  public unowned AddPersonaFromDetailsMock? add_persona_from_details_mock
    {
      get; set; default = null;
    }

  /**
   * Add a new {@link Persona} to the PersonaStore.
   *
   * Accepted keys for ``details`` are:
   * - PersonaStore.detail_key (PersonaDetail.AVATAR)
   * - PersonaStore.detail_key (PersonaDetail.BIRTHDAY)
   * - PersonaStore.detail_key (PersonaDetail.EMAIL_ADDRESSES)
   * - PersonaStore.detail_key (PersonaDetail.FULL_NAME)
   * - PersonaStore.detail_key (PersonaDetail.GENDER)
   * - PersonaStore.detail_key (PersonaDetail.IM_ADDRESSES)
   * - PersonaStore.detail_key (PersonaDetail.IS_FAVOURITE)
   * - PersonaStore.detail_key (PersonaDetail.PHONE_NUMBERS)
   * - PersonaStore.detail_key (PersonaDetail.POSTAL_ADDRESSES)
   * - PersonaStore.detail_key (PersonaDetail.ROLES)
   * - PersonaStore.detail_key (PersonaDetail.STRUCTURED_NAME)
   * - PersonaStore.detail_key (PersonaDetail.LOCAL_IDS)
   * - PersonaStore.detail_key (PersonaDetail.WEB_SERVICE_ADDRESSES)
   * - PersonaStore.detail_key (PersonaDetail.NOTES)
   * - PersonaStore.detail_key (PersonaDetail.URLS)
   *
   * See {@link Folks.PersonaStore.add_persona_from_details}.
   *
   * @throws Folks.PersonaStoreError.STORE_OFFLINE if the store hasn’t been
   * prepared
   * @throws Folks.PersonaStoreError.CREATE_FAILED if creating the persona in
   * the dummy store failed
   *
   * @since UNRELEASED
   */
  public override async Folks.Persona? add_persona_from_details (
      HashTable<string, Value?> details) throws PersonaStoreError
    {
      /* We have to have called prepare() beforehand. */
      if (!this._is_prepared)
        {
          throw new PersonaStoreError.STORE_OFFLINE (
              "Persona store has not yet been prepared.");
        }

      /* Allow overriding the class used. */
      var contact_id = this._contact_id.to_string();
      this._contact_id++;
      var uid = Folks.Persona.build_uid (BACKEND_NAME, this.id, contact_id);
      var iid = this.id + ":" + contact_id;

      var persona = Object.new (this._persona_type,
          "display-id", contact_id,
          "uid", uid,
          "iid", iid,
          "store", this,
          "is-user", false,
          null) as FolksDummy.Persona;
      assert (persona != null);
      persona.update_writeable_properties (this.always_writeable_properties);

      var iter = HashTableIter<string, Value?> (details);
      unowned string k;
      unowned Value? _v;

      while (iter.next (out k, out _v) == true)
        {
          if (_v == null)
            {
              continue;
            }
          unowned Value v = (!) _v;

          if (k == Folks.PersonaStore.detail_key (
                PersonaDetail.FULL_NAME))
            {
              var _persona = persona as NameDetails;
              if (_persona != null) 
                {
                  string? full_name = v.get_string ();
                  string _full_name = "";
                  if (full_name != null)
                    {
                      _full_name = (!) full_name;
                    }
                  _persona.full_name = _full_name;
                }
            }
          else if (k == Folks.PersonaStore.detail_key (
                PersonaDetail.EMAIL_ADDRESSES))
            {
              var _persona = persona as EmailDetails;
              if (_persona != null)
                {
                  Set<EmailFieldDetails> email_addresses =
                      (Set<EmailFieldDetails>) v.get_object ();
                  if (email_addresses != null)
                    {
                      _persona.email_addresses =  email_addresses;
                    }             
                }
            }
          else if (k == Folks.PersonaStore.detail_key (PersonaDetail.AVATAR))
            {
              var _persona = persona as AvatarDetails;
              if (_persona != null)
                {
                  var avatar = (LoadableIcon?) v.get_object ();
                  if (avatar != null)
                    {
                      _persona.avatar = avatar;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (
                PersonaDetail.IM_ADDRESSES))
            {
              var _persona = persona as ImDetails;
              if (_persona != null)
                {
                  MultiMap<string,ImFieldDetails> im_addresses =
                    (MultiMap<string,ImFieldDetails>) v.get_object ();
                  if (im_addresses != null)
                    {
                      _persona.im_addresses = im_addresses;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (
                PersonaDetail.PHONE_NUMBERS))
            {
              var _persona = persona as PhoneDetails;
              if (_persona != null)
                {
                  Set<PhoneFieldDetails> phone_numbers =
                    (Set<PhoneFieldDetails>) v.get_object ();
                  if (phone_numbers != null)
                    {
                      _persona.phone_numbers = phone_numbers;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (
                PersonaDetail.POSTAL_ADDRESSES))
            {
              var _persona = persona as PostalAddressDetails;
              if (_persona != null)
                {
                  Set<PostalAddressFieldDetails> postal_fds =
                    (Set<PostalAddressFieldDetails>) v.get_object ();
                  if (postal_fds != null)
                    {
                      _persona.postal_addresses = postal_fds;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (
                PersonaDetail.STRUCTURED_NAME))
            {
              var _persona = persona as NameDetails;
              if (_persona != null) 
                {
                  StructuredName sname = (StructuredName) v.get_object ();
                  if (sname != null)
                    {
                      _persona.structured_name = sname;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (PersonaDetail.LOCAL_IDS))
            {
              var _persona = persona as LocalIdDetails;
              if (_persona != null)
                {
                  Set<string> local_ids = (Set<string>) v.get_object ();
                  if (local_ids != null)
                    {
                      _persona.local_ids = local_ids;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key
              (PersonaDetail.WEB_SERVICE_ADDRESSES))
            {
              var _persona = persona as WebServiceDetails;
              if (_persona != null)
                {
                  var web_service_addresses =
                      (HashMultiMap<string, WebServiceFieldDetails>) v.get_object ();
                  if (web_service_addresses != null)
                    {
                      _persona.web_service_addresses = web_service_addresses;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (PersonaDetail.NOTES))
            {
              var _persona = persona as NoteDetails;
              if (_persona != null)
                {
                  var notes = (Gee.HashSet<NoteFieldDetails>) v.get_object ();
                  if (notes != null)
                    {
                      _persona.notes = notes;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (PersonaDetail.GENDER))
            {
              var _persona = persona as GenderDetails;
              if (_persona != null)
                {
                  var gender = (Gender) v.get_enum ();
                  _persona.gender = gender;
                }
            }
          else if (k == Folks.PersonaStore.detail_key (PersonaDetail.URLS))
            {
              var _persona = persona as UrlDetails;
              if (_persona != null)
                {
                  Set<UrlFieldDetails> urls = (Set<UrlFieldDetails>) v.get_object ();
                  if (urls != null)
                    {
                      _persona.urls = urls;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (PersonaDetail.BIRTHDAY))
            {
              var _persona = persona as BirthdayDetails;
              if (_persona != null)
                {
                  var birthday = (DateTime?) v.get_boxed ();
                  if (birthday != null)
                    {
                      _persona.birthday = birthday;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (PersonaDetail.ROLES))
            {
              var _persona = persona as RoleDetails;
              if (_persona != null)
                {
                  Set<RoleFieldDetails> roles =
                      (Set<RoleFieldDetails>) v.get_object ();
                  if (roles != null)
                    {
                      _persona.roles = roles;
                    }
                }
            }
          else if (k == Folks.PersonaStore.detail_key (
                  PersonaDetail.IS_FAVOURITE))
            {
              var _persona = persona as FavouriteDetails;
              if (_persona != null)
                {
                  bool is_fav = v.get_boolean ();
                  _persona.is_favourite = is_fav;
                }
            }
          else if (k == Folks.PersonaStore.detail_key (
                   PersonaDetail.NICKNAME))
            {
              var _persona = persona as NameDetails;
              if (_persona != null)
                {
                  string? nickname = v.get_string ();
                  string _nickname = "";
                  if (nickname != null)
                    {
                      _nickname = (!) nickname;
                    }
                  _persona.nickname = _nickname;
                }
            }
        }

      /* Allow the caller to inject failures and delays into
       * add_persona_from_details() by providing a mock function. */
      if (this.add_persona_from_details_mock != null)
        {
          var delay = this.add_persona_from_details_mock (persona);
          yield this._implement_mock_delay (delay);
        }

      /* No simulated failure: continue adding the persona. */
      this._personas.set (persona.iid, persona);

      /* Notify of the new persona. */
      var added_personas = new HashSet<Persona> ();
      added_personas.add (persona);
      this._emit_personas_changed (added_personas, null);

      return persona;
    }

  /**
   * Type of a mock function for {@link PersonaStore.remove_persona}.
   *
   * See {@link FolksDummy.PersonaStore.remove_persona_mock}.
   *
   * @param persona the persona being removed from the store
   * @throws PersonaStoreError to be thrown from
   * {@link PersonaStore.remove_persona}
   * @returns delay to apply to the remove persona operation (negative delays
   * complete synchronously; zero delays complete in an idle callback; positive
   * delays complete after that many milliseconds)
   * @since UNRELEASED
   */
  public delegate int RemovePersonaMock (Persona persona)
      throws PersonaStoreError;

  /**
   * Mock function for {@link PersonaStore.remove_persona}.
   *
   * This function is called whenever this store's
   * {@link PersonaStore.remove_persona} method is called. It allows
   * the caller to determine whether removing the given persona should fail, by
   * throwing an error from this mock function. If no error is thrown from this
   * function, removing the given persona will succeed. This is useful for
   * testing error handling of calls to {@link PersoneStore.remove_persona}.
   *
   * The value returned by this function gives a delay which is imposed for
   * completion of the {@link PersonaStore.remove_persona} call.
   * Negative delays result in the call completing synchronously, zero delays
   * result in completion in an idle callback, and positive delays result in
   * completion after that many milliseconds.
   *
   * If this is ``null``, all calls to {@link PersonaStore.remove_persona} will
   * succeed.
   *
   * This mock function may be changed at any time; changes will take effect for
   * the next call to {@link PersonaStore.remove_persona}.
   *
   * @since UNRELEASED
   */
  public unowned RemovePersonaMock? remove_persona_mock
    {
      get; set; default = null;
    }

  /**
   * Remove a {@link Persona} from the PersonaStore.
   *
   * See {@link Folks.PersonaStore.remove_persona}.
   *
   * @param persona the persona that should be removed
   * @throws Folks.PersonaStoreError.STORE_OFFLINE if the store hasn’t been
   * prepared or has gone offline
   * @throws Folks.PersonaStoreError.PERMISSION_DENIED if the store denied
   * permission to delete the contact
   * @throws Folks.PersonaStoreError.READ_ONLY if the store is read only
   * @throws Folks.PersonaStoreError.REMOVE_FAILED if any other errors happened
   * in the store
   *
   * @since UNRELEASED
   */
  public override async void remove_persona (Folks.Persona persona)
      throws PersonaStoreError
      requires (persona is FolksDummy.Persona)
    {
      /* We have to have called prepare() beforehand. */
      if (!this._is_prepared)
        {
          throw new PersonaStoreError.STORE_OFFLINE (
              "Persona store has not yet been prepared.");
        }

      /* Allow the caller to inject failures and delays. */
      if (this.remove_persona_mock != null)
        {
          var delay = this.remove_persona_mock ((FolksDummy.Persona) persona);
          yield this._implement_mock_delay (delay);
        }

      Persona? _persona = this._personas.get (persona.iid);
      if (_persona != null)
        {
          this._personas.unset (persona.iid);

          /* Handle the case where a contact is removed while persona changes
           * are frozen. */
          this._pending_persona_registrations.remove ((!) _persona);
          this._pending_persona_unregistrations.remove ((!) _persona);

          /* Notify of the removal. */
          var removed_personas = new HashSet<Folks.Persona> ();
          removed_personas.add ((!) persona);
          this._emit_personas_changed (null, removed_personas);
        }
    }

  /**
   * Type of a mock function for {@link PersonaStore.prepare}.
   *
   * See {@link FolksDummy.PersonaStore.prepare_mock}.
   *
   * @throws PersonaStoreError to be thrown from {@link PersonaStore.prepare}
   * @returns delay to apply to the prepare operation (negative delays
   * complete synchronously; zero delays complete in an idle callback; positive
   * delays complete after that many milliseconds)
   * @since UNRELEASED
   */
  public delegate int PrepareMock () throws PersonaStoreError;

  /**
   * Mock function for {@link PersonaStore.prepare}.
   *
   * This function is called whenever this store's
   * {@link PersonaStore.prepare} method is called on an unprepared store. It
   * allows the caller to determine whether preparing the store should fail, by
   * throwing an error from this mock function. If no error is thrown from this
   * function, preparing the store will succeed (and all future calls to
   * {@link PersonaStore.prepare} will return immediately without calling this
   * mock function). This is useful for testing error handling of calls to
   * {@link PersoneStore.prepare}.
   *
   * The value returned by this function gives a delay which is imposed for
   * completion of the {@link PersonaStore.prepare} call.
   * Negative delays result in the call completing synchronously, zero delays
   * result in completion in an idle callback, and positive delays result in
   * completion after that many milliseconds.
   *
   * If this is ``null``, all calls to {@link PersonaStore.prepare} will
   * succeed.
   *
   * This mock function may be changed at any time; changes will take effect for
   * the next call to {@link PersonaStore.prepare}.
   *
   * @since UNRELEASED
   */
  public unowned PrepareMock? prepare_mock
    {
      get; set; default = null;
    }

  /**
   * Prepare the PersonaStore for use.
   *
   * See {@link Folks.PersonaStore.prepare}.
   *
   * @throws Folks.PersonaStoreError.STORE_OFFLINE if the store is offline
   * @throws Folks.PersonaStoreError.PERMISSION_DENIED if permission was denied
   * to open the store
   * @throws Folks.PersonaStoreError.INVALID_ARGUMENT if any other error
   * occurred in the store
   *
   * @since UNRELEASED
   */
  public override async void prepare () throws PersonaStoreError
    {
      Internal.profiling_start ("preparing Dummy.PersonaStore (ID: %s)",
          this.id);

      if (this._is_prepared == true || this._prepare_pending == true)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;

          /* Allow the caller to inject failures and delays. */
          if (this.prepare_mock != null)
            {
              var delay = this.prepare_mock ();
              yield this._implement_mock_delay (delay);
            }

          this._is_prepared = true;
          this.notify_property ("is-prepared");

          /* If reach_quiescence() has been called already, signal
           * quiescence. */
          if (this._quiescent_on_prepare == true)
            {
              this.reach_quiescence ();
            }
        }
      finally
        {
          this._prepare_pending = false;
        }

      Internal.profiling_end ("preparing Dummy.PersonaStore");
    }


  /*
   * All the functions below here are to be used by testing code rather than by
   * libfolks clients. They form the interface which would normally be between
   * the PersonaStore and a web service or backing store of some kind.
   */


  private Type _persona_type = typeof (FolksDummy.Persona);

  /**
   * Type of programmatically created personas.
   *
   * This is the type used to create new personas when
   * {@link PersonaStore.add_persona_from_details} is called. It must be a
   * subtype of {@link FolksDummy.Persona}.
   *
   * This may be modified at any time, with modifications taking effect for the
   * next call to {@link PersonaStore.add_persona_from_details} or
   * {@link PersonaStore.register_personas}.
   *
   * @since UNRELEASED
   */
  public Type persona_type
    {
      get { return this._persona_type; }
      set
        {
          assert (value.is_a (typeof (FolksDummy.Persona)));
          if (this._persona_type != value)
            {
              this._persona_type = value;
              this.notify_property ("persona-type");
            }
        }
    }

  /**
   * Set capabilities of the persona store.
   *
   * This sets the capabilities of the store, as if they were changed on a
   * backing store somewhere. This is intended to be used for testing code which
   * depends on the values of {@link PersonaStore.can_add_personas},
   * {@link PersonaStore.can_alias_personas} and
   * {@link PersonaStore.can_remove_personas}.
   *
   * @param can_add_personas whether the store can handle adding personas
   * @param can_alias_personas whether the store can handle and update
   * user-specified persona aliases
   * @param can_remove_personas whether the store can handle removing personas
   * @since UNRELEASED
   */
  public void set_capabilities (MaybeBool can_add_personas,
      MaybeBool can_alias_personas, MaybeBool can_remove_personas)
    {
      this.freeze_notify ();

      if (can_add_personas != this._can_add_personas)
        {
          this._can_add_personas = can_add_personas;
          this.notify_property ("can-add-personas");
        }

      if (can_alias_personas != this._can_alias_personas)
        {
          this._can_alias_personas = can_alias_personas;
          this.notify_property ("can-alias-personas");
        }

      if (can_remove_personas != this._can_remove_personas)
        {
          this._can_remove_personas = can_remove_personas;
          this.notify_property ("can-remove-personas");
        }

      this.thaw_notify ();
    }

  /**
   * Freeze persona changes in the store.
   *
   * This freezes externally-visible changes to the set of personas in the store
   * until {@link PersonaStore.thaw_persona_changes} is called, at which point
   * all pending changes are made visible in the {@link PersonaStore.personas}
   * property and by emitting {@link PersonaStore.personas_changed}.
   *
   * Calls to {@link PersonaStore.freeze_persona_changes} and
   * {@link PersonaStore.thaw_persona_changes} must be well-nested. Pending
   * changes will only be committed after the final call to
   * {@link PersonaStore.thaw_persona_changes}.
   *
   * @see PersonaStore.thaw_persona_changes
   * @since UNRELEASED
   */
  public void freeze_persona_changes ()
    {
      this._persona_changes_frozen++;
    }

  /**
   * Thaw persona changes in the store.
   *
   * This thaws externally-visible changes to the set of personas in the store.
   * If the number of calls to {@link PersonaStore.thaw_persona_changes} matches
   * the number of calls to {@link PersonaStore.freeze_persona_changes}, all
   * pending changes are committed and made externally-visible.
   *
   * @see PersonaStore.freeze_persona_changes
   * @since UNRELEASED
   */
  public void thaw_persona_changes ()
    {
      assert (this._persona_changes_frozen > 0);
      this._persona_changes_frozen--;

      if (this._persona_changes_frozen == 0)
        {
          /* Emit the queued changes. */
          this._emit_personas_changed (this._pending_persona_registrations,
              this._pending_persona_unregistrations);

          this._pending_persona_registrations.clear ();
          this._pending_persona_unregistrations.clear ();
        }
    }

  /**
   * Register new personas with the persona store.
   *
   * This registers a set of personas as if they had just appeared in the
   * backing store. If the persona store is not frozen (see
   * {@link PersonaStore.freeze_persona_changes}) the changes are made
   * externally visible on the store immediately (e.g. in the
   * {@link PersonaStore.personas} property and through a
   * {@link PersonaStore.personas_changed} signal). If the store is frozen, the
   * changes will be pending until the store is next unfrozen.
   *
   * All elements in the @personas set be of type
   * {@link PersonaStore.persona_type}.
   *
   * @param personas set of personas to register
   * @since UNRELEASED
   */
  public void register_personas (Set<Persona> personas)
    {
      Set<Persona> added_personas;
      var emit_notifications = (this._persona_changes_frozen == 0);

      /* If the persona store has persona changes frozen, queue up the
       * personas and emit a notification about them later. */
      if (emit_notifications == false)
          added_personas = this._pending_persona_registrations;
      else
          added_personas = new HashSet<Persona> ();

      foreach (var persona in personas)
        {
          assert (persona.get_type ().is_a (this._persona_type));

          /* Handle the case where a persona is unregistered while the store is
           * frozen, then registered again before it's unfrozen. */
          if (this._pending_persona_unregistrations.remove (persona))
              this._personas.unset (persona.iid);

          if (this._personas.has_key (persona.iid))
              continue;

          added_personas.add (persona);
          if (emit_notifications == true)
              this._personas.set (persona.iid, persona);
        }

      if (added_personas.size > 0 && emit_notifications == true)
          this._emit_personas_changed (added_personas, null);
    }

  /**
   * Unregister existing personas with the persona store.
   *
   * This unregisters a set of personas as if they had just disappeared from the
   * backing store. If the persona store is not frozen (see
   * {@link PersonaStore.freeze_persona_changes}) the changes are made
   * externally visible on the store immediately (e.g. in the
   * {@link PersonaStore.personas} property and through a
   * {@link PersonaStore.personas_changed} signal). If the store is frozen, the
   * changes will be pending until the store is next unfrozen.
   *
   * @param personas set of personas to unregister
   * @since UNRELEASED
   */
  public void unregister_personas (Set<Persona> personas)
    {
      Set<Persona> removed_personas;
      var emit_notifications = (this._persona_changes_frozen == 0);

      /* If the persona store has persona changes frozen, queue up the
       * personas and emit a notification about them later. */
      if (emit_notifications == false)
          removed_personas = this._pending_persona_unregistrations;
      else
          removed_personas = new HashSet<Persona> ();

      foreach (var _persona in personas)
        {
          /* Handle the case where a persona is registered while the store is
           * frozen, then unregistered before it's unfrozen. */
          this._pending_persona_registrations.remove (_persona);

          Persona? persona = this._personas.get (_persona.iid);
          if (persona == null)
              continue;

          removed_personas.add ((!) persona);
          if (emit_notifications == true)
              this._personas.unset (((!) persona).iid);
        }

       if (removed_personas.size > 0 && emit_notifications == true)
           this._emit_personas_changed (null, removed_personas);
    }

  /**
   * Reach quiescence on the store.
   *
   * If the {@link PersonaStore.prepare} method has already been called on the
   * store, this causes the store to signal that it has reached quiescence
   * immediately. If the store has not yet been prepared, this will set a flag
   * to ensure that quiescence is reached as soon as
   * {@link PersonaStore.prepare} is called.
   *
   * @since UNRELEASED
   */
  public void reach_quiescence ()
    {
      /* Can't reach quiescence until prepare() has been called. */
      if (this._is_prepared == false)
        {
          this._quiescent_on_prepare = true;
          return;
        }

      /* The initial query is complete, so signal that we've reached
       * quiescence (even if there was an error). */
      if (this._is_quiescent == false)
        {
          this._is_quiescent = true;
          this.notify_property ("is-quiescent");
        }
    }
}
