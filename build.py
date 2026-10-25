"""Build VendorBoard from source.

    python build.py

Needs Java 11+ and the Apache Flex SDK (mxmlc) with playerglobal.swc installed:
  - set FLEX_HOME to the SDK folder, or unpack the SDK at tools/flexsdk/
  - playerglobal.swc goes in <SDK>/frameworks/libs/player/32.0/ (the build copies it there from
    tools/playerglobal32_0.swc if present)

Steps: mxmlc compiles VendorBoard/scripts/VendorBoard.as (document class) with the library sources
under VendorBoard/scripts -> dist/interface/VendorBoard.swf; tools/ba2pack.py writes
dist/VendorBoard.ba2; the release zip is dist/VendorBoard-<version>.zip (+ a copy in ~/Downloads).
"""
import os, re, shutil, subprocess, sys, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
NAME = 'VendorBoard'
SRC_DIR = os.path.join(HERE, NAME, 'scripts')
MAIN = os.path.join(SRC_DIR, NAME + '.as')
OUT = os.path.join(HERE, 'dist')
VERSION = re.search(r'VERSION:String\s*=\s*"([^"]+)"', open(MAIN, encoding='utf-8').read()).group(1)


def find_sdk():
    for cand in (os.environ.get('FLEX_HOME'), os.path.join(HERE, 'tools', 'flexsdk')):
        if cand and os.path.exists(os.path.join(cand, 'lib', 'mxmlc.jar')):
            return cand
    raise SystemExit('Apache Flex SDK not found: set FLEX_HOME or unpack it at tools/flexsdk (see README.md)')


def main():
    sdk = find_sdk()
    player_dir = os.path.join(sdk, 'frameworks', 'libs', 'player', '32.0')
    swc = os.path.join(player_dir, 'playerglobal.swc')
    if not os.path.exists(swc):
        local = os.path.join(HERE, 'tools', 'playerglobal32_0.swc')
        if not os.path.exists(local):
            raise SystemExit('playerglobal.swc missing: put it at ' + swc)
        os.makedirs(player_dir, exist_ok=True)
        shutil.copy(local, swc)
    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(os.path.join(OUT, 'pack', 'interface'))
    swf = os.path.join(OUT, 'pack', 'interface', NAME + '.swf')
    env = dict(os.environ, PLAYERGLOBAL_HOME=os.path.join(sdk, 'frameworks', 'libs', 'player'))
    cmd = ['java', '-Xmx1024m', '-Dflexlib=' + os.path.join(sdk, 'frameworks'), '-jar', os.path.join(sdk, 'lib', 'mxmlc.jar'),
           '+flexlib=' + os.path.join(sdk, 'frameworks'),
           '-target-player=32.0', '-swf-version=34', '-static-link-runtime-shared-libraries=true',
           '-output=' + swf, '-source-path+=' + SRC_DIR, '--', MAIN]
    r = subprocess.run(cmd, capture_output=True, text=True, env=env)
    open(os.path.join(OUT, 'mxmlc.log'), 'w', encoding='utf-8').write(r.stdout + r.stderr)
    if r.returncode != 0 or not os.path.exists(swf):
        print(r.stdout[-3000:], r.stderr[-3000:])
        raise SystemExit('mxmlc failed, see dist/mxmlc.log')
    ba2 = os.path.join(OUT, NAME + '.ba2')
    r = subprocess.run([sys.executable, os.path.join(HERE, 'tools', 'ba2pack.py'), ba2, os.path.join(OUT, 'pack')], capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit('ba2pack failed: ' + r.stdout + r.stderr)
    zpath = os.path.join(OUT, f'{NAME}-{VERSION}.zip')
    with zipfile.ZipFile(zpath, 'w', zipfile.ZIP_DEFLATED) as z:
        z.write(ba2, NAME + '.ba2')
        z.write(os.path.join(HERE, 'Config', NAME + '.json'), NAME + '.json')
        z.write(os.path.join(HERE, 'extras', 'hudmodloader.example.ini'), 'hudmodloader.example.ini')
    downloads = os.path.join(os.path.expanduser('~'), 'Downloads')
    if os.path.isdir(downloads):
        shutil.copy(zpath, os.path.join(downloads, os.path.basename(zpath)))
    print('built', zpath, 'swf', os.path.getsize(swf), 'bytes')


if __name__ == '__main__':
    main()
