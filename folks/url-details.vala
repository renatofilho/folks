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
 * Authors:
 *       Marco Barisione <marco.barisione@collabora.co.uk>
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 */

using GLib;
using Gee;

/**
 * Object representing a URL that can have some parameters associated with it.
 *
 * See {@link Folks.AbstractFieldDetails} for details on common parameter names
 * and values.
 *
 * @since 0.6.0
 */
public class Folks.UrlFieldDetails : AbstractFieldDetails<string>
{
  /**
   * Create a new UrlFieldDetails.
   *
   * @param value the value of the field
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A `null` value is equivalent to a
   * empty map of parameters.
   *
   * @return a new UrlFieldDetails
   *
   * @since 0.6.0
   */
  public UrlFieldDetails (string value,
      MultiMap<string, string>? parameters = null)
    {
      this.value = value;
      if (parameters != null)
        this.parameters = parameters;
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public override bool equal (AbstractFieldDetails<string> that)
    {
      return base.equal<string> (that);
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public override uint hash ()
    {
      return base.hash ();
    }
}

/**
 * Associates a list of URLs with a contact.
 *
 * @since 0.3.5
 */
public interface Folks.UrlDetails : Object
{
  /**
   * The websites of the contact.
   *
   * A list or websites associated to the contact.
   *
   * @since 0.5.1
   */
  public abstract Set<UrlFieldDetails> urls { get; set; }
}
