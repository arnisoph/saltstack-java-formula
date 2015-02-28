#!jinja|yaml

{% from 'java/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('java:lookup')) %}

include: {{ datamap.sls_include|default([]) }}
extend: {{ datamap.sls_extend|default({}) }}

{% for package in salt['pillar.get']('java', []) if package in ['jre', 'jdk'] %}
java_{{ package }}_dir:
  file:
    - directory
    - name: {{ datamap[package]['root']['path'] }}
    - mode: 755
    - user: root
    - group: root
    - makedirs: True

  {% for id, data in salt['pillar.get']('java:' ~ package ~ ':versions')|dictsort %}
java_{{ package }}_{{ id }}_archive:
  archive:
    - extracted
    - name: {{ datamap[package]['root']['path'] }}/{{ id }}
    - source: {{ data.source }}
    {% if 'source_hash' in data %}
    - source_hash: {{ data.source_hash }}
    {% endif %}
    - archive_format: {{ data.archive_format|default('tar') }}
    - keep: {{ data.archive_cache|default(True) }}

java_{{ package }}_{{ id }}_perm:
  file:
    - directory
    - name: {{ datamap[package]['root']['path'] }}/{{ id }}
    - user: root
    - group: root
    - recurse:
      - user
      - group

java_{{ package }}_{{ id }}_deeplink:
  file:
    - symlink
    - name: {{ datamap[package]['root']['path'] }}/{{ id }}/src
    - target: {{ datamap[package]['root']['path'] }}/{{ id }}/{{ data.version }}
    - user: root
    - group: root
  {% endfor %}

java_{{ package }}_current:
  file:
    - symlink
    - name: {{ datamap[package]['root']['path'] }}/current
    - target: {{ datamap[package]['root']['path'] }}/{{ salt['pillar.get']('java:' ~ package ~ ':current_ver', 'none') }}
    - makedirs: True
    - user: root
    - group: root

java_{{ package }}_current_globsymlink:
  file:
    - symlink
    - name: /usr/bin/java
    - target: {{ datamap[package].root.path }}/current/src/bin/java
    - makedirs: True
    - user: root
    - group: root
{% endfor %}
