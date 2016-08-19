define rgbank::load (
  $balancermembers,
  $port = 80,
) {
  include haproxy

  haproxy::listen {"rgbank-${name}":
    collect_exported => false,
    ipaddress        => '0.0.0.0',
    mode             => 'http',
    options          => {
      'option'       => ['forwardfor', 'http-server-close', 'httplog'],
      'balance'      => 'roundrobin',
    },
    ports            => $port,
  }

  $balancermembers.each |$member| {

    haproxy::balancermember { $member['host']:
      listening_service => "rgbank-${name}",
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
        before   => Haproxy::Listen["rgbank-${name}"],
      }
    }
  }

  firewall { '000 accept rgbank load balanced connections':
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
