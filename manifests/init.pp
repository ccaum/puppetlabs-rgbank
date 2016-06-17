application rgbank (
  $db_username = 'test',
  $db_password = 'test'
) {

  $web_components = collect_component_titles($nodes, Rgbank::Web)
  $db_components = collect_component_titles($nodes, Rgbank::Db)
  $load_components = collect_component_titles($nodes, Rgbank::Load)

  $db_components.each |$comp_name| {
    rgbank::db { $comp_name:
      user     => $db_username,
      password => $db_password,
      export   => Mysqldb["rgbank-${name}"],
    }
  }

  $web_https = $web_components.map |$comp_name| {
    $http = Http["rgbank-${comp_name}"]

    rgbank::web { "${comp_name}":
      consume => Mysqldb["rgbank-${name}"],
      export  => $http,
    }

    #Return HTTP service resource
    $http
  }

  $load_components.each |$comp_name| {
    rgbank::load { $comp_name:
      balancermembers => $web_https,
      require         => $web_https,
      export          => Http["rgbank-web-lb-${name}"],
    }
  }
}
