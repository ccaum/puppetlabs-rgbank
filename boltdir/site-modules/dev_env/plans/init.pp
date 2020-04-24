plan dev_env(
  String  $pe_server = 'cdpe-carl.delivery.puppetlabs.net',
  String  $platform = 'centos-7-x86_64',
  Integer $count = 1,
  String  $role = '',
  Optional[String] $environment = 'agent_specified'
) {

  if $environment == undef {
    $branch = run_command('git rev-parse --abbrev-ref HEAD', 'localhost').first.value()['stdout']
    if $branch.empty() {
      fail_plan("Could not find a git branch in current working directory")
    }

    $_environment = $branch
  } else {
    $_environment = $environment
  }

  $nodes = run_task("floaty::get", 'localhost',
    platform => $platform,
    count    => $count).first['nodes']

  $group = $platform ? {
    /win.*/ => 'windows',
    default => 'linux'
  }

  add_to_group($nodes, $group)
  out::message("Added nodes to group ${group}")

  $results = Array.new([])

  $nodes.map |$node| {
    $token = run_task('autosign::generate_token', $pe_server, certname => $node).first.message().strip()
    out::message("generated a token for node: ${node}")
    $result = run_task('bootstrap', $node, master => $pe_server, custom_attribute => ["challengePassword=${token}"], extension_request => ["pp_role=${role}","pp_environment=${_environment}"])
    out::message("Bootstrapped an agent for ${node} with result ${result.first.message()}")
    $results << $result
  }

  return($nodes)
}
