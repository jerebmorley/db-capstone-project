{#- raw es append-only: cada cambio en MySQL es una fila nueva. Este macro deja
    solo la versión vigente de cada clave (la de mayor updatedat; _batch_id
    desempata si dos versiones comparten updatedat). -#}
{% macro latest_version(relation, key) %}
    select *
    from (
        select
            *,
            row_number() over (
                partition by {{ key }}
                order by updatedat desc, _batch_id desc
            ) as _version_rank
        from {{ relation }}
    ) as versions
    where _version_rank = 1
{% endmacro %}
