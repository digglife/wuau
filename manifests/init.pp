# == Class: wuau
#
# Puppet Module for Windows Automatic Update Configuration.
#
# === Parameters
#
# [*enabled*]
#   (boolean) Enable automatic update or not. Default is true.
# [*type*]
#   (string) options for automatic update. Default is `schedule`.
#    Possible types are:
#    1. `notify`. Notify before download.
#    2. `download`. Automatically download and notify of installation. 
#    3. `schedule`. Automatically download and schedule installation.
#    4. `custom`. Automatic Updates is required, but end users can configure it.
# [*wsus_server*]
#   (string) URL of WSUS Server. Default is `undef`.
# [*target_group*]
#   (string) target group on WSUS Server. Default is `undef`.
# [*auto_reboot*]
#   (boolean) 
#   **true**  : Notifies user that the server will restart in 15 minutes.
#   **false** : Logged-on user can choose whether or not to restart.
#   The server will restart anyway if there is no logged-on user. 
#   Default is `true`.
# [*auto_install_minor_updates*]
#   (boolean) Silently install minor updates(no restart required) or not. 
#   Default is `false`.
# [*include_recommended_updates*]
#   (boolean) install recommended updates or not. Default is `false`.
# [*power_management_enabled*]
#   (boolean) whether wake up the server to install the updates. Default is `true`.
# [*scheduled_install_day*]
#   (integer) `0` for `daily`. `1-7` for `Sunday(1)` to `Saturday(7)`. Default is `7`.
#   Only applies when `type` is `schedule`.
# [*scheduled_install_time*]
#   (integer) 24-hour format (`0–23`). Default is `3`.
#   Only applies when `type` is `schedule`.
# [*detection_frequency*]
#   (integer) Time in hours (`1–22`) between detection cycle. Default is `22`.
# [*reboot_relaunch_timeout*]
#   (integer) Time in minutes(`1-1440`) between prompting again for a scheduled restart.
#   Default is `10`.
# [*reboot_warning_timeout*]
#   (integer) Time in minutes (`1-30`) of the restart warning countdown,
#   after installing updates with a deadline or scheduled updates.
#   Default is `5`.
# [*reschedule_wait_time*]
#   (integer) Time in minutes(`0-60`), that Automatic Updates should wait at startup 
#   before applying updates from a missed scheduled installation time.
#   This policy applies only when `type` is `schedule`.
#   Default is `1`.
#   *NOTE* : if it's set as 0,  a missed scheduled installation will occur
#            during the next scheduled installation time.
#
# === Examples
#
# class { 'wuau':
#     enabled      => true,
#     type         => 'schedule',
#     wsus_server  => 'http://10.0.0.111',
#     target_group => 'Production',
#     auto_reboot  => false,
# }
#

#
# === Authors
#
# Eric Zhu(朱聖黎) <digglife@gmail.com>
#
# === References
#
# https://technet.microsoft.com/en-us/library/dd939844%28v=ws.10%29.aspx
# https://technet.microsoft.com/en-us/library/cc720464%28v=ws.10%29.aspx
#
# === Copyright
#
# Copyright 2015 Eric Zhu(朱聖黎) <digglife@gmail.com>, unless otherwise noted.
#
class wuau(
  $enabled = true,
  $type = 'schedule',
  $wsus_server = undef,
  $target_group = undef,
  $auto_reboot = true,
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
  validate_integer($reboot_warning_timeout, 40, 1)
  # Default 1(minute) if not configured.
  validate_integer($reschedule_wait_time, 60, 0)

  # convert boolean value to integer for writting into registry.
  $NoAutoUpdate = bool2num(!$enabled)
  $NoAutoRebootWithLoggedOnUsers = bool2num(!$auto_reboot)
  $AutoInstallMinorUpdates = bool2num($auto_install_minor_updates)
  $IncludeRecommendedUpdates = bool2num($include_recommended_updates)
  $AUPowerManagement = bool2num($power_management_enabled)
  # if $reschedule_wait_time is 0 then 0, otherwise 1.
  $RescheduleWaitTimeEnabled = bool2num(num2bool($reschedule_wait_time))

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

  registry_key { 'AutomaticUpdate':
    path         => $au_reg_path,
    ensure       => present,
  }

  if $wsus_server {
    validate_re($wsus_server, '^https?:\/\/.*')

    registry_value { 'UseWUServer':
      ensure => present,
      path   => "$au_reg_path\\UseWUServer",
      type   => 'dword',
      data   => 1,
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

  } else {

    registry_value { 'UseWUServer':
      # or use ensure => absent ?
      ensure => present,
      path   => "$au_reg_path\\UseWUServer",
      type   => 'dword',
      data   => 0,
      notify => Service['wuauserv'],
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
    data   => $RescheduleWaitTimeEnabled,
  }

  registry_value { 'RescheduleWaitTime':
    ensure => present,
    path   => "$au_reg_path\\RescheduleWaitTime",
    type   => 'dword',
    data   => $reschedule_wait_time,
  }

}
