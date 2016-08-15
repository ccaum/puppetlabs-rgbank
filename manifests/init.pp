application rgbank (
  $db_username = 'test',
  $db_password = 'test',
  $dynamic_infrastructure = false
) {

  $db_components = collect_component_titles($nodes, Rgbank::Db)
  $web_components = collect_component_titles($nodes, Rgbank::Web)
  $load_components = collect_component_titles($nodes, Rgbank::Load)

  #Assume we only have one DB component
  rgbank::db { $db_components[0]:
    user     => $db_username,
    password => $db_password,
    export   => Mysqldb["rgbank-${name}"],
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
        true  => [Mysqldb["rgbank-${name}"], Vinfrastructure["rgbank-web-${comp_name}"]],
        false => Mysqldb["rgbank-${name}"]
      },
      export  => $http,
    }

    #Return HTTP service resource
    $http
  }

  #Assume we only have one load balancer component
  rgbank::load { $load_components[0]:
    balancermembers => $web_https,
    require         => $web_https,
    export          => Http["rgbank-lb-${name}"],
  }
}
