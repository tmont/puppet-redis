# == Class: redis
#
# Install redis.
#
# === Parameters
#
# [*version*]
#   Version to install.
#   Default: 2.4.13
#
# [*redis_src_dir*]
#   Location to unpack source code before building and installing it.
#   Default: /opt/redis-src
#
# [*redis_bin_dir*]
#   Location to install redis binaries.
#   Default: /opt/redis
#
# === Examples
#
# include redis
#
# class { 'redis':
#   version       => '2.6',
#   redis_src_dir => '/fake/path/redis-src',
#   redis_bin_dir => '/fake/path/redis',
# }
#
# === Authors
#
# Thomas Van Doren
#
# === Copyright
#
# Copyright 2012 Thomas Van Doren, unless otherwise noted.
#
class redis (
  $version = $redis::params::version,
  $redis_src_dir = $redis::params::redis_src_dir,
  $redis_bin_dir = $redis::params::redis_bin_dir
) inherits redis::params {
  include gcc

  anchor { 'redis::begin':
    before => [ Redis::Instance['redis-default'] ]
  }

  $redis_pkg_name = "redis-${version}.tar.gz"
  $redis_pkg = "${redis_src_dir}/${redis_pkg_name}"
  $real_redis_bin_dir = "${redis_bin_dir}/redis-${version}"
  $real_redis_src_dir = "${redis_src_dir}/redis-${version}"

  # Install default instance
  redis::instance { 'redis-default': }

  File {
    owner => root,
    group => root,
  }
  file { $redis_src_dir:
    ensure => directory,
  }
  file { '/etc/redis':
    ensure => directory,
  }
  file { 'redis-lib':
    ensure => directory,
    path   => '/var/lib/redis',
  }

  exec { 'get-redis-pkg':
    command => "wget --output-document ${redis_pkg} http://download.redis.io/releases/${redis_pkg_name}",
    creates => $redis_pkg,
    require => File[$redis_src_dir],
  }
  exec { 'unpack-redis':
    command => "tar -xzf ${redis_pkg}",
    cwd     => $redis_src_dir,
    creates => "${real_redis_src_dir}/Makefile",
    require => Exec['get-redis-pkg'],
  }
  exec { 'install-redis':
    command => "make && make install PREFIX=${real_redis_bin_dir}",
    cwd     => $real_redis_src_dir,
    creates => "${real_redis_bin_dir}/bin/redis-server",
    require => [ Exec['unpack-redis'], Class['gcc'] ],
  }
  file { 'redis-cli-link':
    ensure => link,
    path   => '/usr/local/bin/redis-cli',
    target => "${real_redis_bin_dir}/bin/redis-cli",
    require => Exec['install-redis'],
  }

  anchor { 'redis::end':
    require => [ File['redis-cli-link'], File['redis-lib'], File['/etc/redis'] ]
  }
}
