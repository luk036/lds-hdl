#!/usr/bin/env python3
"""Cocotb test runner for lds-hdl 32-bit modules.

Usage:  python run.py [module_name ...]
        python run.py              # run all
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from cocotb_tools.runner import get_runner

ROOT = Path(__file__).parent.parent
RTL = ROOT / "rtl"
TEST_DIR = Path(__file__).parent / "tests"

MODULES = {
    "vdc_32": (
        "vdc_32", [RTL / "vdc_32.v"], "test_vdc_32"
    ),
    "vdc_3_ilds_32": (
        "vdc_3_ilds_32", [RTL / "vdc_3_ilds_32.v"], "test_vdc_3_ilds_32"
    ),
    "cordic_32": (
        "cordic_32", [RTL / "cordic_32.v"], "test_cordic_32"
    ),
    "cordic_sqrt_32": (
        "cordic_sqrt_32", [RTL / "cordic_sqrt_32.v"], "test_cordic_sqrt_32"
    ),
    "circle_2_32": (
        "circle_2_32",
        [RTL / f for f in ["circle_2_32.v", "vdc_32.v", "cordic_32.v"]],
        "test_circle_2_32",
    ),
    "circle_3_32": (
        "circle_3_32",
        [RTL / f for f in ["circle_3_32.v", "vdc_3_ilds_32.v", "cordic_32.v"]],
        "test_circle_3_32",
    ),
    "disk_32": (
        "disk_32",
        [RTL / f for f in ["disk_32.v", "circle_2_32.v", "vdc_32.v",
                           "cordic_32.v", "vdc_3_ilds_32.v", "cordic_sqrt_32.v"]],
        "test_disk_32",
    ),
    "sphere_32": (
        "sphere_32",
        [RTL / f for f in ["sphere_32.v", "vdc_32.v", "circle_3_32.v",
                           "vdc_3_ilds_32.v", "cordic_32.v", "cordic_sqrt_32.v"]],
        "test_sphere_32",
    ),
}


def check_results_xml(build_dir):
    xml_file = Path(build_dir) / "results.xml"
    if not xml_file.exists():
        return False, "no results.xml"
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        for testsuite in root.findall("testsuite"):
            failures = int(testsuite.get("failures", "0"))
            errors = int(testsuite.get("errors", "0"))
            if failures > 0 or errors > 0:
                return False, f"{failures} failures, {errors} errors"
        return True, "ok"
    except Exception as e:
        return False, str(e)


def main():
    names = sys.argv[1:] if len(sys.argv) > 1 else list(MODULES.keys())
    runner = get_runner("icarus")
    passed, failed = 0, 0

    for name in names:
        toplevel, sources, test_module = MODULES[name]
        src_strs = [str(s) for s in sources]
        build_dir = f"sim_build_{name}"

        print(f"\n{'='*60}\n  {name}\n{'='*60}")
        try:
            runner.build(
                sources=src_strs,
                hdl_toplevel=toplevel,
                build_dir=build_dir,
            )
            runner.test(
                hdl_toplevel=toplevel,
                test_module=test_module,
                test_dir=str(TEST_DIR),
                build_dir=build_dir,
            )
            ok, msg = check_results_xml(build_dir)
            if ok:
                print(f"  {name}: PASSED")
                passed += 1
            else:
                print(f"  {name}: FAILED ({msg})")
                failed += 1
        except Exception as e:
            print(f"  {name}: ERROR - {e}")
            failed += 1

    print(f"\n  Summary: {passed}/{passed+failed} passed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
