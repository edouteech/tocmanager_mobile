import atexit
import os
import tempfile

# Isolate tests from the repository's ./tocmanager.db before importing app.*
if "DATABASE_URL" not in os.environ:
    _tmp_db_file = os.path.join(
        tempfile.gettempdir(), f"tocmanager_pytest_{os.getpid()}.db"
    )
    os.environ["DATABASE_URL"] = f"sqlite:///{_tmp_db_file}"

    def _cleanup_tmp_db() -> None:
        if os.path.exists(_tmp_db_file):
            try:
                os.remove(_tmp_db_file)
            except OSError:
                pass

    atexit.register(_cleanup_tmp_db)
