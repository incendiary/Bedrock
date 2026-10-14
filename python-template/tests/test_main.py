from src.main import main


def test_main_prints_greeting(capsys):
    main()
    assert "Hello from" in capsys.readouterr().out
