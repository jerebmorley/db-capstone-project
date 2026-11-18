{#- Test genérico de una dimensión SCD2. Devuelve las entidades con algún problema:
      * un rango vacío o invertido (valid_from >= valid_to)
      * un hueco o una superposición entre versiones consecutivas
      * una cantidad de versiones vigentes distinta de 1 -#}
{% test scd2_integrity(model, entity_column) %}

with versions as (
    select
        {{ entity_column }} as entity,
        valid_from,
        valid_to,
        is_current,
        lead(valid_from) over (partition by {{ entity_column }} order by valid_from) as next_valid_from
    from {{ model }}
)

select entity, 'rango vacío o invertido' as problem
from versions
where valid_from >= valid_to

union all

select entity, 'hueco o superposición'
from versions
where next_valid_from is not null and next_valid_from <> valid_to

union all

select entity, 'versiones vigentes: ' || count(*) filter (where is_current)
from versions
group by entity
having count(*) filter (where is_current) <> 1

{% endtest %}
