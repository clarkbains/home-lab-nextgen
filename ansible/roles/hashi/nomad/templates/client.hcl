# /etc/nomad.d/client.hcl


client {
  enabled = true
{% if cfg.nomad_vols.names is defined %} {% for mount in cfg.nomad_vols.names.split(',') %}
  host_volume "{{mount}}" {
    path      = "{{mountpoint.content | b64decode | trim}}/{{mount}}"
    read_only = false
  }
{% endfor %} {% endif %}
}

plugin "docker" {
  config {
    allow_privileged = true
    volumes {
      enabled = true
    }
  }
}


