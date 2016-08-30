class rgbank::load::frontend {
  $load_resources = find_resources(Rgbank::Load)

  $acl_configs = $load_resources.map |$app_load| {
    $resource_title = $app_load.get_resource_title().split('_')[-1]
    "${resource_title} path_beg /${resource_title}"
  }

  $use_backend_configs = $load_resources.map |$app_load| {
    $resource_title = $app_load.get_resource_title().split('_')[-1]
    "${resource_title} if ${resource_title}"
  }

  haproxy::frontend { 'rgbank':
    ipaddress => '0.0.0.0',
    ports     => '80',
    mode      => 'http',
    options   => {
     'use_backend' => $use_backend_configs,
     'acl'         => $acl_configs,
    }
  }
}
