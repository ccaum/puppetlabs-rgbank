plan dev_env::snow_create() {
  $domain = system::env("DEPLOYEMNT_DOMAIN")
  $deployment_id = system::env("DEPLOYMENT_ID")
  $deployment_url = "http://10.234.3.30:8080/${domain}/deployments/${deployment_id}"

  $incident = run_task('servicenow_tasks::create_record', 'dev84270',
    table  => 'incidents',
    fields => {'description' => "Deployment ID ${deployment_id} requires approval. See the deployment here: ${deployment_id}"}).first.output['fields']['id']

  #ctrl::do_until {
  #  $status = run_task('servicenow_tasks::get_record', 'dev84270', table => 'incidents', sys_id => $incident).first.output['status']

  #  if $status == 'Canceled' {
  #    fail_plan("Deployment was declined in ticket ${incident}")
  #  }

  #  $ok = $status ? {
  #    'Closed'  => true
  #    'Resolve' => true
  #    default   => false
  #  }

  #  $ok
  #}

  #return({'incident': $incident, 'status': 'approved'})
}
