#!/usr/bin/env python3

import datetime
import json
import subprocess
from collections import defaultdict
import math
import os
import dbus
from pathlib import Path
import sys

from kitty.boss import get_boss
from kitty.fast_data_types import Screen
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    Formatter,
    TabBarData,
    as_rgb,
    draw_attributed_string,
    draw_title,
)

sys.path.insert(0, str(Path.home() / '.config' / 'kitty'))
from kitty_common import (
    ssh_help, kitty_help, kitty_alt_help,
    cyan, red, white, normal, rst, mc_string
)

session_bus = dbus.SessionBus()
host_list = {}
STATE = defaultdict(lambda: "", {"Paused": "", "Playing": ""})


def get_active_music():
    ret = None
    for name in session_bus.list_names():
        if name.startswith('org.mpris.MediaPlayer2.'):
            player = session_bus.get_object(name, '/org/mpris/MediaPlayer2')
            iface = dbus.Interface(player, 'org.freedesktop.DBus.Properties')
            props = iface.GetAll('org.mpris.MediaPlayer2.Player')
            if props['PlaybackStatus'] == 'Playing' or ret is None:
                ret = '{0}{1} {2} {3} - {4} {5}'.format(
                    rst,
                    normal,
                    STATE[props['PlaybackStatus']],
                    ''.join(props['Metadata']['xesam:artist']),
                    props['Metadata']['xesam:title'],
                    rst,
                )
            if props['PlaybackStatus'] == 'Playing':
                break
    return (len(ret) - 2 * len(rst) - len(normal), ret) if ret and len(ret) > 3 else (1, '')


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
    mc_title = f'{rst}{white}{tab.tab_id: >2}{rst}' if tab.is_active else f'{rst}{normal}{tab.tab_id: >2}{rst}'
    draw_attributed_string(
        mc_title,
        screen
    )
    if not is_last:
        return screen.cursor.x
    lam, active_music = get_active_music()
    this_host_list = host_list.setdefault(tab.tab_id, [os.uname().nodename])
    userhost = next((f for f in tab.title.split(' ') if '@' in f), None)
    if userhost:
        host = userhost.split('@')[1].split(':')[0].strip('[]()')
        if len(this_host_list) >= 2 and host == this_host_list[-2]:
            this_host_list.pop()
        elif len(this_host_list) >= 1 and host != this_host_list[-1]:
            this_host_list.append(host)
    mc_title = ' -> '.join(this_host_list)
    mc_title = mc_title if len(mc_title) < 40 else ' -> '.join(this_host_list[-2:])

    draw_attributed_string(
        mc_string(
            kitty_help if len(this_host_list) <= 1 else ssh_help,
            title=mc_title,
            cols=screen.columns - screen.cursor.x - lam,
            color=red if len(this_host_list) > 1 else cyan,
        ),
        screen
    )
    draw_attributed_string(
        active_music,
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

