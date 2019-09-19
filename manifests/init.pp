class rgbank (
  String    $db_username = 'test',
  Sensitive[String] $db_password = 'test',
  Integer   $listen_port = 8060,
  Boolean   $use_docker  = false,
  Integer   $lb_port     = 80,
) { }
