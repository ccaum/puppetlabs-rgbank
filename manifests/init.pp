application rgbank (
  $db_username = 'test',
  $db_password = 'test'
) {

  $web_components = collect_component_titles($nodes, Rgbank::Web)
  $webs = $web_components.map |$i| { Http["rgbank-web-${name}-${i}"] }

  rgbank::db { $name:
    user     => $db_username,
    password => $db_password,
    export   => Mysqldb["rgbank-${name}"],
  }

  $web_count.each |$i| {
    rgbank::web { "${name}-${i}":
      consume => Mysqldb["rgbank-${name}"],
      export  => Http["rgbank-web-${name}-${i}"],
    }
  }

  rgbank::load { $name:
    balancermembers => $webs,
    require         => $webs,
    export          => Http["rgbank-web-lb-${name}"],
  }
}
