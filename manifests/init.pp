application rgbank (
  $db_username = 'test',
  $db_password = 'test',
  $listen_port = '80',
  $use_docker = false,
) {

  $db_components = collect_component_titles($nodes, Rgbank::Db)
  $web_components = collect_component_titles($nodes, Rgbank::Web)
  $load_components = collect_component_titles($nodes, Rgbank::Load)

  #Assume we only have one DB component
  if $db_components.size() > 0 {
    rgbank::db { $db_components[0]:
      user     => $db_username,
      password => $db_password,
      export   => Database[$db_components[0]],
    }
  }

  $web_https = $web_components.map |$comp_name| {
    $http = Http["rgbank-web-${comp_name}"]

    rgbank::web { $comp_name:
      use_docker  => $use_docker,
      listen_port => String($listen_port),
      consume     => Database[$db_components[0]],
      export      => $http,
    }

    #Return HTTP service resource
    $http
  }

  if $load_components.size() > 0 {
    #Assume we only have one load balancer component
    rgbank::load { $load_components[0]:
      balancermembers => $web_https,
      port            => $serve_port,
      require         => $web_https,
      export          => Http[$load_components[0]],
    }
  }
}
