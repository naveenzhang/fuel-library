#    Copyright 2013 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


class mcollective::rabbitmq (
  $user            = "mcollective",
  $password        = "mcollective",
  $stompport       = "61613",
  $management_port = "15672",
  $stomp           = false,
  $vhost           = "mcollective",) {

  define access_to_rabbitmq_port ($port, $protocol = 'tcp') {
    $rule = "-p $protocol -m state --state NEW -m $protocol --dport $port -j ACCEPT"

    exec { "access_to_cobbler_${protocol}_port: $port":
      command => "iptables -t filter -I INPUT 1 $rule; \
          /etc/init.d/iptables save",
      unless  => "iptables -t filter -S INPUT | grep -q \"^-A INPUT $rule\"",
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
  }

  # unused code from fuelweb. will be deleted in next release
  #  define mcollective_rabbitmq_safe_package(){
  #  if ! defined(Package[$name]){
  #    @package { $name : }
  #  }
  # }


  case $::osfamily {
    'Debian' : {
    }
    'RedHat' : {
      access_to_rabbitmq_port { "${stompport}_tcp": port => $stompport }
    }
    default  : {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }

  # NOTE(bogdando) indentation is important
  $rabbit_tcp_listen_options =
    '[
      binary,
      {packet, raw},
      {reuseaddr, true},
      {backlog, 128},
      {nodelay, true},
      {exit_on_close, false},
      {keepalive, true}
    ]'

  # NOTE(bogdando) this requires rabbitmq>=4.0 module
  class { '::rabbitmq':
    admin_enable            => true,
    repos_ensure            => false,
    package_provider        => 'yum',
    package_source          => undef,
    service_ensure          => 'running',
    delete_guest_user       => true,
    config_cluster          => false,
    cluster_nodes           => [],
    config_stomp            => true,
    stomp_port              => $stompport,
    node_ip_address         => 'UNSET',
    config_kernel_variables => {
     'inet_dist_listen_min'         => '41055',
     'inet_dist_listen_max'         => '41055',
     'inet_default_connect_options' => '[{nodelay,true}]',
    },
    config_variables        => {
      'log_levels'                  => '[connection,debug,info,error]',
      'default_vhost'               => '<<"">>',
      'default_permissions'         => '[<<".*">>, <<".*">>, <<".*">>]',
      'tcp_listen_options'          => $rabbit_tcp_listen_options,
    },
    environment_variables   => {
      'SERVER_ERL_ARGS'      => '"+K true +A30 +P 1048576"',
    },
  }

  if $stomp {
    $actual_vhost = "/"
  } else {
    rabbitmq_vhost { $vhost: }
    $actual_vhost = $vhost
  }

  rabbitmq_user { $user:
    admin    => true,
    password => $password,
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }

  rabbitmq_user_permissions { "${user}@${actual_vhost}":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => [Class['::rabbitmq'], Rabbitmq_user[$user],]
  }

  file { "/etc/rabbitmq/enabled_plugins":
    content => template("mcollective/enabled_plugins.erb"),
    owner   => root,
    group   => root,
    mode    => 0644,
    require => Package["rabbitmq-server"],
    notify  => Service["rabbitmq-server"],
  }

  Rabbitmq_user <| |> -> Exec['rabbitmq_restart']
  Rabbitmq_user_permissions <| |> -> Exec['rabbitmq_restart']
  File['/etc/rabbitmq/enabled_plugins'] -> Exec['rabbitmq_restart']

  exec { 'rabbitmq_restart':
    command => 'service rabbitmq-server restart',
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  }

  exec { 'create-mcollective-directed-exchange':
    command   => "curl -i -u ${user}:${password} -H \"content-type:application/json\" -XPUT \
      -d'{\"type\":\"direct\",\"durable\":true}' http://localhost:${management_port}/api/exchanges/${actual_vhost}/mcollective_directed",
    logoutput => true,
    require   => [Service['rabbitmq-server'], Rabbitmq_user_permissions["${user}@${actual_vhost}"]],
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    tries     => 10,
    try_sleep => 3,
  }

  exec { 'create-mcollective-broadcast-exchange':
    command   => "curl -i -u ${user}:${password} -H \"content-type:application/json\" -XPUT \
      -d'{\"type\":\"topic\",\"durable\":true}' http://localhost:${management_port}/api/exchanges/${actual_vhost}/mcollective_broadcast",
    logoutput => true,
    require   => [Service['rabbitmq-server'], Rabbitmq_user_permissions["${user}@${actual_vhost}"]],
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    tries     => 10,
    try_sleep => 3,
  }

}

