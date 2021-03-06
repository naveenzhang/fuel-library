# == Class: murano::keystone::auth
#
# Configures murano service and endpoint in Keystone.
#
# === Parameters
#
# [*password*]
#   (required) Password for murano user.
#
# [*service_name*]
#   (Optional) Name of the service.
#   Defaults to the value of auth_name.
#
# [*auth_name*]
#   (Optional) Username for murano service.
#   Defaults to 'murano'.
#
# [*email*]
#   (Optional) Email for murano user.
#   Defaults to 'murano@localhost'.
#
# [*tenant*]
#   (Optional) Tenant for murano user.
#   Defaults to 'services'.
#
# [*configure_endpoint*]
#   (Optional) Should murano endpoint be configured?
#   Defaults to 'true'.
#
# [*service_type*]
#   (Optional) Type of service.
#   Defaults to 'application-catalog'.
#
# [*service_description*]
#   (Optional) Description of service.
#   Defaults to 'Murano Application Catalog'.
#
# [*region*]
#   (Optional) Region for endpoint.
#   Defaults to 'RegionOne'.
#
# [*public_url*]
#   (optional) The endpoint's public url. (Defaults to 'http://127.0.0.1:8082
#   This url should *not* contain any trailing '/'.
#
# [*admin_url*]
#   (optional) The endpoint's admin url. (Defaults to 'http://127.0.0.1:8082
#   This url should *not* contain any trailing '/'.
#
# [*internal_url*]
#   (optional) The endpoint's internal url. (Defaults to 'http://127.0.0.1:8082
#   This url should *not* contain any trailing '/'.
#
# [*version*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   API version endpoint. (Defaults to 'v1.1')
#   Setting this parameter overrides public_url, internal_url and admin_url parameters.
#
# [*port*]
#   (optional) DEPRECATED: Use public_url, internal_url and admin_url instead.
#   Default port for endpoints. (Defaults to 8082)
#   Setting this parameter overrides public_url, internal_url and admin_url parameters.
#
# [*public_port*]
#   (optional) DEPRECATED: Use public_url instead.
#   Default port for endpoints. (Defaults to $port)
#   Setting this parameter overrides public_url parameter.
#
# [*public_protocol*]
#   (optional) DEPRECATED: Use public_url instead.
#   Protocol for public endpoint. (Defaults to 'http')
#   Setting this parameter overrides public_url parameter.
#
# [*public_address*]
#   (optional) DEPRECATED: Use public_url instead.
#   Public address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides public_url parameter.
#
# [*internal_protocol*]
#   (optional) DEPRECATED: Use internal_url instead.
#   Protocol for internal endpoint. (Defaults to 'http')
#   Setting this parameter overrides internal_url parameter.
#
# [*internal_address*]
#   (optional) DEPRECATED: Use internal_url instead.
#   Internal address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides internal_url parameter.
#
# [*admin_protocol*]
#   (optional) DEPRECATED: Use admin_url instead.
#   Protocol for admin endpoint. (Defaults to 'http')
#   Setting this parameter overrides admin_url parameter.
#
# [*admin_address*]
#   (optional) DEPRECATED: Use admin_url instead.
#   Admin address for endpoint. (Defaults to '127.0.0.1')
#   Setting this parameter overrides admin_url parameter.
#
# === Deprecation notes
#
# If any value is provided for public_protocol, public_address or port parameters,
# public_url will be completely ignored. The same applies for internal and admin parameters.
#
# === Examples
#
#  class { 'murano::keystone::auth':
#    public_url   => 'https://10.0.0.10:8082',
#    internal_url => 'https://10.0.0.11:8082',
#    admin_url    => 'https://10.0.0.11:8082',
#  }
#
class murano::keystone::auth(
  $password,
  $service_name        = undef,
  $auth_name           = 'murano',
  $email               = 'murano@localhost',
  $tenant              = 'services',
  $service_type        = 'application_catalog',
  $service_description = 'Murano Application Catalog',
  $configure_endpoint  = true,
  $region              = 'RegionOne',
  $public_url          = 'http://127.0.0.1:8082',
  $admin_url           = 'http://127.0.0.1:8082',
  $internal_url        = 'http://127.0.0.1:8082',
# DEPRECATED PARAMETERS
  $version             = undef,
  $port                = undef,
  $public_port         = undef,
  $public_protocol     = undef,
  $public_address      = undef,
  $public_port         = undef,
  $internal_protocol   = undef,
  $internal_address    = undef,
  $admin_protocol      = undef,
  $admin_address       = undef,
) {

  if $version {
    warning('The version parameter is deprecated, use public_url, internal_url and admin_url instead.')
  }

  if $port {
    warning('The port parameter is deprecated, use public_url, internal_url and admin_url instead.')
  }

  if $public_port {
    warning('The public_port parameter is deprecated, use public_url instead.')
  }

  if $public_protocol {
    warning('The public_protocol parameter is deprecated, use public_url instead.')
  }

  if $internal_protocol {
    warning('The internal_protocol parameter is deprecated, use internal_url instead.')
  }

  if $admin_protocol {
    warning('The admin_protocol parameter is deprecated, use admin_url instead.')
  }

  if $public_address {
    warning('The public_address parameter is deprecated, use public_url instead.')
  }

  if $internal_address {
    warning('The internal_address parameter is deprecated, use internal_url instead.')
  }

  if $admin_address {
    warning('The admin_address parameter is deprecated, use admin_url instead.')
  }

  if ($public_protocol or $public_address or $port or $public_port or $version) {
    $public_url_real = sprintf('%s://%s:%s',
      pick($public_protocol, 'http'),
      pick($public_address, '127.0.0.1'),
      pick($public_port, $port, '8082'))
  } else {
    $public_url_real = $public_url
  }

  if ($admin_protocol or $admin_address or $port or $version) {
    $admin_url_real = sprintf('%s://%s:%s',
      pick($admin_protocol, 'http'),
      pick($admin_address, '127.0.0.1'),
      pick($port, '8082'))
  } else {
    $admin_url_real = $admin_url
  }

  if ($internal_protocol or $internal_address or $port or $version) {
    $internal_url_real = sprintf('%s://%s:%s',
      pick($internal_protocol, 'http'),
      pick($internal_address, '127.0.0.1'),
      pick($port, '8082'))
  } else {
    $internal_url_real = $internal_url
  }

  $real_service_name = pick($service_name, $auth_name)

  keystone::resource::service_identity { $real_service_name:
    configure_user      => true,
    configure_user_role => true,
    configure_endpoint  => $configure_endpoint,
    service_type        => $service_type,
    service_description => $service_description,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }
}
