{#- Convierte las versiones append-only de raw en rangos de validez SCD2.

    Por cada clave, ordena sus versiones y calcula:
      valid_from  inicio de la versión; la primera arranca en 1900-01-01
                  porque no sabemos desde cuándo valía (ver ADR-006)
      valid_to    inicio de la versión siguiente; la vigente, 9999-12-31
      is_current  true solo en la última versión
    Los rangos son [valid_from, valid_to): contiguos y sin superposición.

    Precisión: updatedat tiene microsegundos, pero las fechas de los eventos
    (OrderDate, ReservationDate) solo segundos. Por eso cada versión rige desde
    el inicio de su segundo: un pedido hecho en el mismo segundo que el cambio
    ya ve la versión nueva. Si hay varias versiones en el mismo segundo, queda
    la última (mayor updatedat y, si empatan, mayor _batch_id). -#}
{% macro scd2_from_raw(relation, key) %}
    with unique_versions as (
        select distinct on ({{ key }}, date_trunc('second', updatedat))
            *,
            date_trunc('second', updatedat) as _version_start
        from {{ relation }}
        order by {{ key }}, date_trunc('second', updatedat), updatedat desc, _batch_id desc
    )

    select
        *,
        case
            when lag(_version_start) over by_key is null then timestamp '1900-01-01'
            else _version_start
        end as valid_from,
        coalesce(lead(_version_start) over by_key, timestamp '9999-12-31') as valid_to,
        lead(_version_start) over by_key is null as is_current
    from unique_versions
    window by_key as (partition by {{ key }} order by _version_start)
{% endmacro %}
