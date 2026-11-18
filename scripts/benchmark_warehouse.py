"""Benchmark de las consultas del warehouse con EXPLAIN ANALYZE.

Por cada archivo de benchmarks/queries/: una corrida de calentamiento que se
descarta y N corridas medidas con EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON).
Reporta la mediana del tiempo de ejecución, el nodo del plan que más tiempo
propio consumió y el peor error de estimación de filas (señal de estadísticas
malas). Imprime una tabla en markdown y guarda los planes en
generated/benchmarks/<etiqueta>/.

Uso:
    set -a; source .env; set +a
    python scripts/benchmark_warehouse.py --label baseline
"""

import argparse
import json
import statistics
import sys
from pathlib import Path

from db_connections import conectar_postgres

RAIZ = Path(__file__).resolve().parents[1]
CONSULTAS = RAIZ / "benchmarks" / "queries"
SALIDA = RAIZ / "generated" / "benchmarks"


def nodos(plan):
    """Recorre el plan y devuelve cada nodo."""
    yield plan
    for hijo in plan.get("Plans", []):
        yield from nodos(hijo)


def tiempo_propio(nodo):
    """Milisegundos del nodo sin contar a sus hijos (ajustado por loops)."""
    total = nodo["Actual Total Time"] * nodo["Actual Loops"]
    hijos = sum(h["Actual Total Time"] * h["Actual Loops"] for h in nodo.get("Plans", []))
    return max(total - hijos, 0.0)


def describir(nodo):
    tabla = nodo.get("Relation Name") or nodo.get("Index Name") or ""
    return f"{nodo['Node Type']} {tabla}".strip()


def peor_estimacion(plan):
    """Mayor error (veces) entre filas estimadas y reales en el plan."""
    peor, cual = 1.0, ""
    for n in nodos(plan):
        if n["Actual Loops"] == 0:  # nodo que no llegó a ejecutarse
            continue
        # Las dos cifras son por loop, así que se comparan directamente.
        estimadas = max(n["Plan Rows"], 1)
        reales = max(n["Actual Rows"], 1)
        error = max(estimadas / reales, reales / estimadas)
        if error > peor:
            peor, cual = error, describir(n)
    return peor, cual


def medir(pg, sql, corridas):
    explain = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) {sql}"
    pg.execute(explain)  # calentamiento: se descarta
    resultados = [pg.execute(explain).fetchone()[0][0] for _ in range(corridas)]
    tiempos = [r["Execution Time"] for r in resultados]
    mediano = sorted(resultados, key=lambda r: r["Execution Time"])[len(resultados) // 2]
    return tiempos, mediano


def main(argv=None):
    parser = argparse.ArgumentParser(description="Benchmark del warehouse con EXPLAIN ANALYZE.")
    parser.add_argument("--label", required=True, help="nombre de la medición (ej.: baseline)")
    parser.add_argument("--runs", type=int, default=5, help="corridas medidas por consulta")
    args = parser.parse_args(argv)

    destino = SALIDA / args.label
    destino.mkdir(parents=True, exist_ok=True)
    pg = conectar_postgres()
    pg.autocommit = True
    filas = []
    try:
        for archivo in sorted(CONSULTAS.glob("*.sql")):
            sql = archivo.read_text(encoding="utf-8").strip().rstrip(";")
            tiempos, plan = medir(pg, sql, args.runs)
            (destino / f"{archivo.stem}.json").write_text(json.dumps(plan, indent=2))
            raiz = plan["Plan"]
            caro = max(nodos(raiz), key=tiempo_propio)
            error, donde = peor_estimacion(raiz)
            filas.append((
                archivo.stem,
                statistics.median(tiempos),
                min(tiempos),
                max(tiempos),
                plan["Planning Time"],
                f"{describir(caro)} ({tiempo_propio(caro):.0f} ms)",
                f"{error:,.0f}x {donde}" if error >= 10 else "<10x",
            ))
    finally:
        pg.close()

    print(f"## {args.label} ({args.runs} corridas por consulta, mediana)\n")
    print("| Consulta | Mediana (ms) | Mín–máx (ms) | Planif. (ms) | Nodo más caro | Peor estimación |")
    print("|---|---:|---:|---:|---|---|")
    for nombre, mediana, minimo, maximo, planif, caro, error in filas:
        print(f"| {nombre} | {mediana:,.1f} | {minimo:,.0f}–{maximo:,.0f} | {planif:.1f} | {caro} | {error} |")
    print(f"\nPlanes completos en {destino.relative_to(RAIZ)}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
