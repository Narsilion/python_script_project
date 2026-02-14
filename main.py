import time
from datetime import datetime, timezone


TOTAL_STEPS = 6
SLEEP_SECONDS = 5


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> None:
    print(f"[{now_utc()}] job started")

    for step in range(1, TOTAL_STEPS + 1):
        print(f"[{now_utc()}] step {step}/{TOTAL_STEPS}")
        time.sleep(SLEEP_SECONDS)

    print(f"[{now_utc()}] job completed successfully")


if __name__ == "__main__":
    main()
