#!/usr/bin/env python3

import datetime
import json
import subprocess
from collections import defaultdict
import math
import os

from kitty.boss import get_boss
from kitty.fast_data_types import Screen
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    Formatter,
    TabBarData,
    as_rgb,
    draw_attributed_string
)

host_list = {}
csi = '\x1b['
cyan = f'{csi}30;46m'
red = f'{csi}30;41m'
white = f'{csi}30;47m'
normal = f'{csi}37;40m'
rst = f'{csi}00m'
ssh_help = [
    ['1', 'WaitConn'],
    ['2', 'ListConn'],
    ['3', 'Rekey'],
    ['4', 'Cmd Line'],
    ['5', 'Break'],
    ['6', 'Suspend'],
    ['7', 'Terminate'],
    ['8', '---'],
    ['9', '---'],
    ['10', '---']
]
kitty_alt_help = [
    ['1', 'UnHold'],
    ['2', 'AltScreen'],
    ['3', 'Reset'],
    ['4', '---'],
    ['5', 'HangUp'],

    ['6', 'Stop'],
    ['7', 'Quit'],
    ['8', 'Kill'],
    ['9', '---'],
    ['10', '---']
]
kitty_help = [
    ['1', 'Hold'],
    ['2', 'Screen'],
    ['3', 'Setup'],
    ['4', 'Shell'],
    ['5', 'Interrupt'],

    ['6', 'Suspend'],
    ['7', 'Terminate'],
    ['8', 'Continue'],
    ['9', '---'],
    ['10', 'Maximize']
]


def mc_string(lst, title=None, cols=160, color=cyan):
    ret = [rst]
    n = len(lst)
    t = len(title) if title else 0
    cols -= t
    fn_cols = math.floor(cols / n) - 2
    remainder = cols - n * (fn_cols + 2)
    if title:
        ret.append(f'{white}{title}{rst}')
    i = 1
    last_pad = 0
    for l in lst:
        pad = math.floor(remainder * i / n)
        ret.append(f'{normal}{l[0]: >2}{color}{l[1]: <{fn_cols + pad - last_pad}}{rst}')
        last_pad = pad
        i += 1
    ret.append('\n\n')
    return ''.join(ret)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    if not tab.is_active:
        return screen.cursor.x
    this_host_list = host_list.setdefault(tab.tab_id, [os.uname().nodename])
    userhost = next((f for f in tab.title.split(' ') if '@' in f), None)
    if userhost:
        host = userhost.split('@')[1].split(':')[0]
        if len(this_host_list) >= 2 and host == this_host_list[-2]:
            this_host_list.pop()
        elif len(this_host_list) >= 1 and host != this_host_list[-1]:
            this_host_list.append(host)

    draw_attributed_string(
        mc_string(
            kitty_help if len(this_host_list) <= 1 else ssh_help,
            title=' -> '.join(this_host_list),
            cols=screen.columns,
            color=red if len(this_host_list) > 1 else cyan,
        ),
        screen
    )
    return screen.cursor.x


def draw_right_status(draw_data: DrawData, screen: Screen) -> None:
    # The tabs may have left some formats enabled. Disable them now.
    draw_attributed_string(Formatter.reset, screen)
    cells = create_cells()
    # Drop cells that wont fit
    while True:
        if not cells:
            return
        padding = screen.columns - screen.cursor.x \
            - sum(len(c) + 3 for c in cells)
        if padding >= 0:
            break
        cells = cells[1:]

    if padding:
        screen.draw(" " * padding)

    tab_bg = as_rgb(int(draw_data.inactive_bg))
    tab_fg = as_rgb(int(draw_data.inactive_fg))
    default_bg = as_rgb(int(draw_data.default_bg))
    for cell in cells:
        # Draw the separator
        if cell == cells[0]:
            screen.cursor.fg = tab_bg
            screen.draw("")
        else:
            screen.cursor.fg = default_bg
            screen.cursor.bg = tab_bg
            screen.draw("")
        screen.cursor.fg = tab_fg
        screen.cursor.bg = tab_bg
        screen.draw(f" {cell} ")


def create_cells() -> list[str]:
    now = datetime.datetime.now()
    return [
        currently_playing(),
        get_headphone_battery_status(),
        now.strftime("%d %b"),
        now.strftime("%H:%M"),
    ]


def get_headphone_battery_status():
    try:
        battery_pct = int(subprocess.getoutput("headsetcontrol -b -c"))
    except Exception:
        status = ""
    else:
        if battery_pct < 0:
            status = ""
        else:
            status = f"{battery_pct}% {''[battery_pct // 10]}"
    return f" {status}"


STATE = defaultdict(lambda: "", {"Paused": "", "Playing": ""})


def currently_playing():
    status = " "
    data = {}
    try:
        data = json.loads(subprocess.getoutput("dbus-player-status"))
    except ValueError:
        pass
    if data:
        if "state" in data:
            status = f"{status} {STATE[data['state']]}"
        if "title" in data:
            status = f"{status} {data['title']}"
        if "artist" in data:
            status = f"{status} - {data['artist']}"
    else:
        status = ""
    return status

