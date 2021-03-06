notice('MODULAR: murano.pp')

prepare_network_config(hiera('network_scheme', {}))

$murano_hash                = hiera_hash('murano_hash', {})
$murano_settings_hash       = hiera_hash('murano_settings', {})
$rabbit_hash                = hiera_hash('rabbit_hash', {})
$heat_hash                  = hiera_hash('heat_hash', {})
$neutron_config             = hiera_hash('neutron_config', {})
$node_role                  = hiera('node_role')
$public_ip                  = hiera('public_vip')
$database_ip                = hiera('database_vip', undef)
$management_ip              = hiera('management_vip')
$region                     = hiera('region', 'RegionOne')
$use_neutron                = hiera('use_neutron', false)
$service_endpoint           = hiera('service_endpoint')
$syslog_log_facility_murano = hiera('syslog_log_facility_murano')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_port                  = hiera('amqp_port')
$amqp_hosts                 = hiera('amqp_hosts')
$public_ssl                 = hiera_hash('public_ssl', {})

#################################################################

$public_protocol = pick($public_ssl['services'], false) ? {
  true    => 'https',
  default => 'http',
}

$public_address = pick($public_ssl['services'], false) ? {
  true    => pick($public_ssl['hostname']),
  default => $public_ip,
}

$firewall_rule  = '202 murano-api'

$api_bind_port  = '8082'
$api_bind_host  = get_network_role_property('murano/api', 'ipaddr')

$murano_user    = pick($murano_hash['user'], 'murano')
$tenant         = pick($murano_hash['tenant'], 'services')
$internal_url   = "http://${service_endpoint}:${api_bind_port}"
$db_user        = pick($murano_hash['db_user'], 'murano')
$db_name        = pick($murano_hash['db_name'], 'murano')
$db_password    = pick($murano_hash['db_password'])
$db_host        = pick($murano_hash['db_host'], $database_ip)
$read_timeout   = '60'
$sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?read_timeout=${read_timeout}"

$external_network = $use_neutron ? {
  true    => get_ext_net_name($neutron_config['predefined_networks']),
  default => undef,
}

$repository_url = has_key($murano_settings_hash, 'murano_repo_url') ? {
  true    => $murano_settings_hash['murano_repo_url'],
  default => 'http://storage.apps.openstack.org',
}

####### Disable upstart startup on install #######
tweaks::ubuntu_service_override { ['murano-api', 'murano-engine']:
  package_name => 'murano',
}

firewall { $firewall_rule :
  dport  => $api_bind_port,
  proto  => 'tcp',
  action => 'accept',
}

class { 'murano' :
  verbose             => $verbose,
  debug               => $debug,
  use_syslog          => $use_syslog,
  log_facility        => $syslog_log_facility_murano,
  database_connection => $sql_connection,
  keystone_uri        => "${public_protocol}://${public_address}:5000/v2.0/",
  keystone_username   => $murano_user,
  keystone_password   => $murano_hash['user_password'],
  keystone_tenant     => $tenant,
  identity_uri        => "http://${service_endpoint}:35357/",
  use_neutron         => $use_neutron,
  rabbit_os_user      => $rabbit_hash['user'],
  rabbit_os_password  => $rabbit_hash['password'],
  rabbit_os_port      => $amqp_port,
  rabbit_os_host      => split($amqp_hosts, ','),
  rabbit_ha_queues    => $rabbit_ha_queues,
  rabbit_own_host     => $public_ip,
  rabbit_own_port     => '55572',
  rabbit_own_user     => 'murano',
  rabbit_own_password => $heat_hash['rabbit_password'],
  service_host        => $api_bind_host,
  service_port        => $api_bind_port,
  external_network    => $external_network,
}

class { 'murano::api':
  host => $api_bind_host,
  port => $api_bind_port,
}

class { 'murano::engine': }

class { 'murano::client': }

class { 'murano::dashboard':
  api_url  => $internal_url,
  repo_url => $repository_url,
}

class { 'murano::rabbitmq':
  rabbit_user     => 'murano',
  rabbit_password => $heat_hash['rabbit_password'],
  rabbit_port     => '55572',
}

$haproxy_stats_url = "http://${management_ip}:10000/;csv"

haproxy_backend_status { 'murano-api' :
  name => 'murano-api',
  url  => $haproxy_stats_url,
}

if ($node_role == 'primary-controller') {
  murano::application { 'io.murano' :
    os_tenant_name => $tenant,
    os_username    => $murano_user,
    os_password    => $murano_hash['user_password'],
    os_auth_url    => "${public_protocol}://${public_address}:5000/v2.0/",
    os_region      => $region,
    mandatory      => true,
  }

  Service['murano-api'] -> Murano::Application<| mandatory == true |>
} else {
  notice("Node Role: ${node_role}")
}

Firewall[$firewall_rule] -> Class['murano::api']
Service['murano-api'] -> Haproxy_backend_status['murano-api']

#########################

class openstack::firewall {}
include openstack::firewall
