# v 0.3.3 (7/17/2019)
* truncate DB timestamps

# v 0.3.2 (7/17/2019)
* Expose `Confirmable.confirm_user_unless_confirmed\1`
* Expose `Lockable.unlock_user\1`
* Switch from Poison to Jason

# v 0.3.1 (12/10/2019)
* run `mix format`

# v 0.3.0 (12/10/2019)
* Major Refactoring
  * Registerable
  * Database Authenticatable
  * Confirmable
  * Recoverable
  * Lockable
  * Approvable
* Support Phoenix 1.4

# v 0.2.8 (6/26/2018)
* fix infinite redirect issue

The plugs were calling sign_out and the error handler was calling signout, and then signout was erroring, calling error handler, then sign out...

# v 0.2.7 (6/26/2018)
* store_return_to_url
* redirect_after_sign_in

Generators have been updated to store the location (in the error_handler) and redirect on login (in session_controller and ueberauth_controller)

# v 0.2.6 (6/15/2018)
Database Authenticatable

# v 0.2.5 (6/12/2018)
* Update documentation
* Rescue an invalid token_id

# v 0.2.4 (6/12/2018)
Update token authentication to use constant-time comparison

see: http://blog.plataformatec.com.br/2013/08/devise-3-1-now-with-more-secure-defaults/

# v 0.2.3 (6/12/2018)
API Authentication

* Generator for API Authentication
* Add 'opaque' Guardian token

# v 0.2.2 (1/30/2018)
* Add Curator.Plug.LoadResource

# v 0.2.1 (1/30/2018)
* README.md formatting
* Package priv (for generators)

# v 0.2.0 (1/25/2018)
Rewrite - currently only supports an Ueberauth workflow (and timeouts). v0.3.0 will add support back for database authentication.

* Generators match Phoenix 1.3 structure
* Requires Guardian 1.0
* Configuration is now done at the module level (following the pattern established in Guardian)
* Ueberauth module & generator
* Timeoutable module & generator

# v 0.1.0

Initial Release
