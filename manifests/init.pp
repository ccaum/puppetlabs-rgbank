application rgbank (
  $db_username = 'test',
  $db_password = 'test',
  $dynamic_infrastructure = false
) {

  $db_components = collect_component_titles($nodes, Rgbank::Db)
  $web_components = collect_component_titles($nodes, Rgbank::Web)
  $load_components = collect_component_titles($nodes, Rgbank::Load)
  $vinfrastructure_components = collect_component_titles($nodes, Rgbank::Infrastructure::Web)

  #Assume we only have one DB component
  if $db_components.size() > 0 {
    rgbank::db { $db_components[0]:
      user     => $db_username,
      password => $db_password,
      export   => Mysqldb[$db_components[0]],
    }
  }

  $web_https = $web_components.map |$comp_name| {
    $http = Http["rgbank-web-${comp_name}"]
    $vm = $comp_name.split('/')[0]

    if $vinfrastructure_components.size() > 0 {
      rgbank::infrastructure::web { $vm:
        name   => $vm,
        export => Vinfrastructure[$vm],
      }
    }

    rgbank::web { "${comp_name}":
      consume => $dynamic_infrastructure ? {
        true  => [Mysqldb[$db_components[0]], Vinfrastructure[$vm]],
        false => Mysqldb[$db_components[0]]
      },
      export  => $http,
    }

    #Return HTTP service resource
    $http
  }

  if $load_components.size() > 0 {
    #Assume we only have one load balancer component
    rgbank::load { $load_components[0]:
      balancermembers => $web_https,
      require         => $web_https,
      export          => Http[$load_components[0]],
    }
  }
}
