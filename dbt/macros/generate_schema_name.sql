{#- Usa el schema configurado tal cual ("staging", "marts"). Por defecto dbt
    lo concatena con el del perfil y crearía "staging_staging". -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
