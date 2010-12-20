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

/**
 * The gender of a contact
 *
 * @since 0.3.UNRELEASED
 */
public enum Folks.Gender
{
  /**
   * The gender of the contact is unknown or the contact didn't specify it.
   */
  UNSPECIFIED,
  /**
   * The contact is male.
   */
  MALE,
  /**
   * The contact is female.
   */
  FEMALE
}

/**
 * Interface for specifying the gender of a contact.
 *
 * @since 0.3.UNRELEASED
 */
public interface Folks.GenderOwner : Object
{
  /**
   * The gender of the contact.
   *
   * @since 0.3.UNRELEASED
   */
  public abstract Gender gender { get; set; }
}