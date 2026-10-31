def catalog() -> dict:
    return None

def scenarios() -> list[dict]:
    return None

def baseline(snapshot, plans) -> str:
    return None

def validate(raw_text, snapshot, plans) -> dict:
    return None

def verify_identity(manifest_path, model_file, *, opener=None) -> dict:
    return None

def gemma(snapshot, plans, seed, *, opener=None) -> dict:
    return None

def run(backend, output_dir, *, manifest_path=None, model_file=None, opener=None) -> dict:
    return None

def main(argv=None) -> int:
    return None
