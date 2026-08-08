---
layout: default
title: Package Directory
# permalink: /packages/
---

Browse the custom configuration sets, tools, and package definitions actively
hosted across our infrastructure matrices.

<!-- markdownlint-disable no-inline-html -->
<table>
  <thead>
    <tr>
      <th>Target Suite</th>
      <th>Component</th>
      <th>Package Identifier</th>
      <th>Version</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    {% for pkg in site.data.packages.packages %}
    <tr>
      <td><code>{{ pkg.suite }}</code></td>
      <td><em>{{ pkg.component }}</em></td>
      <td><strong>{{ pkg.name }}</strong></td>
      <td><code>{{ pkg.version }}</code></td>
      <td>{{ pkg.description }}</td>
    </tr>
    {% else %}
    <tr>
      <td colspan="5" style="text-align: center; font-style: italic;">
        No software packages catalogued in the repository yet.
      </td>
    </tr>
    {% endfor %}
  </tbody>
</table>

<!-- markdownlint-enable no-inline-html -->
