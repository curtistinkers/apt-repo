---
layout: default
title: Package Directory
permalink: /packages/
---

Browse the custom configuration sets, tools, and package definitions actively
hosted across our infrastructure matrices.

{% assign suite_groups = site.data.packages.packages | group_by: "suite" %}

## Packages by Suite

{% for group in suite_groups %}

---

### {{ group.name }}

<!-- markdownlint-disable no-inline-html -->
<table>
  <thead>
    <tr>
      <th>Package Identifier</th>
      <th>Version</th>
      <th>Description</th>
      <th>Component</th>
    </tr>
  </thead>
  <tbody>
    {% for pkg in group.items %}
    <tr>
      <td>
        <a href="/pool/{{ pkg.suite }}/{{ pkg.component }}/{{ pkg.file }}">
          <strong>{{ pkg.name }}</strong>
        </a>
      </td>
      <td><code>{{ pkg.version }}</code></td>
      <td>{{ pkg.description }}</td>
      <td><em>{{ pkg.component }}</em></td>
    </tr>
    {% endfor %}
  </tbody>
</table>
{% else %}
<table>
  <tbody>
    <tr>
      <td style="text-align: center; font-style: italic; padding: 20px;">
        No software packages catalogued in the repository yet.
      </td>
    </tr>
  </tbody>
</table>
<!-- markdownlint-enable no-inline-html -->
{% endfor %}
