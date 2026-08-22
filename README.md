# VN130 Controller — Plasma 6 widget

A small KDE Plasma panel widget for reliably connecting a paired Bluetooth
headset. It defaults to the VN130 at `AC:EC:8A:52:BB:46`, but the target device
and connection behavior are configurable per widget instance.

The VN130 sometimes times out during its first Bluetooth authentication. The
widget applies the practical workaround in one action:

1. turn the Bluetooth adapter off;
2. wait briefly and turn it on;
3. connect the configured device;
4. verify the connection remains stable;
5. reset and retry if it disconnects.

It uses KDE's BluezQt API directly. It does not use `sudo`, parse
`bluetoothctl`, alter pairing information, or replace KDE's normal Bluetooth
widget.

## Install

Run the installer from this repository:

```bash
./install.sh
```

The script installs or upgrades the applet for the current user. Plasma
registers it as a system tray applet; no root access is needed.

Then make it visible in the system tray:

1. Right-click the system tray and open **Configure System Tray…**.
2. Open **Entries**.
3. Find **VN130 Controller** and set its visibility to **Always shown** (or **Shown when relevant**).

It can still be added as a standalone panel widget through **Add Widgets** if preferred.

## Configure

Open the widget's **Configure…** dialog and select **Device & Connection**. The
page provides:

- a friendly device name used in the popup and status messages;
- the paired device's Bluetooth MAC address;
- the maximum number of reset/connect attempts;
- waits after powering Bluetooth off and back on;
- the timeout for each connection attempt;
- the stability-check duration before a connection is reported as successful.

The defaults preserve the original VN130 behavior: two attempts, 2 seconds
after power-off, 2.5 seconds after power-on, a 38-second connection timeout,
and a 32-second stability check. Shortening the stability check can miss the
diagnosed VN130 failure, which occurs after roughly 28 seconds.

The configured device must already be paired. The widget deliberately never
removes or creates pairings.

## Use

- When disconnected, click the panel icon to run the reset/connect workflow directly.
- When connected or while working, click the icon to open its status popup.
- The popup provides **Connect** or **Reconnect**, **Disconnect**, and **Cancel** actions.
- The icon remains busy while the configured stability check runs.

> Resetting the adapter temporarily disconnects every Bluetooth device, not
> only the configured headset.

## Uninstall

Run:

```bash
./uninstall.sh
```

The script removes the current user's applet package. If Plasma retains a stale
tray entry, restart Plasma or sign out and back in.

## Troubleshooting

Check the configured paired device and adapter, replacing the sample address if
needed:

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
