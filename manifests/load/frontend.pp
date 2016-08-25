class rgbank::load::frontend {
  $options = {}

  $instances = find_resources(Rgbank::Load).map |$app_load| {
    $options.merge(
      {
        "acl ${app_load['name']}" => ['path_beg', "/${app_load['name']}"],
        "use_backend ${app_load['name']}" => ['if', $app_load['name']],
      }
    )
  }
    
  haproxy::frontend { 'rgbank':
    ipaddress => '0.0.0.0',
    ports     => '80',
    mode      => 'http',
    options   => $options,
  }
}
