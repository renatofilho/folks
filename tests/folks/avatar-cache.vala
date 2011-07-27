/*
 * Copyright (C) 2011 Philip Withnall
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
 */

using GLib;
using Gee;
using Folks;

public class AvatarCacheTests : Folks.TestCase
{
  private AvatarCache _cache;
  private File _cache_dir;
  private LoadableIcon _avatar;
  private MainLoop _main_loop;

  public AvatarCacheTests ()
    {
      base ("AvatarCache");

      /* Use a temporary cache directory */
      this._cache_dir =
          File.new_for_path (Environment.get_tmp_dir ()).
              get_child ("folks-avatar-cache-tests");

      this.add_test ("store-and-load-avatar", this.test_store_and_load_avatar);
      this.add_test ("store-avatar-overwrite",
          this.test_store_avatar_overwrite);
      this.add_test ("load-avatar-non-existent",
          this.test_load_avatar_non_existent);
      this.add_test ("remove-avatar", this.test_remove_avatar);
      this.add_test ("remove-avatar-non-existent",
          this.test_remove_avatar_non_existent);
      this.add_test ("build-uri-for-avatar", this.test_build_uri_for_avatar);
    }

  public override void set_up ()
    {
      this._delete_cache_directory ();
      Environment.set_variable ("XDG_CACHE_HOME", this._cache_dir.get_path (),
          true);

      this._cache = AvatarCache.dup ();
      this._avatar =
          new FileIcon (File.new_for_path (
              Environment.get_variable ("AVATAR_FILE_PATH")));

      this._main_loop = new GLib.MainLoop (null, false);
    }

  public override void tear_down ()
    {
      this._main_loop = null;
      this._avatar = null;
      this._cache = null;
      this._delete_cache_directory ();
    }

  protected void _delete_directory (File dir) throws GLib.Error
    {
      // Delete the files in the directory
      var enumerator =
          dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME,
              FileQueryInfoFlags.NONE);

      FileInfo? file_info = enumerator.next_file ();
      while (file_info != null)
        {
          var child_file = dir.get_child (file_info.get_name ());

          if (child_file.query_file_type (FileQueryInfoFlags.NONE) ==
                  FileType.DIRECTORY)
            {
              this._delete_directory (child_file);
            }
          else
            {
              child_file.delete ();
            }

          file_info = enumerator.next_file ();
        }
      enumerator.close ();

      // Delete the directory itself
      dir.delete ();
    }

  protected void _delete_cache_directory ()
    {
      try
        {
          this._delete_directory (this._cache_dir);
        }
      catch (Error e)
        {
          // Ignore it
        }
    }

  protected bool _avatars_equal (LoadableIcon avatar1,
      LoadableIcon avatar2)
    {
      if (avatar1.equal (avatar2) == true)
        {
          return true;
        }

      // Compare content instead.
      try
        {
          var stream1 = avatar1.load (-1, null, null);
          var stream2 = avatar2.load (-1, null, null);

          var content1 = new uint8[512];
          var content2 = new uint8[512];

          ssize_t read1 = -1;
          do
            {
              read1 = stream1.read (content1, null);
              var read2 = stream2.read (content2, null);

              if (read1 != read2 || Memory.cmp (content1, content2, read1) != 0)
                {
                  return false;
                }
            }
          while (read1 > 0);
        }
      catch (GLib.Error e)
        {
          return false;
        }

      return true;
    }

  protected void _assert_store_avatar (string id, LoadableIcon avatar)
    {
      this._cache.store_avatar.begin (id, avatar, (obj, res) =>
        {
          try
            {
              this._cache.store_avatar.end (res);
            }
          catch (GLib.Error e)
            {
              error ("Error storing avatar: %s", e.message);
            }

          this._main_loop.quit ();
        });

      this._main_loop.run ();
    }

  protected LoadableIcon? _assert_load_avatar (string id)
    {
      LoadableIcon? avatar = null;

      this._cache.load_avatar.begin (id, (obj, res) =>
        {
          try
            {
              avatar = this._cache.load_avatar.end (res);
            }
          catch (GLib.Error e)
            {
              error ("Error loading avatar: %s", e.message);
            }

          this._main_loop.quit ();
        });

      this._main_loop.run ();

      return avatar;
    }

  protected void _assert_remove_avatar (string id)
    {
      this._cache.remove_avatar.begin (id, (obj, res) =>
        {
          try
            {
              this._cache.remove_avatar.end (res);
            }
          catch (GLib.Error e)
            {
              error ("Error removing avatar: %s", e.message);
            }

          this._main_loop.quit ();
        });

      this._main_loop.run ();
    }

  public void test_store_and_load_avatar ()
    {
      // Store the avatar.
      this._assert_store_avatar ("test-store-avatar-id", this._avatar);

      // Load it again.
      var avatar = this._assert_load_avatar ("test-store-avatar-id");

      // Check the avatar's OK
      assert (avatar != null);
      assert (avatar is LoadableIcon);
      assert (this._avatars_equal (this._avatar, avatar) == true);
    }

  public void test_store_avatar_overwrite ()
    {
      // Store the avatar twice.
      this._assert_store_avatar ("test-store-avatar-ow-id", this._avatar);
      this._assert_store_avatar ("test-store-avatar-ow-id", this._avatar);

      // Load it again.
      var avatar = this._assert_load_avatar ("test-store-avatar-ow-id");

      // Check the avatar's OK
      assert (avatar != null);
      assert (avatar is LoadableIcon);
      assert (this._avatars_equal (this._avatar, avatar) == true);
    }

  public void test_load_avatar_non_existent ()
    {
      // Load a non-existent avatar.
      var avatar = this._assert_load_avatar ("test-load-avatar-non-existent");
      assert (avatar == null);
    }

  public void test_remove_avatar ()
    {
      LoadableIcon? avatar = null;

      // Store the avatar.
      this._assert_store_avatar ("test-remove-avatar", this._avatar);

      // Check it's been stored OK.
      avatar = this._assert_load_avatar ("test-remove-avatar");
      assert (avatar != null);

      // Remove it.
      this._assert_remove_avatar ("test-remove-avatar");

      // Check it's been removed OK.
      avatar = this._assert_load_avatar ("test-remove-avatar");
      assert (avatar == null);
    }

  public void test_remove_avatar_non_existent ()
    {
      // Check the avatar doesn't exist.
      var avatar = this._assert_load_avatar ("test-remove-avatar-non-existent");
      assert (avatar == null);

      // Attempt to remove it.
      this._assert_remove_avatar ("test-remove-avatar-non-existent");
    }

  public void test_build_uri_for_avatar ()
    {
      // Basic checks on the constructed URI.
      var uri = this._cache.build_uri_for_avatar ("test-id");
      assert (uri != null);
      assert (Uri.parse_scheme (uri) != null); /* basic check for validity */
    }
}

public int main (string[] args)
{
  Test.init (ref args);

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new AvatarCacheTests ().get_suite ());

  Test.run ();

  return 0;
}

/* vim: filetype=vala textwidth=80 tabstop=2 expandtab: */