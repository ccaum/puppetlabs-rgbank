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
      export   => Mysqldb["rgbank-db"],
    }
  }

  $web_https = $web_components.map |$comp_name| {
    $http = Http["rgbank-web-${comp_name}"]

    rgbank::web { "${comp_name}":
      consume => Mysqldb["rgbank-db"],
      export  => $http,
    }

    #Return HTTP service resource
    $http
  }

  $load_components.each |$comp_name| {
    $environment = get_compiler_environment()
    $http_query = "resources { type = 'Http' and title ~ '^rgbank-web-[^lb].*' and environment = '${environment}'}"
    $http_resources = puppetdb_query($http_query).map |$resource| {
      Http[$resource['title']]
    }

    $all_http_resources = unique(concat($http_resources, $web_https))

    rgbank::load { $comp_name:
      balancermembers => $web_https,
      require         => $web_https,
      export          => Http["rgbank-lb-${name}"],
    }
  }
}
