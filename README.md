# VN130 Controller — Plasma 6 widget

A small KDE Plasma panel widget for the VN130 Bluetooth headset at
`AC:EC:8A:52:BB:46`.

The headset sometimes times out during its first Bluetooth authentication. The
widget applies the practical workaround in one action:

1. turn the Bluetooth adapter off;
2. wait briefly and turn it on;
3. connect VN130;
4. verify the connection remains stable;
5. reset and retry once if it disconnects.

It uses KDE's BluezQt API directly. It does not use `sudo`, parse
`bluetoothctl`, alter pairing information, or replace KDE's normal Bluetooth
widget.

## Install

From this repository:

```bash
kpackagetool6 --type Plasma/Applet --install ./vn130-plasma-widget
```

For an existing installation:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./vn130-plasma-widget
```

Then add it to the system tray:

1. Right-click the system tray and open **Configure System Tray…**.
2. Open **Entries**.
3. Find **VN130 Controller** and set its visibility to **Always shown** (or **Shown when relevant**).

It can still be added as a standalone panel widget through **Add Widgets** if preferred.

## Use

- When disconnected, click the panel icon to run **Reset & Connect** directly.
- When connected or while working, click the icon to open its status popup.
- The popup provides **Reconnect VN130**, **Disconnect**, and **Cancel**.
- The icon remains busy while it verifies the connection. This takes about 32
  seconds because the diagnosed VN130 failure occurs after roughly 28 seconds.

> Resetting the adapter temporarily disconnects every Bluetooth device, not
> only VN130.

VN130 must already be paired. The widget deliberately never removes or creates
pairings.

## Uninstall

Remove the widget from the panel, then run:

```bash
kpackagetool6 --type Plasma/Applet --remove org.local.vn130connector
```

## Troubleshooting

Check the paired device and adapter:

```bash
bluetoothctl info AC:EC:8A:52:BB:46
bluetoothctl show
```

Launch the widget in a test window and watch terminal diagnostics:

```bash
plasmawindowed org.local.vn130connector
```

If Plasma is still using an older development copy, restart the shell session
or remove and reinstall the package.
