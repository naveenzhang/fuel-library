# This installs a MongoDB server. See README.md for more details.
class mongodb::server (
  $ensure           = $mongodb::params::ensure,

  $user             = $mongodb::params::user,
  $group            = $mongodb::params::group,

  $config           = $mongodb::params::config,
  $dbpath           = $mongodb::params::dbpath,
  $pidfilepath      = $mongodb::params::pidfilepath,
  $rcfile           = $mongodb::params::rcfile,

  $service_provider = $mongodb::params::service_provider,
  $service_name     = $mongodb::params::service_name,
  $service_enable   = $mongodb::params::service_enable,
  $service_ensure   = $mongodb::params::service_ensure,
  $service_status   = $mongodb::params::service_status,

  $package_ensure  = $mongodb::params::package_ensure,
  $package_name    = $mongodb::params::server_package_name,

  $logpath         = $mongodb::params::logpath,
  $bind_ip         = $mongodb::params::bind_ip,
  $logappend       = true,
  $fork            = $mongodb::params::fork,
  $port            = undef,
  $journal         = $mongodb::params::journal,
  $nojournal       = undef,
  $smallfiles      = undef,
  $cpu             = undef,
  $auth            = false,
  $noauth          = undef,
  $create_admin    = false,
  $admin_username  = undef,
  $admin_password  = undef,
  $admin_roles     = ['dbAdmin', 'dbOwner', 'userAdmin', 'userAdminAnyDatabase'],
  $store_creds     = $mongodb::params::store_creds,
  $verbose         = undef,
  $verbositylevel  = undef,
  $objcheck        = undef,
  $quota           = undef,
  $quotafiles      = undef,
  $diaglog         = undef,
  $directoryperdb  = undef,
  $profile         = undef,
  $maxconns        = undef,
  $oplog_size      = undef,
  $nohints         = undef,
  $nohttpinterface = undef,
  $noscripting     = undef,
  $notablescan     = undef,
  $noprealloc      = undef,
  $nssize          = undef,
  $mms_token       = undef,
  $mms_name        = undef,
  $mms_interval    = undef,
  $replset         = undef,
  $configsvr       = undef,
  $shardsvr        = undef,
  $rest            = undef,
  $quiet           = undef,
  $slowms          = undef,
  $keyfile         = undef,
  $key             = undef,
  $set_parameter   = undef,
  $syslog          = undef,
  $config_content  = undef,
  $ssl             = undef,
  $ssl_key         = undef,
  $ssl_ca          = undef,

  # Deprecated parameters
  $master          = undef,
  $slave           = undef,
  $only            = undef,
  $source          = undef,
) inherits mongodb::params {


  if $ssl {
    validate_string($ssl_key, $ssl_ca)
  }

  if ($ensure == 'present' or $ensure == true) {
    anchor { 'mongodb::server::start': }->
    class { 'mongodb::server::install': }->
    class { 'mongodb::server::config': }->
    class { 'mongodb::server::service': }->
    anchor { 'mongodb::server::end': }
  } else {
    anchor { 'mongodb::server::start': }->
    class { 'mongodb::server::service': }->
    class { 'mongodb::server::config': }->
    class { 'mongodb::server::install': }->
    anchor { 'mongodb::server::end': }
  }

  if $create_admin {
    mongodb_user { $admin_username:
      ensure        => present,
      username      => $admin_username,
      password_hash => mongodb_password($admin_username, $admin_password),
      database      => 'admin',
      roles         => $admin_roles,
      tries         => 10,
      tag           => 'admin'
    }

    if $replset {
      # You can't create users before replica set initialization
      Class['mongodb::replset'] -> Mongodb_user <| tag == 'admin' |>
    }

    # Make sure admin user created first
    Mongodb_user <| tag == 'admin' |> -> Mongodb_user <| tag != 'admin' |>
  }
}
