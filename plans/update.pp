# @summary
#   Deploy a tagged release of RG Bank to production
#
# @param tag
#   The tagged release in VCS to deploy
#
plan rgbank::update(
  String $tag,
) {

  $query_results = puppetdb_query('nodes { certname ~ "wordpress.*" }')

  $certnames = $query_results.map |$r| { $r['certname'] }

  $targets = get_targets($certnames)

  out::message("Updating RG Bank application to version ${tag} one host at a time")
  $targets.each |$target| {
    run_task('rgbank::co', $target,
      tag => $tag)
  }
}
