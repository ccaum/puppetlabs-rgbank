application rgbank (
  $db_username = 'test',
  $db_password = 'test',
  $listen_port = '80',
  $use_docker = false,
) {

  $db_component = collect_component_titles($nodes, Rgbank::Db)[0] #Assume we only have one
  $web_components = collect_component_titles($nodes, Rgbank::Web)
  $load_component = collect_component_titles($nodes, Rgbank::Load)[0] #Assume we only have one
  $vinfrastructure_components = collect_component_titles($nodes, Rgbank::Infrastructure::Web)

  rgbank::db { $db_component:
    user     => $db_username,
    password => $db_password,
    export   => Database[$db_components[0]],
  }

  $web_https = $web_components.map |$comp_name| {
    $http = Http["rgbank-web-${comp_name}"]

    if $vinfrastructure_components.size() > 0 {
      $vm = $comp_name.split('_')[0]
      $rgbank_web_consume = [Database[$db_components[0]], Vinfrastructure[$vm]]

      rgbank::infrastructure::web { $vm:
        export => Vinfrastructure[$vm],
      }
    } else {
     $rgbank_web_consume = Database[$db_components[0]]
    }

    rgbank::web { $comp_name:
      use_docker  => $use_docker,
      listen_port => String($listen_port),
      consume     => $rgbank_web_consume,
      export      => $http,
    }

    #Return HTTP service resource
    $http
  }

  rgbank::load { $load_component:
    balancermembers => $web_https,
    port            => $serve_port,
    require         => $web_https,
    export          => Http[$load_components[0]],
  }
}
