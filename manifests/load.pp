define rgbank::load (
  $balancermembers,
  $port = 80,
) {
  include haproxy
  include rgbank::load::frontend

  $sanitized_backend_name = $name.regsubst('[:/-]','_','G')
  $service_name = $name.split('_')[-1]
  haproxy::backend { $sanitized_backend_name:
    mode    => 'http',
    options => {
      'option'  => [
        'forwardfor',
        'httpchk GET / HTTP/1.0',
      ],
      'reqrep' => "^([^\ :]*)\ /${service_name}(.*) \1\ /\2",
      'balance' => 'roundrobin',
    },
  }

  $balancermembers.each |$member| {
    $sanitized_member_name = String($member).regsubst('[:/-]','_','G')
    haproxy::balancermember { $sanitized_member_name:
      listening_service => $sanitized_backend_name,
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
        before   => Haproxy::Frontend["rgbank"],
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
