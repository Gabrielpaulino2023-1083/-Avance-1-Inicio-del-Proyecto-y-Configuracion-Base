"""
Pruebas unitarias del motor de aprendizaje adaptativo (adaptive-engine).

Cada prueba empieza con el ID de la matriz (CP-MOT-xx / CP-VAL-xx) para que
el reporte pueda relacionarla con su caso. Las pruebas describen el
comportamiento CORRECTO esperado: si hoy fallan, es porque encontraron un
defecto (ver tests/INCIDENCIAS.md), no porque la prueba esté mal.

Ejecutar desde la raíz del repositorio:
    python -m pytest tests/unit/motor -v
"""

import copy
import json
import math
import sys
from pathlib import Path

import pytest

ENGINE_DIR = Path(__file__).resolve().parents[3] / "adaptive-engine"
sys.path.insert(0, str(ENGINE_DIR))

from engine import process_student  # noqa: E402


# ---------------------------------------------------------------- utilidades

def interaction(**overrides):
    base = {
        "study_minutes": 20,
        "errors": 2,
        "attempts": 2,
        "repetitions": 1,
        "navigation_count": 5,
        "score_percentage": 75,
    }
    base.update(overrides)
    return base


def student(*interactions, student_id=1, topic="SQL JOIN"):
    return {
        "student_id": student_id,
        "topic": topic,
        "interactions": list(interactions) or [interaction()],
    }


def action_of(data):
    return process_student(data)["recommendation"]["action"]


# ------------------------------------------------------- escenarios del motor

def test_CP_MOT_01_rendimiento_bajo_refuerza_el_tema():
    result = process_student(student(interaction(score_percentage=45, errors=6)))
    rec = result["recommendation"]
    assert rec["action"] == "reinforce_topic"
    assert rec["difficulty"] == "reduced"
    assert "SQL JOIN" in rec["recommendation"]
    assert result["profile"]["average_score"] == 45


def test_CP_MOT_02_rendimiento_medio_mantiene_dificultad():
    rec = process_student(student(interaction(score_percentage=75, errors=2)))["recommendation"]
    assert rec["action"] == "maintain_difficulty"
    assert rec["difficulty"] == "current"


def test_CP_MOT_03_rendimiento_alto_aumenta_dificultad():
    rec = process_student(
        student(interaction(score_percentage=95, errors=0, attempts=1))
    )["recommendation"]
    assert rec["action"] == "increase_difficulty"
    assert rec["difficulty"] == "increased"


@pytest.mark.parametrize(
    "score, errors, attempts, esperado",
    [
        (59.99, 0, 1, "reinforce_topic"),       # justo debajo de 60
        (60, 0, 1, "maintain_difficulty"),       # 60 ya no es refuerzo
        (90, 5, 1, "reinforce_topic"),           # 5 errores fuerza refuerzo
        (90, 4, 1, "maintain_difficulty"),       # 4 errores no
        (84.99, 0, 1, "maintain_difficulty"),    # justo debajo de 85
        (85, 2, 2, "increase_difficulty"),       # todos los límites incluidos
        (85, 3, 2, "maintain_difficulty"),       # 3 errores impide aumentar
        (85, 2, 3, "maintain_difficulty"),       # 3 intentos impide aumentar
        (50, 0, 1, "reinforce_topic"),           # refuerzo tiene prioridad
    ],
)
def test_CP_MOT_04_valores_limite_de_las_reglas(score, errors, attempts, esperado):
    data = student(interaction(score_percentage=score, errors=errors, attempts=attempts))
    assert action_of(data) == esperado


def test_CP_MOT_05_material_complementario_solo_en_refuerzo():
    refuerzo = process_student(
        student(interaction(score_percentage=40, errors=1, repetitions=5))
    )["recommendation"]["recommendation"]
    mantener = process_student(
        student(interaction(score_percentage=75, errors=1, repetitions=5))
    )["recommendation"]["recommendation"]
    assert "material complementario" in refuerzo
    assert "material complementario" not in mantener


def test_CP_MOT_06_archivo_de_ejemplo_del_repositorio():
    with (ENGINE_DIR / "data" / "estudiante_prueba.json").open(encoding="utf-8") as f:
        data = json.load(f)
    result = process_student(data)
    assert result["profile"]["average_score"] == 53.33
    assert result["profile"]["total_errors"] == 9
    assert result["profile"]["average_attempts"] == 3.0
    assert result["recommendation"]["action"] == "reinforce_topic"


def test_CP_MOT_07_calculo_del_perfil_con_varias_interacciones():
    data = student(
        interaction(study_minutes=10, errors=1, attempts=1, repetitions=0, navigation_count=2, score_percentage=70),
        interaction(study_minutes=20, errors=2, attempts=2, repetitions=1, navigation_count=4, score_percentage=80),
        interaction(study_minutes=30, errors=0, attempts=3, repetitions=2, navigation_count=6, score_percentage=90),
    )
    profile = process_student(data)["profile"]
    assert profile == {
        "student_id": 1,
        "topic": "SQL JOIN",
        "average_score": 80.0,
        "total_errors": 3,
        "average_attempts": 2.0,
        "total_repetitions": 3,
        "average_study_minutes": 20.0,
        "total_interactions": 3,
    }


