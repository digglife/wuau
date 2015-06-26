# wuau

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with wuau](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

`wuau` is a puppet module for configuring **W**indows **U**pdate **A**utomatic **U**pdate.
It covers most of the configurable options mentioned in the [official documents](https://technet.microsoft.com/en-us/library/dd939844%28v=ws.10%29.aspx), so we can control every aspects of the behavior of Windows Automatic Update via Puppet.

```puppet
class { 'wuau':
    enabled => true,
    type    => 'schedule',
    wsus_server => 'http://10.0.0.111',
    target_group => 'Production',
    auto_reboot  => true,
}

```

## Module Description

If applicable, this section should have a brief description of the technology
the module integrates with and what that integration enables. This section
should answer the questions: "What does this module *do*?" and "Why would I use
it?"

If your module has a range of functionality (installation, configuration,
management, etc.) this is the time to mention it.

## Setup


## Usage

Put the classes, types, and resources for customizing, configuring, and doing
the fancy stuff with your module here.

## Reference

Here, list the classes, types, providers, facts, etc contained in your module.
This section should include all of the under-the-hood workings of your module so
people know what the module is touching on their system but don't need to mess
with things. (We are working on automating this section!)

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.
