# == Class: wuau
#
# Puppet Module for Windows Automatic Update Configuration.
#
# === Parameters
#
# Document parameters here.
#
# [*enabled*]
#   (boolean) Enable automatic update or not.
# [*type*]
#   (string) options for automatic update. Possible types are:
#    1. `notify`. 
#    2. `download`.
#    3. `schedule`.
#    4. `custom`.
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'wuau':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Zhu Sheng Li <digglife@gmail.com>
#
# === References
#
# https://technet.microsoft.com/en-us/library/dd939844%28v=ws.10%29.aspx
# https://technet.microsoft.com/en-us/library/cc720464%28v=ws.10%29.aspx
#
# === Copyright
#
# Copyright 2015 Zhu Sheng Li, unless otherwise noted.
#
class wuau(
  $enabled = true,
  $type = 'schedule',
  $wsus_server = undef,
  $target_group = undef,
  $auto_reboot = false,
  $auto_install_minor_updates = false,
  $include_recommended_updates = false,
  $power_management_enabled = true,
  $scheduled_install_day = 7,
  $scheduled_install_time = 3,
  $detection_frequency = 22,
  $reboot_relaunch_timeout = 10,
  $reboot_warning_timeout = 5,
  $reschedule_wait_time = 1,
){


  $wu_reg_path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
  $au_reg_path = "$wu_reg_path\\AU"

  validate_bool($enabled)
  validate_bool($auto_reboot)
  validate_bool($auto_install_minor_updates)
  validate_bool($include_recommended_updates)
  validate_bool($power_management_enabled)
  validate_re($type, ['^notify$', '^download$', '^schedule$', '^custom$'])

  # validate_integer is a new function of puppet stdlib version 4.6
  validate_integer($scheduled_install_day, 7, 0)
  validate_integer($scheduled_install_time, 23, 0)
  # Default 22(hours) if disabled or not configured.
  validate_integer($detection_frequency, 22, 1)
  # Default 10(minutes) if disabled or not configured.
  validate_integer($reboot_relaunch_timeout, 1440, 1)
  # Default 5(miniutes) if disabled or not configured.
  # Note: when I tested on Windows Server 2008, the default value is 15mins,
  #       which is different from the official documents.
  validate_integer($reboot_warning_timeout, 40, 1)
  # Default 1(minute) if disabled or not configured.
  validate_integer($reschedule_wait_time, 60, 1)

  # convert boolean value to integer for writting into registry.
  $NoAutoUpdate = bool2num(!$enabled)
  $NoAutoRebootWithLoggedOnUsers = bool2num(!$auto_reboot)
  $AutoInstallMinorUpdates = bool2num($auto_install_minor_updates)
  $IncludeRecommendedUpdates = bool2num($include_recommended_updates)
  $AUPowerManagement = bool2num($power_management_enabled)

  $AUOptions = $type ? {
    'notify'    => 2,
    'download'  => 3,
    'schedule'  => 4,
    'custom'    => 5,
  }

  service { 'wuauserv':
    ensure    => 'running',
    enable    => true,
    subscribe => Registry_value[
      'NoAutoUpdate',
      'AUOptions',
      'ScheduledInstallDay',
      'ScheduledInstallTime',
      'AutoInstallMinorUpdates',
      'IncludeRecommendedUpdates',
      'AUPowerManagement',
      'DetectionFrequency',
      'RebootRelaunchTimeout',
      'RebootWarningTimeout',
      'RescheduleWaitTime',
      'NoAutoRebootWithLoggedOnUsers'
    ]
  }

  registry_key { $au_reg_path:
    ensure       => present,
    purge_values => true,
  }

  if $wsus_server {
    validate_re($wsus_server, '^https?:\/\/.*')

    registry_value { 'UseWUServer':
      ensure => present,
      path   => "$au_reg_path\\UseWUServer",
      type   => 'dword',
      data   => '1',
      notify => Service['wuauserv'],
    }

    registry_value { 'WUServer' :
      ensure => present,
      path   => "$wu_reg_path\\WUServer",
      type   => 'string',
      data   => $wsus_server,
      notify => Service['wuauserv'],
    }

    registry_value {'WUStatusServer' :
      ensure => present,
      path   => "$wu_reg_path\\WUStatusServer",
      type   => 'string',
      data   => $wsus_server,
      notify => Service['wuauserv'],
    }

    if $target_group {
      validate_string($target_group)

      registry_value { 'TargetGroupEnabled':
        ensure => present,
        path   => "$wu_reg_path\\TargetGroupEnabled",
        type   => 'dword',
        data   => 1,
        notify => Service['wuauserv'],
      }

      registry_value { 'TargetGroup':
        ensure => present,
        path   => "$wu_reg_path\\TargetGroup",
        type   => 'string',
        data   => $target_group,
        notify => Service['wuauserv']
      }
    }
  }


  registry_value { 'NoAutoUpdate':
    ensure => present,
    path   => "$au_reg_path\\NoAutoUpdate",
    type   => 'dword',
    data   => $NoAutoUpdate,
  }

  registry_value { 'AUOptions':
    ensure => present,
    path   => "$au_reg_path\\AUOptions",
    type   => 'dword',
    data   => $AUOptions,
  }

  registry_value { 'ScheduledInstallDay':
    ensure => present,
    path   => "$au_reg_path\\ScheduledInstallDay",
    type   => 'dword',
    data   => $scheduled_install_day,
  }

  registry_value { 'ScheduledInstallTime':
    ensure => present,
    path   => "$au_reg_path\\ScheduledInstallTime",
    type   => 'dword',
    data   => $scheduled_install_time,
  }

  registry_value { 'NoAutoRebootWithLoggedOnUsers':
    ensure => present,
    path   => "$au_reg_path\\NoAutoRebootWithLoggedOnUsers",
    type   => 'dword',
    data   => $NoAutoRebootWithLoggedOnUsers,
  }

  registry_value { 'AutoInstallMinorUpdates':
    ensure => present,
    path   => "$au_reg_path\\AutoInstallMinorUpdates",
    type   => 'dword',
    data   => $AutoInstallMinorUpdates,
  }


  registry_value { 'IncludeRecommendedUpdates':
    ensure => present,
    path   => "$au_reg_path\\IncludeRecommendedUpdates",
    type   => 'dword',
    data   => $IncludeRecommendedUpdates,
  }

  registry_value { 'AUPowerManagement':
    ensure => present,
    path   => "$au_reg_path\\AUPowerManagement",
    type   => 'dword',
    data   => $AUPowerManagement,
  }


  registry_value { 'DetectionFrequencyEnabled':
    ensure => present,
    path   => "$au_reg_path\\DetectionFrequencyEnabled",
    type   => 'dword',
    data   => 1,
  }

  registry_value { 'DetectionFrequency':
    ensure => present,
    path   => "$au_reg_path\\DetectionFrequency",
    type   => 'dword',
    data   => $detection_frequency,
  }

  # Customized RebootRelaunchTimeout, RebootWarningTimeout, RescheduleWaitTime
  # only valid when the associated *Enabled value is to 1(true).

  registry_value { 'RebootRelaunchTimeoutEnabled':
    ensure => present,
    path   => "$au_reg_path\\RebootRelaunchTimeoutEnabled",
    type   => 'dword',
    data   => 1,
  }

  registry_value { 'RebootRelaunchTimeout':
    ensure => present,
    path   => "$au_reg_path\\RebootRelaunchTimeout",
    type   => 'dword',
    data   => $reboot_relaunch_timeout,
  }

  registry_value { 'RebootWarningTimeoutEnabled':
    ensure => present,
    path   => "$au_reg_path\\RebootWarningTimeoutEnabled",
    type   => 'dword',
    data   => 1,
  }

  registry_value { 'RebootWarningTimeout':
    ensure => present,
    path   => "$au_reg_path\\RebootWarningTimeout",
    type   => 'dword',
    data   => $reboot_warning_timeout,
  }


  registry_value { 'RescheduleWaitTimeEnabled':
    ensure => present,
    path   => "$au_reg_path\\RescheduleWaitTimeEnabled",
    type   => 'dword',
    data   => 1,
  }

  registry_value { 'RescheduleWaitTime':
    ensure => present,
    path   => "$au_reg_path\\RescheduleWaitTime",
    type   => 'dword',
    data   => $reschedule_wait_time,
  }


}
