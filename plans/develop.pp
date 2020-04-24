plan rgbank::develop(
  Optional[TargetSpec] $db_node = undef,
  Optional[TargetSpec] $app_node = undef,
  Boolean $provision = false,
) {
  if $provision {
    $nodes = run_plan('dev_env', count => 2, role => 'rgbank_base')

    $_db_node = $nodes[0]
    $_app_node = $nodes[1]
    
    wait_until_available($nodes)
  } else {
    $nodes = [$db_node, $app_node]
    $_db_node = $db_node
    $_app_node = $app_node
  }

  apply_prep($nodes)

  $db_results = apply($_db_node, _catch_errors => true) {
    class { 'mysql::server':
      override_options   => {
        'mysqld' => {
          'bind-address' => '0.0.0.0',
        }
      },
    }

    include rgbank::profile::db
  }
  $db_results.each |$result| {
    notice($result.report)
  }

  $app_results = apply($_app_node, _catch_errors => true) {
    class { 'php':
      composer => false,
    }
    class { 'nginx':
      names_hash_bucket_size => 128,
    }

    class { 'rgbank::profile::web':
      db_host => $_db_node
    }

    Class['php'] -> Class['nginx']
  }
  $app_results.each |$result| {
    notice($result.report)
  }

  return({
    'rgbank_app' => "http://${_app_node}:8080",
    'db_node'    => $_db_node,
    'app_node'   => $_app_node,
    'update_cmd' => "bolt plan run rgbank::develop db_node=${_db_node} app_node=${_app_node}"
  })
}