def test_CP_MOT_08_salida_respeta_el_contrato_del_frontend():
    result = process_student(student())
    assert set(result) == {"profile", "recommendation"}
    assert set(result["recommendation"]) == {
        "student_id", "topic", "action", "difficulty", "reason", "recommendation",
    }
    assert result["recommendation"]["action"] in {
        "reinforce_topic", "increase_difficulty", "maintain_difficulty",
    }
    assert result["recommendation"]["difficulty"] in {"reduced", "increased", "current"}
    # Debe poder serializarse como JSON estándar (lo que leerá Node).
    json.loads(json.dumps(result, allow_nan=False))


def test_CP_MOT_08_no_modifica_los_datos_de_entrada():
    data = student(interaction(score_percentage="80"))
    original = copy.deepcopy(data)
    process_student(data)
    assert data == original


# ------------------------------------------------- datos vacíos e incorrectos

def test_CP_VAL_01_interacciones_vacias():
    data = student()
    data["interactions"] = []
    with pytest.raises(ValueError, match="al menos una interacción"):
        process_student(data)


@pytest.mark.parametrize("modo", ["ausente", "null"])
def test_CP_VAL_02_interacciones_ausentes_o_null(modo):
    data = student()
    if modo == "ausente":
        del data["interactions"]
    else:
        data["interactions"] = None
    with pytest.raises(ValueError):
        process_student(data)


@pytest.mark.parametrize(
    "campo",
    ["study_minutes", "errors", "attempts", "repetitions", "navigation_count", "score_percentage"],
)
def test_CP_VAL_03_campo_obligatorio_faltante(campo):
    data = student()
    del data["interactions"][0][campo]
    with pytest.raises(ValueError, match=campo):
        process_student(data)


@pytest.mark.parametrize(
    "campo, valor",
    [
        ("score_percentage", "abc"),
        ("score_percentage", ""),
        ("errors", None),
        ("attempts", [1, 2]),
        ("study_minutes", "veinte"),
    ],
)
def test_CP_VAL_04_valores_no_numericos_o_nulos(campo, valor):
    data = student(interaction(**{campo: valor}))
    with pytest.raises(ValueError, match="numéricos"):
        process_student(data)


@pytest.mark.parametrize(
    "campo, valor",
    [
        ("score_percentage", 150),
        ("score_percentage", -1),
        ("study_minutes", -5),
        ("errors", -1),
        ("attempts", 0),
        ("repetitions", -2),
        ("navigation_count", -3),
    ],
)
def test_CP_VAL_05_valores_fuera_de_rango(campo, valor):
    data = student(interaction(**{campo: valor}))
    with pytest.raises(ValueError, match="fuera de los rangos"):
        process_student(data)


def test_CP_VAL_06_numeros_como_texto_se_convierten():
    data = student(interaction(score_percentage="90", errors="0", attempts="1"))
    assert action_of(data) == "increase_difficulty"


@pytest.mark.parametrize("campo", ["student_id", "topic"])
def test_CP_VAL_07_falta_student_id_o_topic(campo):
    data = student()
    del data[campo]
    # Lo correcto: ValueError descriptivo, como con los otros campos obligatorios.
    # Hoy el motor lanza KeyError('topic') sin explicación (ver INC-04).
    with pytest.raises(ValueError, match=campo):
        process_student(data)


@pytest.mark.parametrize("valor", ["abc", {"a": 1}, [1, 2]])
def test_CP_VAL_08_interactions_con_tipo_incorrecto(valor):
    data = student()
    data["interactions"] = valor
    with pytest.raises(ValueError):
        process_student(data)


@pytest.mark.parametrize(
    "campo, valor",
    [
        ("study_minutes", math.inf),
        ("score_percentage", math.nan),
        ("navigation_count", math.inf),
    ],
)
def test_CP_VAL_09_infinito_o_nan_se_rechazan(campo, valor):
    data = student(interaction(**{campo: valor}))
    with pytest.raises(ValueError):
        process_student(data)


@pytest.mark.parametrize("campo", ["score_percentage", "errors"])
def test_CP_VAL_10_booleanos_se_rechazan(campo):
    data = student(interaction(**{campo: True}))
    with pytest.raises(ValueError):
        process_student(data)


@pytest.mark.parametrize("campo", ["errors", "attempts", "repetitions", "navigation_count"])
def test_CP_VAL_11_conteos_con_decimales_se_rechazan(campo):
    data = student(interaction(**{campo: 2.7}))
    with pytest.raises(ValueError):
        process_student(data)
