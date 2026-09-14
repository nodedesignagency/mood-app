# LiquidGlassKit (vendored)

Source: https://github.com/sqoder/LiquidGlassKit — MIT, see LICENSE.

Only the pieces this app uses are copied in: the configuration type, the
`liquidGlassLens` modifier, and the Metal shader. `LiquidGlassCanvas` is not
copied — it takes the lens frame as plain values, so a moving lens jumps
instead of animating; `Selector/LensCanvas.swift` is an animatable
replacement over the same shader function. The macOS-only desktop bubble and
the dark-themed card/pill wrappers are left out.

Vendored rather than added as a package because the Xcode project is written
by `genproj.py`, which knows about source files and nothing else. The `.metal`
file compiles into the app's default library, which is where
`ShaderLibrary.default` looks — the library's own `#if SWIFT_PACKAGE` branch
is simply never taken.
