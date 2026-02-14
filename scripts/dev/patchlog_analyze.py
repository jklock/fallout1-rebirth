#!/usr/bin/env python3
"""Simple patchlog analyzer to find GNW_SHOW_RECT events where a surface
that was previously non-zero becomes zero (surf_pre>0 && surf_post==0).

Usage:
  ./patchlog_analyze.py tmp/rme/validation/runtime/patchlogs/CARAVAN.MAP.patchlog.txt

Outputs suspicious events with surrounding context.
"""
import re
import sys
from collections import deque

LINE_RE = re.compile(r'^\[(?P<ts>[^\]]+)\] \[(?P<tag>[^\]]+)\] (?P<data>.*)$')
KV_RE = re.compile(r"(\w+)=([\w\d:xA-Fa-f\-\._,()]+)")


def parse_kv_pairs(s):
    d = {}
    for m in KV_RE.finditer(s):
        k = m.group(1)
        v = m.group(2)
        d[k] = v
    return d


def to_int(x):
    try:
        return int(x)
    except Exception:
        return None


def parse_copy(copy):
    if not copy:
        return None, None
    if 'x' in copy:
        a, b = copy.split('x', 1)
        return to_int(a), to_int(b)
    return None, None


def analyze(path, window=1000, max_results=20):
    results = []
    # Read all lines up-front so we can look forward for recovery records that
    # follow a GNW_SHOW_RECT with surf_post==0 (these are benign if recovered).
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        lines = [ln.rstrip('\n') for ln in f]

    ctx = deque(maxlen=window)
    for lineno, line in enumerate(lines, start=1):
        m = LINE_RE.match(line)
        if not m:
            ctx.append((lineno, line))
            continue
        ts = m.group('ts')
        tag = m.group('tag')
        data = m.group('data')
        kv = parse_kv_pairs(data)

        entry = dict(lineno=lineno, ts=ts, tag=tag, data=data, kv=kv)
        ctx.append((lineno, line))

        if tag == 'GNW_SHOW_RECT':
            copy = kv.get('copy')
            w, h = parse_copy(copy)
            src_nonzero = to_int(kv.get('src_nonzero'))
            surf_pre = to_int(kv.get('surf_pre'))
            surf_post = to_int(kv.get('surf_post'))
            disp_pre = to_int(kv.get('disp_pre'))
            disp_post = to_int(kv.get('disp_post'))
            tex_pre = to_int(kv.get('tex_pre'))
            tex_post = to_int(kv.get('tex_post'))

            # suspicious: surface had data but was cleared by this copy
            if surf_pre and surf_post == 0:
                # Check forward for a GNW_SHOW_RECT_RECOVERED entry with the same
                # sequence number; if found, treat this as recovered and skip.
                seq_str = kv.get('seq')
                recovered = False
                if seq_str is not None:
                    # search next 200 lines for RECOVERED marker
                    for fwd_idx in range(lineno, min(len(lines), lineno + 200)):
                        fwd_line = lines[fwd_idx]
                        fm = LINE_RE.match(fwd_line)
                        if not fm:
                            continue
                        ftag = fm.group('tag')
                        fdata = fm.group('data')
                        if ftag == 'GNW_SHOW_RECT_RECOVERED' and ('seq=' + seq_str) in fdata:
                            recovered = True
                            break

                if recovered:
                    # Skip this event — the engine retried and recovered the surface.
                    continue

                # Find the nearest prior GNW_SHOW_RECT_SRC (if any) and related fills/scrolls
                prev_src = None
                win_fill_matches = []
                map_scroll_match = None
                # Scan backwards through context
                for lno, ln in reversed(ctx):
                    mm = LINE_RE.match(ln)
                    if not mm:
                        continue
                    ttag = mm.group('tag')
                    tdata = mm.group('data')
                    tkv = parse_kv_pairs(tdata)

                    if prev_src is None and ttag == 'GNW_SHOW_RECT_SRC':
                        prev_src = dict(lineno=lno, ts=mm.group('ts'), tag=ttag, data=tdata, kv=tkv)
                        # Continue scanning to find fills and scrolls that come before
                        continue

                    if prev_src is not None:
                        if ttag in ('WIN_FILL_RECT', 'WIN_FILL_RECT_SCREENBUF', 'WIN_SCRBLIT'):
                            # If srcPtr exists and matches prev_src srcPtr, note it
                            if 'srcPtr' in tkv and 'srcPtr' in prev_src['kv'] and tkv['srcPtr'] == prev_src['kv'].get('srcPtr'):
                                win_fill_matches.append(dict(lineno=lno, ts=mm.group('ts'), tag=ttag, data=tdata, kv=tkv))
                            else:
                                # Also collect fills that overlap top region heuristically
                                win_fill_matches.append(dict(lineno=lno, ts=mm.group('ts'), tag=ttag, data=tdata, kv=tkv))
                        if ttag == 'MAP_SCROLL_MEMMOVE' and map_scroll_match is None:
                            map_scroll_match = dict(lineno=lno, ts=mm.group('ts'), tag=ttag, data=tdata, kv=tkv)

                    # Stop scanning if we've gone back far enough
                    if lineno - lno > 2000:
                        break

                results.append((entry, list(ctx), prev_src, win_fill_matches, map_scroll_match))
                if len(results) >= max_results:
                    break
    return results


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: patchlog_analyze.py <patchlog.txt>')
        sys.exit(2)
    path = sys.argv[1]
    print('Analyzing', path)
    res = analyze(path)
    if not res:
        print('No suspicious GNW_SHOW_RECT surf_pre>0 && surf_post==0 found')
        sys.exit(0)
    print('\nFound {} suspicious events (showing up to {}).\n'.format(len(res), len(res)))
    for idx, item in enumerate(res, start=1):
        # item is (entry, ctx, prev_src, win_fill_matches, map_scroll_match)
        entry, ctx, prev_src, win_fill_matches, map_scroll_match = item
        print('--- Event #{}/{}: {}:{} ---'.format(idx, len(res), entry['lineno'], entry['ts']))
        print(entry['data'])

        if prev_src:
            print('\nNearest prior GNW_SHOW_RECT_SRC:')
            print('{:6d}: {}'.format(prev_src['lineno'], prev_src['data']))
        else:
            print('\nNearest prior GNW_SHOW_RECT_SRC: NONE FOUND')

        if win_fill_matches:
            print('\nMatching WIN_FILL / SCRBLIT events (nearest first):')
            for w in win_fill_matches[:5]:
                print('{:6d}: {}'.format(w['lineno'], w['data']))
        else:
            print('\nMatching WIN_FILL / SCRBLIT events: NONE FOUND')

        if map_scroll_match:
            print('\nRecent MAP_SCROLL_MEMMOVE:')
            print('{:6d}: {}'.format(map_scroll_match['lineno'], map_scroll_match['data']))

        print('\nContext (last {} lines):'.format(len(ctx)))
        for ln, l in ctx[-200:]:
            print('{:6d}: {}'.format(ln, l))
        print('\n')
    print('Done')
