# wuau

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
4. [Usage ](#usage)
5. [Reference ](#reference)
5. [Limitations](#limitations)
6. [Development](#development)

## Overview

`wuau` is a puppet module for configuring **W**indows **U**pdate **A**utomatic **U**pdate.
It covers most of the configurable options mentioned in the [official documents](https://technet.microsoft.com/en-us/library/dd939844%28v=ws.10%29.aspx), so we can control every aspect of the behavior of Windows Automatic Update via Puppet.

```puppet
class { 'wuau':
    enabled      => true,
    type         => 'schedule',
    wsus_server  => 'http://10.0.0.111',
    target_group => 'Production',
    auto_reboot  => false,
}

```

## Module Description



## Setup


## Usage


### `enabled`
   (`boolean`) Enable automatic update or not. Default is true.
### `type`
   (`string`) options for automatic update. Default is `schedule`.
    Possible types are:
    1. `notify`. Notify before download.
    2. `download`. Automatically download and notify of installation. 
    3. `schedule`. Automatically download and schedule installation.
    4. `custom`. Automatic Updates is required, but end users can configure it.
### `wsus_server`
   (`string`) URL of WSUS Server. Default is `undef`.
### `target_group`
   (`string`) target group on WSUS Server. Default is `undef`.
### `auto_reboot`
   (`boolean`) 
   **true**  : Notifies user that the server will restart in 15 minutes.
   **false** : Logged-on user can choose whether or not to restart.
   The server will restart anyway if there is no logged-on user. 
   Default is `true`.
### `auto_install_minor_updates`
   (`boolean`) Silently install minor updates(no restart required) or not. 
   Default is `false`.
### `include_recommended_updates`
   (`boolean`) install recommended updates or not. Default is `false`.
### `power_management_enabled`
   (`boolean`) whether wake up the server to install the updates. Default is `true`.
### `scheduled_install_day`
   (`integer`) `0` for `daily`. `1-7` for `Sunday(1)` to `Saturday(7)`. Default is `7`.
   Only applies when `type` is `schedule`.
### `scheduled_install_time`
   (`integer`) 24-hour format (`0–23`). Default is `3`.
   Only applies when `type` is `schedule`.
### `detection_frequency`
   (`integer`) Time in hours (`1–22`) between detection cycle. Default is `22`.
### `reboot_relaunch_timeout`
   (`integer`) Time in minutes(`1-1440`) between prompting again for a scheduled restart.
   Default is `10`.
### `reboot_warning_timeout`
   (`integer`) Time in minutes (`1-30`) of the restart warning countdown,
   after installing updates with a deadline or scheduled updates.
   Default is `5`.
### `reschedule_wait_time`
   (`integer`) Time in minutes(`0-60`), that Automatic Updates should wait at startup 
   before applying updates from a missed scheduled installation time.
   This policy applies only when `type` is `schedule`.
   Default is `1`.
   *NOTE* : if it's set as 0,  a missed scheduled installation will occur
            during the next scheduled installation time.


## Reference

[https://technet.microsoft.com/en-us/library/cc720464%28v=ws.10%29.aspx]

## Limitations

Tested on :

Windows Server 2003
Windows Server 2008
Windows Server 2012

But it should be also applicable to Windows XP/7/8.

## Development

Please kindly raise issue if you find any bugs. Any thought is welcome.
