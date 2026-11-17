import importlib


MODULES = ["embedder"]


def test_all_modules_import():
    failures = []
    for module_name in MODULES:
        try:
            importlib.import_module(module_name)
        except Exception as exc:
            failures.append(f"{module_name}: {exc}")
    if failures:
        raise AssertionError("Failed to import modules:\n" + "\n".join(failures))
