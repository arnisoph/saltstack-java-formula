#!jinja|yaml

{% set datamap = salt['formhelper.get_defaults']('java', saltenv, ['yaml'])['yaml'] %}

include: {{ datamap.sls_include|default([]) }}
extend: {{ datamap.sls_extend|default({}) }}

{% for package_type, package in datamap.manage|default({})|dictsort if package_type in ['jre', 'jdk'] %}
java_{{ package_type }}_root_dir:
  file:
    - directory
    - name: {{ datamap[package_type]['root']['path'] }}
    - mode: 755
    - user: root
    - group: root
    - makedirs: True

  {% for id, data in package.versions|default({})|dictsort %}
java_{{ package_type }}_{{ id }}_archive:
  archive:
    - extracted
    - name: {{ datamap[package_type]['root']['path'] }}/{{ id }}
    - source: {{ data.source }}
    {% if 'source_hash' in data %}
    - source_hash: {{ data.source_hash }}
    {% endif %}
    - archive_format: {{ data.archive_format|default('tar') }}
    - keep: {{ data.archive_cache|default(True) }}

java_{{ package_type }}_{{ id }}_perm:
  file:
    - directory
    - name: {{ datamap[package_type]['root']['path'] }}/{{ id }}
    - user: root
    - group: root
    - recurse:
      - user
      - group

java_{{ package_type }}_{{ id }}_deeplink:
  file:
    - symlink
    - name: {{ datamap[package_type]['root']['path'] }}/{{ id }}/src
    - target: {{ datamap[package_type]['root']['path'] }}/{{ id }}/{{ data.version }}
    - user: root
    - group: root
  {% endfor %}

java_{{ package_type }}_current:
  file:
    - symlink
    - name: {{ datamap[package_type]['root']['path'] }}/current
    - target: {{ datamap[package_type]['root']['path'] }}/{{ package.current_ver|default('none') }}
    - makedirs: True
    - user: root
    - group: root

java_{{ package_type }}_current_globsymlink:
  file:
    - symlink
    - name: /usr/bin/java
    - target: {{ datamap[package_type]['root']['path'] }}/current/src/bin/java
    - makedirs: True
    - user: root
    - group: root
{% endfor %}
