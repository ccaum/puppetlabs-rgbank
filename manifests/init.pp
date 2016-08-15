application rgbank (
  $db_username = 'test',
  $db_password = 'test',
  $dynamic_infrastructure = false
) {

  $web_components = collect_component_titles($nodes, Rgbank::Web)

  rgbank::db { "rgbank-db-${name}":
    user     => $db_username,
    password => $db_password,
    export   => Mysqldb["rgbank-db"],
  }

  $web_https = $web_components.map |$comp_name| {
    $http = Http["rgbank-web-${comp_name}"]

    if $dynamic_infrastructure {
      rgbank::infrastructure::web { $comp_name:
        export => Vinfrastructure["rgbank-web-${comp_name}"],
      }
    }

    rgbank::web { "${comp_name}":
      consume => $dynamic_infrastructure ? {
        true  => [Mysqldb["rgbank-db"], Vinfrastructure["rgbank-web-${comp_name}"]],
        false => Mysqldb["rgbank-db"]
      },
      export  => $http,
    }

    #Return HTTP service resource
    $http
  }

  rgbank::load { "rgbank-lb-${name}":
    balancermembers => $web_https,
    require         => $web_https,
    export          => Http["rgbank-lb-${name}"],
  }
}
