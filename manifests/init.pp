application rgbank (
  $db_username = 'test',
  $db_password = 'test',
  $dynamic_infrastructure = false,
  $use_dockr = false,
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

    if $vinfrastructure_components.size() > 0 {
      $vm = $comp_name.split('/')[0]
      $rgbank_web_consume = [Mysqldb[$db_components[0]], Vinfrastructure[$vm]]

      rgbank::infrastructure::web { $vm:
        export => Vinfrastructure[$vm],
      }
    } else {
     $rgbank_web_consume = Mysqldb[$db_components[0]]
    }

    if $use_docker {
      rgbank::web::docker { $comp_name:
        consume => $rgbank_web_consume,
        export  => $http,
      }
    } else {
      rgbank::web { "${comp_name}":
        consume => $rgbank_web_consume,
        export  => $http,
      }
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
