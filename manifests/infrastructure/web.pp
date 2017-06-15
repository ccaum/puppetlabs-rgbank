define rgbank::infrastructure::web(
  $ensure = 'present',
  $size = 'small',
  $cloud = 'aws',
  $aws_keyname = undef,
  $aws_security_groups = undef,
  $development_branch,
  $build_number,
) {
  
  $vmware_template       = hiera('rgbank::infrastructure::web::vmware_template', '/opdx1/vm/carl/centos-7-x86_64-puppet')
  $vmware_resource_pool  = hiera('rgbank::infrastructure::web::vmware_resource_pool', '/general1')
  $aws_region            = hiera('rgbank::infrastructure::web::aws_region', 'us-east-1')
  $aws_availability_zone = hiera('rgbank::infrastructure::web::aws_availability_zone', 'us-east-1c')
  $aws_subnet            = hiera('rgbank::infrastructure::web::aws_subnet', 'ara-subnet')
  $aws_ami               = hiera('rgbank::infrastructure::web::aws_ami', 'ami-6b32627c')
  $aws_security_groups   = hiera('rgbank::infrastructure::web::aws_security_groups', ['rgbank-app','ssh'])

  Ec2_instance {
    ensure            => $ensure,
    region            => $aws_region,
    image_id          => $aws_ami,
    key_name          => $aws_keyname,
    availability_zone => $aws_availability_zone,
    subnet            => $aws_subnet,
    security_groups   => $aws_security_groups,
    tags              => {
      development_branch => $development_branch,
      development_app    => "RG Bank",
      provisioner        => "puppet",
      department         => "Product Marketing",
      project            => "ARA demo",
      owner              => "Carl Caum",
    },
  }

  case $size {
    'small': {
      $vmware_memory     = 1024
      $vmware_cpus       = 1
      $aws_instance_type = 't2.small'
    }
    'medium': {
      $vmware_memory     = 4096
      $vmware_cpus       = 4
      $aws_instance_type = 'm4.large'
    }
    'large': {
      $vmware_memory     = 16392
      $vmware_cpus       = 8
      $aws_instance_type = 'm4.2xlarge'
    }
  }

  case $cloud {
    'vmware': {

      vsphere_vm { "/opdx1/vm/carl/rgbank-development-${title}.vmware.puppet.vm":
        ensure         => present,
        memory         => $vmware_memory,
        cpus           => $vmware_cpus,
        source         => $vmware_template,
        source_type    => 'template',
        resource_pool  => $vmware_resource_pool,
        create_command => {
          command   => '/bin/sleep',
          arguments => "30; /bin/curl -k https://10.32.161.83:8140/packages/puppet_provision.bash | bash -s extension_requests:pp_role=rgbank-development extension_requests:pp_datacenter=PDX extension_requests:pp_application=Rgbank[${development_branch}] extension_requests:pp_environment=${development_branch} extension_requests:pp_apptier=Rgbank::Web extension_requests:pp_project=${build_number} attributes:challengePassword=Sup3rs3cr3t",
          user      => 'root',
          password  => 'puppetlabs',
        }
      }
    }

    'aws': {
      ec2_instance { "rgbank-development-${title}.aws.puppet.vm":
        instance_type   => $aws_instance_type,
        security_groups => $aws_security_groups,
        user_data       => epp( 'rgbank/aws_user_data.epp', {
          'role'           => 'rgbank-development',
          'application'    => "Rgbank[${::branch}]",
          'environment'    => $development_branch,
          'apptier'        => '[Rgbank::Db,Rgbank::Web]',
          'build_id'       => $build_number
        }),
      }
    }
  }
}

Rgbank::Infrastructure::Web produces Vinfrastructure { }
