application rgbank (
  $db_username = 'test',
  $db_password = 'test'
) {

  $web_components = collect_component_titles($nodes, Rgbank::Web).count()

  rgbank::db { $name:
    user     => $db_username,
    password => $db_password,
    export   => Mysqldb["rgbank-${name}"],
  }

  $web_https = $web_components.map |$comp_name| {
    $http = Http["rgbank-${comp_name}"]

    rgbank::web { $comp_name:
      consume => Mysqldb["rgbank-${name}"],
      export  => $http,
    }

    #Return HTTP service resource
    $http
  }

  rgbank::load { $name:
    balancermembers => $web_https,
    require         => $web_https,
    export          => Http["rgbank-web-lb-${name}"],
  }
}
