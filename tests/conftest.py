"""Put the project source (../src) on the import path so tests can `import wallet`,
`import stoic_strategy`, etc. directly — the same flat layout the bot uses at runtime."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))
