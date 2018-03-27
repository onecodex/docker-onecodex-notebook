{%- extends 'full.tpl' -%}

{%- block header -%}
  {{ super() }}
{%- endblock header -%}

{% block output_area_prompt %}
{% endblock output_area_prompt %}

{% block input_group %}
<div class="input_hidden">
  {% if cell.metadata.show_input == True %}
    {{ super() }}
  {% endif %}
</div>
{% endblock input_group %}

{% block output_group %}
  {{ super() }}
{% endblock %}