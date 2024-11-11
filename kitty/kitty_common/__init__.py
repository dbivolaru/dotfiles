import math

csi = '\x1b['
cyan = f'{csi}30;46m'
red = f'{csi}30;41m'
white = f'{csi}30;47m'
normal = f'{csi}37;40m'
rst = f'{csi}00m'
ssh_help = [
    ['~&', 'WaitConn'],
    ['~#', 'ListConn'],
    ['~R', 'Rekey'],
    ['~C', 'Cmd Line'],
    ['~B', 'Break'],
    ['^Z', 'Suspend'],
    ['~.', 'Terminate'],
    [' ', '---'],
    [' ', '---'],
    [' ', '---']
]
kitty_ctrl_help = [
    ['1', 'F11'],
    ['2', 'F12'],
    ['3', 'F13'],
    ['4', 'F14'],
    ['5', 'F15'],
    ['6', 'F16'],
    ['7', 'F17'],
    ['8', 'F18'],
    ['9', 'F19'],
    ['10', 'F20']
]
kitty_alt_help = [
    ['1', ''],
    ['2', ''],
    ['3', 'Reset'],
    ['4', 'SoftReset'],
    ['5', 'Disconnect'],

    ['6', 'Stop'],
    ['7', 'Quit'],
    ['8', '---'],
    ['9', '---'],
    ['10', '---']
]
kitty_help = [
    ['1', 'Hold'],
    ['2', 'AltScreen'],
    ['3', 'Setup'],
    ['4', 'Shell'],
    ['5', 'Break'],

    ['6', 'Suspend'],
    ['7', 'Terminate'],
    ['8', 'Continue'],
    ['9', 'Kill'],
    ['10', 'Maximize']
]


def mc_string(lst, title=None, title_cr=True, cols=160, color=cyan, center_title=False):
    ret = [rst]
    n = len(lst)
    t = len(title) if title and not center_title else 0
    cols -= t
    fn_cols = math.floor(cols / n) - 2
    remainder = cols - n * (fn_cols + 2)
    if title:
        if center_title:
            ret.append(f'{rst}{white}{title: ^{cols}}{rst}{normal}')
        else:
            ret.append(f' {rst}{white}{title}{rst}{normal}')
        if title_cr:
            ret.append(f'\n')
    i = 1
    last_pad = 0
    for l in lst:
        pad = math.floor(remainder * i / n)
        ret.append(f'{rst}{normal}{l[0]: >2}{color}{l[1]: <{fn_cols + pad - last_pad}}{rst}{normal}')
        last_pad = pad
        i += 1
    return ''.join(ret)


def mc_print(lst, title=None, cols=160):
    print(mc_string(lst, title, cols, center_title=True), flush=True)
