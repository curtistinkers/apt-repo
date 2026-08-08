---
layout: default
title: Package Directory
# permalink: /packages/
---

Browse the custom configuration sets, tools, and package definitions actively
hosted across our infrastructure matrices.

| Target Suite | Component | Package Identifier | Version | Description |
| :----------- | :-------- | :----------------- | :------ | :---------- |
{% for pkg in site.data.packages.packages %}
| `{{ pkg.suite }}` | *{{ pkg.component }}* | **{{ pkg.name }}** | `{{ pkg.version }}` | {{ pkg.description }} |
{% else %}
| *N/A* | *N/A* | *No software packages cataloged in the repository loops yet.* | *N/A* | *N/A* |
{% endfor %}
