# This setup for mongodb assumes that the replica set can be determined from
# the id of the minion
# NOTE: Currently this will not work behind a NAT in AWS VPC.
# see http://lodge.glasgownet.com/2012/07/11/apt-key-from-behind-a-firewall/comment-page-1/ for details
{% from "mongodb/map.jinja" import mongodb with context %}

{% set version        = salt['pillar.get']('mongodb:version', '2.4.6') %}
{% set package_name   = salt['pillar.get']('mongodb:package_name', "mongodb-10gen") %}

{% if version is not none %}

{% set bind_ip        = salt['pillar.get']('mongodb:bind_ip', {}) %}
{% set port           = salt['pillar.get']('mongodb:port', 27017) %}
{% set replica_set    = salt['pillar.get']('mongodb:replica_set', "mongodb") %}
{% set config_svr     = salt['pillar.get']('mongodb:config_svr', False) %}
{% set shard_svr      = salt['pillar.get']('mongodb:shard_svr', False) %}
{% set use_ppa        = salt['pillar.get']('mongodb:use_ppa', True) %}
{% set db_path        = salt['pillar.get']('mongodb:db_path', '/data') %}
{% set log_path       = salt['pillar.get']('mongodb:log_path', '/var/log/mongodb') %}

/data:
  mount.mounted:
    - device: /dev/xvdf
    - fstype: ext4
    - mkmnt: True
  
/journal:
  mount.mounted:
    - device: /dev/xvdg
    - fstype: ext4
    - mkmnt: True
  
/data/journal:
  file.symlink:
    - target: /journal

mongodb_db_path:
  file.directory:
    - name: {{ db_path }}
    - user: mongodb
    - group: mongodb
    - mode: 755
    - makedirs: True
    - recurse:
        - user
        - group

mongodb_journal_path:
  file.directory:
    - name: /journal
    - user: mongodb
    - group: mongodb
    - mode: 755
    - makedirs: True
    - recurse:
        - user
        - group

mongodb_log_path:
  file.directory:
    - name: {{ log_path }}
    - user: mongodb
    - group: mongodb
    - mode: 755
    - makedirs: True

mongodb_configuration:
  file.managed:
    - name: {{ mongodb.conf_path }}
    - user: root
    - group: root
    - mode: 644
    - source: salt://mongodb/files/mongodb.conf.jinja
    - template: jinja
    - context:
        dbpath: {{ db_path }}
        logpath: {{ log_path }}
        bind_ip: {{ bind_ip }}
        port: {{ port }}
        replica_set: {{ replica_set }}
        config_svr: {{ config_svr }}
        shard_svr: {{ shard_svr }}

mongodb_logrotate:
  file.managed:
    - name: /etc/logrotate.d/mongodb
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://mongodb/files/logrotate.jinja

mongodb_package:
{% if use_ppa %}
  pkgrepo.managed:
    - humanname: MongoDB PPA
    - name: deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen
    - file: /etc/apt/sources.list.d/mongodb.list
    - keyid: 7F0CEB10
    - keyserver: keyserver.ubuntu.com
  pkg.installed:
    - name: {{ package_name }}
    - version: {{ version }}
{% else %}
  pkg.installed:
     - name: mongodb
{% endif %}

mongodb_service:
  service.running:
    - name: {{ mongodb.mongod }}
    - enable: True
    - watch:
      - file: mongodb_configuration


{% endif %}
