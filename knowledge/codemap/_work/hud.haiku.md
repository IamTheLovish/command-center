## Purpose
Client-side HUD, cursor, top-down GUI, health bars, keybinds, onboarding and tutorial for the RTS (hud/cursor/guiscreen/healthbars/keybinds/onboarding/tutorial/attackwarnings packages, 114 files, ~23641 lines).
Renders selection/command panels, portraits, notifications and tutorial/onboarding flow, with a few server-side onboarding/tutorial handlers and packets.

## Key classes
- `hud/HudClientEvents.java` (~2709) [OVER 1000] - main HUD rendering, selection strip, button grids, input handling
- `tutorial/TutorialClientEvents.java` (~1060) [OVER 1000] - tutorial stage progression and help button
- `hud/LobbyBackdrop.java` (~999) - animated lobby/skirmish backdrop rendering
- `hud/NotificationClientEvents.java` (~840) - spoken/chord alert notifications with per-type cooldowns
- `cursor/CursorClientEvents.java` (~762) - cursor state and client events (name-based)
- `hud/PortraitRendererUnit.java` (~692) - unit portrait rendering
- `hud/playerdisplay/PlayerPanelClientEvents.java` (~692) - player panel client events (name-based)
- `onboarding/OnboardingServer.java` (~566) - server-side onboarding logic (name-based)
- `hud/EconomyBarRenderer.java` (~543) - economy bar rendering
- `hud/UnitInfoCard.java` (~537) - unit info card (name-based)
- `onboarding/OnboardingClient.java` (~512) - client-side onboarding (name-based)
- `hud/GothicText.java` (~476) - custom text rendering (name-based)
- `healthbars/HealthBarClientEvents.java` (~422) - health bar client events (name-based)
- `hud/buttons/Button.java` (~399) - HUD button model and rendering
- `hud/playerdisplay/DiplomacyPlayerDisplay.java` (~395) - diplomacy player display (name-based)
- `tutorial/TutorialServerEvents.java` (~347) - server-side tutorial events (name-based)

## Entry points and events
- Client tick: `HudClientEvents.onClientTick`, `TutorialClientEvents.onClientTick`
- Render: `HudClientEvents.onDrawScreen` (ScreenEvent.Render.Post), `TutorialClientEvents.onRenderOverLay` (RenderGuiOverlayEvent.Pre)
- Input: `HudClientEvents.onInput`/`onMousePress`/`onKeyPress`/`onKeyRelease`, `TutorialClientEvents.onMouseClick`/`onKeyPress`/`onKeyRelease`
- Entity render: `HudClientEvents.onRenderLivingEntity`, `onRenderNamePlate`
- Packets (9 files): `hud/HudClientboundPacket`, `tutorial/TutorialClientboundPacket`/`TutorialServerboundPacket`, `onboarding/OnboardingClientboundPacket`/`OnboardingServerboundPacket`, `attackwarnings/AttackWarningClientboundPacket`, `guiscreen/TopdownGuiServerboundPacket`, `hud/custombutton/CustomButtonClientboundPacket`/`CustomButtonActionServerboundPacket`
- Commands: none seen in dossier

## Server vs client
- Server-side (name-based): `onboarding/OnboardingServer.java`, `tutorial/TutorialServerEvents.java`, and the `ServerboundPacket` classes receiving input.
- Client-side: `HudClientEvents`, `TutorialClientEvents`, `NotificationClientEvents`, `CursorClientEvents`, `HealthBarClientEvents`, `OnboardingClient`, and most of `hud/`.

## Data flow
- Imports from: unit (121), building (95), util (43), player (41), resources (36), orthoview (27), faction (21), registrars (16), alliance (15), config (14).
- Imported by: unit (175), ability (145), building (121), research (58), gametest (15), matchstart (14), mixin (9), player (8), items (7), resources (6).
- Hub-like: heavily consumed by unit, ability and building packages; the HUD is a leaf-style consumer of those domains.

## Instrumentation and tests
- Instrumentation ids: BARS (FrameParts/Sys ids beyond BARS: none seen)
- GameTest classes by import count: SkirmishGameTests(17), OnboardingGameTests(4), BuildGroupGameTests(3), CommanderKeyGameTests(3), ReturnResourcesKeyGameTests(3), KeybindGameTests(2), SandboxSecurityGameTests(2), AnnouncementFeedGameTests(1)