import importlib.machinery
import importlib.util
import pathlib

try:
    import pytest
except ImportError:
    class _RaisesContext:
        def __init__(self, exc):
            self.exc = exc

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc_val, exc_tb):
            if exc_type is None:
                raise AssertionError(f"Expected {self.exc.__name__} but nothing was raised")
            return issubclass(exc_type, self.exc)

    class _PytestStub:
        @staticmethod
        def raises(exc):
            return _RaisesContext(exc)

    pytest = _PytestStub()

STORE = pathlib.Path(__file__).parent.parent / "profile/airootfs/usr/local/bin/cyberos-store"


def load():
    spec = importlib.util.spec_from_loader(
        "cyberos_store",
        importlib.machinery.SourceFileLoader("cyberos_store", str(STORE))
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_parses_pacman_sl_rows():
    store = load()
    text = ("cyberos-apps ghidra 11.4-1\n"
            "cyberos-apps cyberos-plugin-ctf 1.2-1 [installed]\n")
    rows = store.parse_pacman_sl(text)
    assert len(rows) == 2
    assert rows[0] == {"repo": "cyberos-apps", "name": "ghidra",
                       "version": "11.4-1", "installed": False}
    assert rows[1]["installed"] is True


def test_ignores_blank_and_malformed_lines():
    store = load()
    rows = store.parse_pacman_sl("\n  \ngarbage\ncyberos-apps demo 1.0-1\n")
    assert [r["name"] for r in rows] == ["demo"]


def test_classify_uses_the_naming_convention():
    store = load()
    assert store.classify("cyberos-plugin-ctf", None) == "plugin"
    assert store.classify("ghidra", None) == "app"


def test_classify_prefers_the_appstream_type():
    store = load()
    assert store.classify("ghidra", "addon") == "plugin"
    assert store.classify("cyberos-plugin-ctf", "desktop-application") == "app"


def test_install_goes_through_pacman_not_a_hand_rolled_downloader():
    store = load()
    argv = store.install_argv("ghidra")
    assert argv == ["pkexec", "pacman", "-S", "--needed", "--noconfirm", "ghidra"]


def test_install_rejects_a_name_that_is_not_a_package_name():
    store = load()
    with pytest.raises(ValueError):
        store.install_argv("ghidra; rm -rf /")
    with pytest.raises(ValueError):
        store.install_argv("--config=/tmp/evil")


if __name__ == "__main__":
    test_parses_pacman_sl_rows()
    test_ignores_blank_and_malformed_lines()
    test_classify_uses_the_naming_convention()
    test_classify_prefers_the_appstream_type()
    test_install_goes_through_pacman_not_a_hand_rolled_downloader()
    test_install_rejects_a_name_that_is_not_a_package_name()
    print("All test_store tests pass.")
