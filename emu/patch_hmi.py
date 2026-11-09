#!/usr/bin/env python3
"""Idempotent byte patches for the MGU22 Hmi8 binary so it behaves in the emulator.

Hmi8's text segment is mapped at file offset 0, so vaddr == file offset.
Each patch checks the original bytes first; a backup Hmi8.orig is kept once.

  touch-gate: CHmiDisplayAndEarlyVideoInputHandler::onTouchEvent -> `mov w0,#0; ret`
      In the car the display manager reports the CID panel as on; here nothing does, so the
      handler thinks the screen is off and swallows every touch as a "wake the screen" tap.
      Returning false ("not handled") lets touches fall through to the real UI handlers.
  early-hmi: EarlyHMI handover timeout 30 s -> 1 s (see below).
"""
import shutil
import sys

PATCHES = [
    # name, offset, original bytes, patched bytes
    ("touch-gate", 0x5daa2ec,
     bytes.fromhex("3f2303d5ff8303d1"),          # paciasp; sub sp, sp, #0xe0
     bytes.fromhex("00008052c0035fd6")),         # mov w0, #0; ret
    # early-hmi: CEarlyVideoService::startEarlyHmiTimeoutTimer arms a 30 s timer waiting for the
    # boot-animation process (EarlyHMI) to hand the screen over. There is none here, so the HMI
    # sat invisible until it timed out. Same path, 1 s instead of 30 s.
    ("early-hmi", 0x5cc4a1c,
     bytes.fromhex("04a68e52"),                  # mov w4, #30000
     bytes.fromhex("047d8052")),                 # mov w4, #1000
]


def main(path):
    with open(path, "r+b") as f:
        todo = []
        for name, off, orig, new in PATCHES:
            f.seek(off)
            cur = f.read(len(orig))
            if cur == new:
                print(f"{name}: already applied")
            elif cur == orig:
                todo.append((name, off, new))
            else:
                sys.exit(f"{name}: unexpected bytes {cur.hex()} at {off:#x} - wrong Hmi8 build?")
    if not todo:
        return
    backup = path + ".orig"
    try:
        open(backup, "rb").close()
    except FileNotFoundError:
        shutil.copy2(path, backup)
        print(f"backup -> {backup}")
    with open(path, "r+b") as f:
        for name, off, new in todo:
            f.seek(off)
            f.write(new)
            print(f"{name}: patched at {off:#x}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/srv/mgu22/root/opt/ivi/rootfs/usr/bin/Hmi8")
