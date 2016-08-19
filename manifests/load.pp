define rgbank::load (
  $balancermembers,
  $port = 80,
) {
  include haproxy

  $sanitized_listen_name = $name.regsubst('[:/-]','_','G')
  haproxy::listen {"rgbank-${sanitized_listen_name}":
    collect_exported => false,
    ipaddress        => '0.0.0.0',
    mode             => 'http',
    options          => {
      'option'       => ['forwardfor', 'http-server-close', 'httplog'],
      'balance'      => 'roundrobin',
    },
    ports            => "${port}",
  }

  $balancermembers.each |$member| {

    $sanitized_member_name = String($member).regsubst('[:/-]','_','G')
    haproxy::balancermember { $sanitized_member_name:
      listening_service => "rgbank-${sanitized_listen_name}",
      server_names      => $member['host'],
      ipaddresses       => $member['ip'],
      ports             => $member['port'],
      options           => 'check verify none',
    }

    $member_port = $member['port']
    $port_name = "allow-httpd-${member_port}"
    if ! defined(Selinux::Port[$port_name]) {
      selinux::port { $port_name:
        context  => 'http_port_t',
        port     => $member['port'],
        protocol => 'tcp',
        before   => Haproxy::Listen["rgbank-${sanitized_listen_name}"],
      }
    }
  }

  firewall { "000 accept rgbank port ${port} load balanced connections":
    dport  => $port,
    proto  => tcp,
    action => accept,
  }
}

Rgbank::Load produces Http {
  name => $name,
  ip   => $::ipaddress,
  host => $::fqdn,
  port => $port,
}

Rgbank::Load consumes Http { }
