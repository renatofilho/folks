/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2012-2013 Collabora Ltd.
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
 *          Arun Raghavan <arun.raghavan@collabora.co.uk>
 *
 * Based on kf-backend-factory.vala by:
 *          Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *          Travis Reitter <travis.reitter@collabora.co.uk>
 *          Philip Withnall <philip.withnall@collabora.co.uk>
 */

using Folks;
using Folks.Backends.BlueZ;

private BackendFactory _backend_factory = null;

/**
 * The backend module entry point.
 *
 * @param backend_store the {@link BackendStore} to use in this factory.
 *
 * @since 0.9.6
 */
public void module_init (BackendStore backend_store)
{
  _backend_factory = new BackendFactory (backend_store);
}

/**
 * The backend module exit point.
 *
 * @param backend_store the {@link BackendStore} to use in this factory.
 *
 * @since 0.9.6
 */
public void module_finalize (BackendStore backend_store)
{
  _backend_factory = null;
}

/**
 * A backend factory to create a single {@link Backend}.
 *
 * @since 0.9.6
 */
public class Folks.Backends.BlueZ.BackendFactory : Object
{
  /**
   * {@inheritDoc}
   *
   * @since 0.9.6
   */
  public BackendFactory (BackendStore backend_store)
    {
      backend_store.add_backend (new Backend ());
    }
}
